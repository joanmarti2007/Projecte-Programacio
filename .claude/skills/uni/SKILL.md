---
name: uni
description: Consulta el campus de Elisava (campus.elisava.net) para responder preguntas sobre el temario, las asignaturas, los horarios, las clases, los laboratorios, los talleres, la normativa y los avisos. Úsala siempre que el usuario pregunte por algo de la universidad.
---

# Consultas al campus de Elisava

El campus es una web WordPress protegida con el login de Microsoft de Elisava. Responde siempre con datos sacados de ella y nunca te los inventes.

## Leer páginas

`node .claude/skills/uni/scripts/elisava.js get <url|ruta> [--links]`

- Empieza por `/` con `--links` y navega siguiendo los enlaces relevantes (horarios, asignaturas, laboratorios, avisos).
- Si un horario o una guía está en PDF, descárgalo y léelo.

## Si sale `SESION_CADUCADA`: volver a iniciar sesión

1. Lanza `node .claude/skills/uni/scripts/elisava.js login` con Monitor y filtra `NUMERO|CODIGO|APROBAR|LOGIN_OK|ERROR`.
2. Si sale `NUMERO: <n>`, díselo al usuario de forma bien visible y mándale también una notificación push para que lo escriba en Microsoft Authenticator. Si sale `APROBAR_EN_AUTHENTICATOR`, dile que apruebe la solicitud.
3. Si sale `CODIGO_REQUERIDO`, pídele el código de 6 dígitos y escríbelo en `.elisava_code`, en la raíz del repo.
4. Si sale `LOGIN_OK`, repite la consulta.

Las credenciales se leen de `ELISAVA_USER` y `ELISAVA_PASSWORD`. Nunca muestres ni subas al repo las credenciales ni `.elisava_state.json`.

## Reglas

- Cita la URL de donde sale cada dato.
- Si no encuentras algo, dilo y no lo supongas.
