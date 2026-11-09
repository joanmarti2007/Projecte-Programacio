# cache-timer

Mod de Claude Code que avisa cuando la caché de la conversación está a punto de enfriarse, para no pagar por releer toda la conversación a precio completo.

Claude guarda en caché la conversación durante un tiempo (1 hora o 5 minutos). Si escribes después de que caduque, el siguiente mensaje vuelve a procesar todo el contexto sin descuento.

## Qué muestra

- Una barra encima del cuadro de texto (terminal y app de escritorio):
  - 🔥 caché caliente y cuánto le queda,
  - ⏳ en amarillo cuando quedan 5 minutos (1 minuto si la caché es de 5 min),
  - 🧊 caché fría y cuántos tokens releerá el próximo mensaje.
- Un aviso emergente cuando está a punto de enfriarse y otro cuando se enfría.
- Una entrada corta en la línea de estado.
- El comando `/cache` para ver el estado; `/cache 5m` o `/cache 1h` cambia la duración que usa para contar.

El contador vuelve a empezar al terminar cada respuesta de la conversación principal; los subagentes no cuentan.

La duración por defecto es 1 hora. Claude Code no le dice al mod qué duración usa la sesión, así que si la tuya es de 5 minutos escribe `/cache 5m`.

## Instalación

En la terminal, dentro de Claude Code:

```
/plugin install cache-timer --marketplace joanmarti2007/Projecte-Programacio
```

Responde `y` para añadir el marketplace y elige el ámbito de usuario.

Desde la shell:

```
claude plugin install cache-timer --marketplace joanmarti2007/Projecte-Programacio
```

En la app de escritorio: pulsa **+** junto al cuadro de texto, **Plugins**, **Add marketplace** con `joanmarti2007/Projecte-Programacio`, y luego **Add plugin**.

Si el repositorio es privado, solo se instala en ordenadores con acceso a él en GitHub (clave SSH, o `gh auth login` seguido de `gh auth setup-git`).
