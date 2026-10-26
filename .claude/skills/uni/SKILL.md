---
name: uni
description: Consulta la información de la universidad del usuario. Mira el campus virtual (Moodle) para el temario, los apuntes, las entregas, el calendario y las notas, y la web pública de la facultad para los horarios, las aulas, los laboratorios y la normativa. Úsala siempre que el usuario pregunte por sus asignaturas, clases, horarios, exámenes, entregas, laboratorios o cualquier cosa de la universidad.
---

# Consultas de la universidad

Hay dos fuentes. Responde siempre con datos sacados de ellas y nunca te los inventes.

## 1. Campus virtual (Moodle, con login)

`python3 .claude/skills/uni/scripts/moodle.py <comando>` devuelve JSON:

| Pregunta del usuario | Comando |
|---|---|
| Qué asignaturas tengo | `courses` |
| Temario, apuntes, prácticas de una asignatura | `contents <courseid>` |
| Qué tengo pendiente / próximos exámenes | `calendar` y `assignments` |
| Notas | `grades <courseid>` |
| Leer un PDF o documento del campus | `download <fileurl> /tmp/<nombre>` y luego léelo |

Flujo habitual: `courses` → busca el `id` de la asignatura que menciona el usuario (por nombre aproximado) → `contents <id>` → si la respuesta está dentro de un fichero, descárgalo y léelo.

Las fechas (`time`, `duedate`) son timestamps Unix: conviértelas a fecha legible en hora local (Europe/Madrid).

## 2. Web pública de la facultad (horarios, laboratorios, normativa)

`python3 .claude/skills/uni/scripts/web.py <url> [--links]` devuelve el texto de la página.

- Empieza por la portada (`/`) con `--links` y navega siguiendo los enlaces relevantes (horarios, calendario académico, laboratorios, guías docentes).
- Las rutas relativas se resuelven contra `UNI_WEB_URL`.
- Si un horario o una guía está en PDF, descárgalo con `curl -sL -o /tmp/x.pdf <url>` y léelo.

## Reglas

- Cita de dónde sale cada dato: la asignatura y la sección, o la URL.
- Si una fuente no responde o el login falla, dilo y no supongas nada.
- Nunca muestres ni guardes en el repo las credenciales ni el token (`.env` y `.moodle_token` están en `.gitignore`).
