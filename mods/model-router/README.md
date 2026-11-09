# model-router

Mod de Claude Code que reparte cada mensaje entre Haiku y Opus según la dificultad de la tarea.

## Cómo decide

1. Al enviar un mensaje, Haiku lo clasifica como tarea sencilla o compleja. Se le pasa también el final de la última respuesta, para que un "sí, hazlo" después de un plan largo no cuente como sencillo.
2. Sencilla → Haiku. Compleja, o si la clasificación falla → Opus.
3. Protecciones de coste:
   - con más de 150k tokens de contexto, siempre Opus;
   - con más de 40k tokens y la caché de Opus caliente, se queda en Opus aunque la tarea sea sencilla, porque cambiar de modelo obliga a releer la conversación sin descuento de caché.
4. Los subagentes mantienen su propio modelo.

## Qué muestra

- Una barra encima del cuadro de texto con el modelo del último mensaje y el motivo (terminal y app de escritorio).
- Una entrada en la línea de estado.
- `/router` muestra el estado; `/router haiku` o `/router opus` fuerzan un modelo, `/router auto` vuelve al modo automático y `/router off` lo apaga.

Clasificar cada mensaje cuesta una llamada pequeña a Haiku. Los umbrales y la duración de la caché (1 hora) son aproximados.

## Instalación

En la terminal, dentro de Claude Code:

```
/plugin install model-router --marketplace joanmarti2007/Projecte-Programacio
```

Responde `y` para añadir el marketplace y elige el ámbito de usuario.

Desde la shell:

```
claude plugin install model-router --marketplace joanmarti2007/Projecte-Programacio
```

En la app de escritorio: pulsa **+** junto al cuadro de texto, **Plugins**, **Add marketplace** con `joanmarti2007/Projecte-Programacio`, y luego **Add plugin**.
