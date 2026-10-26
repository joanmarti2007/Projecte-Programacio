#!/usr/bin/env python3
"""Cliente mínimo del campus virtual (Moodle) usando su API de web services.

Credenciales en variables de entorno o en un fichero .env en la raíz del repo:
  MOODLE_URL, MOODLE_USER, MOODLE_PASSWORD

Uso:
  moodle.py courses                 Asignaturas en las que estás matriculado
  moodle.py contents <courseid>     Temario: secciones, recursos y ficheros
  moodle.py calendar                Próximos eventos (entregas, exámenes...)
  moodle.py assignments             Entregas de todas tus asignaturas
  moodle.py grades <courseid>       Notas de una asignatura
  moodle.py download <fileurl> <destino>   Descarga un fichero del campus
"""
import json
import os
import sys
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
TOKEN_CACHE = ROOT / ".moodle_token"


def load_env():
    env_file = ROOT / ".env"
    if env_file.exists():
        for line in env_file.read_text().splitlines():
            if "=" in line and not line.lstrip().startswith("#"):
                k, v = line.split("=", 1)
                os.environ.setdefault(k.strip(), v.strip().strip('"'))
    missing = [k for k in ("MOODLE_URL", "MOODLE_USER", "MOODLE_PASSWORD") if not os.environ.get(k)]
    if missing:
        sys.exit(f"Faltan variables: {', '.join(missing)} (ver .env.example)")
    return os.environ["MOODLE_URL"].rstrip("/")


def post(url, data):
    body = urllib.parse.urlencode(data, doseq=True).encode()
    with urllib.request.urlopen(url, body, timeout=30) as r:
        return json.load(r)


def get_token(base, refresh=False):
    if TOKEN_CACHE.exists() and not refresh:
        return TOKEN_CACHE.read_text().strip()
    res = post(f"{base}/login/token.php", {
        "username": os.environ["MOODLE_USER"],
        "password": os.environ["MOODLE_PASSWORD"],
        "service": "moodle_mobile_app",
    })
    if "token" not in res:
        sys.exit(f"Login fallido: {res.get('error', res)}")
    TOKEN_CACHE.write_text(res["token"])
    TOKEN_CACHE.chmod(0o600)
    return res["token"]


def call(base, function, **params):
    for attempt in range(2):
        token = get_token(base, refresh=attempt > 0)
        res = post(f"{base}/webservice/rest/server.php", {
            "wstoken": token, "wsfunction": function,
            "moodlewsrestformat": "json", **params,
        })
        if isinstance(res, dict) and res.get("errorcode") == "invalidtoken":
            continue
        if isinstance(res, dict) and "exception" in res:
            sys.exit(f"Error en {function}: {res.get('message')}")
        return res
    sys.exit("Token inválido incluso tras renovarlo")


def userid(base):
    return call(base, "core_webservice_get_site_info")["userid"]


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    cmd, args = sys.argv[1], sys.argv[2:]
    base = load_env()

    if cmd == "courses":
        res = [{"id": c["id"], "name": c["fullname"], "short": c["shortname"]}
               for c in call(base, "core_enrol_get_users_courses", userid=userid(base))]
    elif cmd == "contents":
        res = []
        for s in call(base, "core_course_get_contents", courseid=args[0]):
            res.append({
                "section": s["name"],
                "summary": s.get("summary", ""),
                "modules": [{
                    "name": m["name"], "type": m["modname"], "url": m.get("url"),
                    "description": m.get("description", ""),
                    "files": [{"name": f["filename"], "fileurl": f["fileurl"]}
                              for f in m.get("contents", []) if f.get("type") == "file"],
                } for m in s.get("modules", [])],
            })
    elif cmd == "calendar":
        res = [{"name": e["name"], "course": e.get("course", {}).get("fullname"),
                "time": e["timestart"], "type": e.get("eventtype"), "url": e.get("url")}
               for e in call(base, "core_calendar_get_calendar_upcoming_view")["events"]]
    elif cmd == "assignments":
        res = [{"course": c["fullname"], "name": a["name"], "duedate": a["duedate"],
                "intro": a.get("intro", "")}
               for c in call(base, "mod_assign_get_assignments")["courses"]
               for a in c["assignments"]]
    elif cmd == "grades":
        res = call(base, "gradereport_user_get_grade_items",
                   courseid=args[0], userid=userid(base))
    elif cmd == "download":
        sep = "&" if "?" in args[0] else "?"
        urllib.request.urlretrieve(f"{args[0]}{sep}token={get_token(base)}", args[1])
        res = {"saved": args[1]}
    else:
        sys.exit(__doc__)

    print(json.dumps(res, ensure_ascii=False, indent=1))


if __name__ == "__main__":
    main()
