---
name: uni
description: Consulta el campus de Elisava (campus.elisava.net) para responder preguntas sobre el temario y los planes docentes, las asignaturas, los horarios, el calendario académico, las aulas libres, los laboratorios (Elisava Labs), la matrícula, el Erasmus, la normativa, IT y los contactos. Úsala siempre que el usuario pregunte por algo de la universidad.
---

# Consultas al campus de Elisava

El campus (`campus.elisava.net`) es una web WordPress protegida con el login de Microsoft de Elisava. Muchos recursos son PDF o ZIP alojados en el propio campus, o enlaces a otras webs de Elisava. Responde siempre con datos sacados de ellos y nunca te los inventes.

## Comandos

`<skill>` es el directorio de esta skill: `.claude/skills/uni` dentro del repo o `~/.claude/skills/uni` si está instalada en el ordenador. Si sale `falta Playwright`, dile al usuario que ejecute `bash <skill>/install.sh`.

```
node <skill>/scripts/elisava.js get <url|ruta> [--links]     # texto de una página
node <skill>/scripts/elisava.js download <url> <destino>     # PDF/ZIP con la sesión
```

Descarga los ficheros en `/tmp/elisava/`. Para leer un PDF usa `pdftotext -layout` si está instalado; si no, léelo con la herramienta Read. Si el PDF tiene información en colores (por ejemplo, el calendario: festivos, exámenes…), lee también el PDF con la herramienta Read para verlo como imagen.

## Perfil del usuario

GEDI (Grado en Ingeniería de Diseño Industrial, Elisava – UVic-UCC), 1.º curso, curso 2026-27, 1.er semestre. Si no dice otra cosa, sus preguntas se refieren a estas asignaturas.

Asignaturas del 1.er semestre (6 ECTS cada una; los planes docentes están en `pdas-1o-gedi-en-pdf.zip`):
- Álgebra y Cálculo
- Expresión Artística
- Fundamentos de Programación
- Materia
- Metodologías del Diseño

Las del 2.º semestre son CAD (en inglés), Estética y Diseño, Física de Materiales, Mecánica y Tecnología Eléctrica y Electrónica.

## Mapa del campus (dónde está cada cosa)

| Tema | Dónde |
|---|---|
| Calendario académico (festivos, exámenes, entregas) | `/calendario-academico-grados/` → PDF |
| Temario / planes docentes (PDA) de cada asignatura | `/gestion-y-documentacion-academica-grados/` → ZIP por curso y grado (`pdas-<n>o-gedi` = Grado en Ingeniería de Diseño Industrial, `pdas-<n>o-gdisi` = Grado en Diseño e Innovación). Los nombres de los ficheros del ZIP tienen espacios y acentos mal codificados: recórrelos con `for f in *.pdf` y entre comillas |
| Matrícula, automatrícula, Erasmus | `/gestion-y-documentacion-academica-grados/` → PDF |
| Horarios de clase | enlace "Horarios de clase" de la portada → `gestioacademicavirtual.elisava.net` (consulta pública) |
| Expediente, notas, matrícula personal | `gestioacademicavirtual.elisava.net` (desde `/expediente-academico-grado/`) |
| Asignaturas (aula virtual Moodle: apuntes, entregas) | `aula.elisava.net` (login OIDC) |
| Aulas libres | `ocupacio.elisava.net` |
| Laboratorios y talleres (reservas, funcionamiento) | Elisava Labs → SharePoint `elisavanet.sharepoint.com` |
| Biblioteca, IT, Welcome guide, normativas, propiedad intelectual, contactos, internships | `/biblioteca/`, `/it-sistemas/`, `/welcome-guide/`, `/normativas-y-protocolos/`, `/propiedad-intelectual/`, `/contactos/`, `/elisava-internships/` |

Si no sabes dónde está algo, empieza por `get / --links` y navega. Si un dominio externo da un error 403 de túnel, no está permitido en la red del entorno: díselo al usuario y dale el dominio que tiene que añadir.

## Si sale `SESION_CADUCADA`: volver a iniciar sesión

1. Lanza `node <skill>/scripts/elisava.js login` en segundo plano (con Monitor si está disponible) y vigila su salida: `NUMERO|CODIGO|APROBAR|LOGIN_OK|ERROR`.
2. Si sale `NUMERO: <n>`, díselo al usuario de forma bien visible y mándale también una notificación push para que lo escriba en Microsoft Authenticator. Si sale `APROBAR_EN_AUTHENTICATOR`, dile que apruebe la solicitud.
3. Si sale `CODIGO_REQUERIDO`, pídele el código de 6 dígitos y escríbelo en `~/.config/elisava/code`.
4. Si sale `LOGIN_OK`, repite la consulta.

Las credenciales se leen de `ELISAVA_USER` y `ELISAVA_PASSWORD` o de `~/.config/elisava/credentials`. Nunca muestres ni subas al repo las credenciales ni `~/.config/elisava/`.

## Reglas

- Cita la URL o el documento de donde sale cada dato.
- Si no encuentras algo, dilo y no lo supongas.
