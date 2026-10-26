---
name: uni
description: Consulta el campus de Elisava (campus.elisava.net) para responder preguntas sobre el temario y los planes docentes, las asignaturas, los horarios, el calendario académico, las aulas libres, los laboratorios (Elisava Labs), la matrícula, el Erasmus, la normativa, IT y los contactos. Úsala siempre que el usuario pregunte por algo de la universidad.
---

# Consultas al campus de Elisava

El campus (`campus.elisava.net`) es una web WordPress protegida con el login de Microsoft de Elisava. Muchos recursos son PDF o ZIP alojados en el propio campus, o enlaces a otras webs de Elisava. Responde siempre con datos sacados de ellos y nunca te los inventes.

## Comandos

```
node .claude/skills/uni/scripts/elisava.js get <url|ruta> [--links]     # texto de una página
node .claude/skills/uni/scripts/elisava.js download <url> <destino>     # PDF/ZIP con la sesión
```

Descarga los ficheros en `/tmp/elisava/`. Para leer un PDF usa `pdftotext -layout`. Si el PDF tiene información en colores (por ejemplo, el calendario: festivos, exámenes…), lee también el PDF con la herramienta Read para verlo como imagen.

## Mapa del campus (dónde está cada cosa)

| Tema | Dónde |
|---|---|
| Calendario académico (festivos, exámenes, entregas) | `/calendario-academico-grados/` → PDF |
| Temario / planes docentes (PDA) de cada asignatura | `/gestion-y-documentacion-academica-grados/` → ZIP por curso y grado (`pdas-<n>o-gedi` = Grado en Diseño e Innovación, `pdas-<n>o-gdisi` = Ingeniería de Diseño Industrial) |
| Matrícula, automatrícula, Erasmus | `/gestion-y-documentacion-academica-grados/` → PDF |
| Horarios de clase | enlace "Horarios de clase" de la portada → `gestioacademicavirtual.elisava.net` (consulta pública) |
| Expediente, notas, matrícula personal | `gestioacademicavirtual.elisava.net` (desde `/expediente-academico-grado/`) |
| Asignaturas (aula virtual Moodle: apuntes, entregas) | `aula.elisava.net` (login OIDC) |
| Aulas libres | `ocupacio.elisava.net` |
| Laboratorios y talleres (reservas, funcionamiento) | Elisava Labs → SharePoint `elisavanet.sharepoint.com` |
| Biblioteca, IT, Welcome guide, normativas, propiedad intelectual, contactos, internships | `/biblioteca/`, `/it-sistemas/`, `/welcome-guide/`, `/normativas-y-protocolos/`, `/propiedad-intelectual/`, `/contactos/`, `/elisava-internships/` |

Si no sabes dónde está algo, empieza por `get / --links` y navega. Si un dominio externo da un error 403 de túnel, no está permitido en la red del entorno: díselo al usuario y dale el dominio que tiene que añadir.

## Si sale `SESION_CADUCADA`: volver a iniciar sesión

1. Lanza `node .claude/skills/uni/scripts/elisava.js login` con Monitor y filtra `NUMERO|CODIGO|APROBAR|LOGIN_OK|ERROR`.
2. Si sale `NUMERO: <n>`, díselo al usuario de forma bien visible y mándale también una notificación push para que lo escriba en Microsoft Authenticator. Si sale `APROBAR_EN_AUTHENTICATOR`, dile que apruebe la solicitud.
3. Si sale `CODIGO_REQUERIDO`, pídele el código de 6 dígitos y escríbelo en `.elisava_code`, en la raíz del repo.
4. Si sale `LOGIN_OK`, repite la consulta.

Las credenciales se leen de `ELISAVA_USER` y `ELISAVA_PASSWORD`. Nunca muestres ni subas al repo las credenciales ni `.elisava_state.json`.

## Reglas

- Cita la URL o el documento de donde sale cada dato.
- Si no encuentras algo, dilo y no lo supongas.
