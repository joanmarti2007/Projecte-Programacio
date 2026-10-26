#!/usr/bin/env python3
"""Lee páginas de la web pública de la universidad como texto plano.

Uso:
  web.py <url>            Texto de la página
  web.py <url> --links    Texto + lista de enlaces (para navegar)

Si la URL es relativa, se resuelve contra UNI_WEB_URL (variable de entorno o .env).
"""
import os
import sys
import urllib.parse
import urllib.request
from html.parser import HTMLParser
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
SKIP = {"script", "style", "noscript", "svg", "head"}
BLOCK = {"p", "div", "br", "li", "tr", "h1", "h2", "h3", "h4", "h5", "h6", "section", "article", "table"}


class Extractor(HTMLParser):
    def __init__(self, base):
        super().__init__()
        self.base, self.depth, self.text, self.links = base, 0, [], []

    def handle_starttag(self, tag, attrs):
        if tag in SKIP:
            self.depth += 1
        elif tag in BLOCK:
            self.text.append("\n")
        if tag == "a" and (href := dict(attrs).get("href")):
            self.links.append(urllib.parse.urljoin(self.base, href))
        if tag in ("td", "th"):
            self.text.append(" | ")

    def handle_endtag(self, tag):
        if tag in SKIP and self.depth:
            self.depth -= 1

    def handle_data(self, data):
        if not self.depth and data.strip():
            self.text.append(data.strip() + " ")


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    env_file = ROOT / ".env"
    if env_file.exists():
        for line in env_file.read_text().splitlines():
            if "=" in line and not line.lstrip().startswith("#"):
                k, v = line.split("=", 1)
                os.environ.setdefault(k.strip(), v.strip().strip('"'))
    url = urllib.parse.urljoin(os.environ.get("UNI_WEB_URL", ""), sys.argv[1])
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=30) as r:
        html = r.read().decode(r.headers.get_content_charset() or "utf-8", "replace")

    p = Extractor(url)
    p.feed(html)
    lines = (l.strip() for l in "".join(p.text).splitlines())
    print("\n".join(l for l in lines if l))
    if "--links" in sys.argv:
        print("\n--- ENLACES ---")
        print("\n".join(dict.fromkeys(p.links)))


if __name__ == "__main__":
    main()
