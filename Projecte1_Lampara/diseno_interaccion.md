# Parte 7 – Diseño de interacción (propuesta)

## 7.1 Funciones de la lámpara

1. Encender / apagar (obligatoria)
2. Regular el brillo
3. Cambiar de color (colores guardados en un array)
4. Efecto vela: la luz tiembla como una llama

## 7.2 Qué puede hacer un dedo sobre un solo sensor

| Gesto | Objeto cotidiano donde se usa |
|---|---|
| Toque corto | Interruptor, timbre, lámpara táctil de mesita |
| Doble toque | Ratón (doble click), pantalla del móvil para hacer zoom, AirPods |
| Triple toque | Algunos auriculares (canción anterior) |
| Mantener el dedo (pulsación larga) | Regulador de luz táctil, menú del móvil, botón de encendido |
| Mantener muy largo (> 3 s) | Apagar/reiniciar un móvil |
| Toque y luego mantener | Algunas lámparas táctiles para regular |
| Acercar la mano sin tocar | Grifos y secadores automáticos |
| Un ritmo concreto de toques | Llamar a una puerta "de una forma especial" |
| No tocar durante un tiempo | Pantalla del móvil que se apaga sola |

## 7.3 Mapa de interacción

| Función | Gesto | Respuesta de la luz | Por qué este gesto |
|---|---|---|---|
| Encender / apagar | Un toque corto (< 0,4 s) | Se enciende o se apaga | Es la acción más usada: le toca el gesto más sencillo, el mismo que cualquier lámpara táctil |
| Regular el brillo | Mantener el dedo (≥ 0,4 s), solo encendida | El brillo sube poco a poco mientras se mantiene; al soltar se queda. La siguiente vez baja (al revés que la última) | Es como los reguladores táctiles: la persona ve el cambio mientras lo hace y suelta cuando le gusta |
| Cambiar de color | Doble toque, solo encendida | Pasa al siguiente color del array (cálido → neutro → frío → cálido) | Gesto conocido (doble click) y rápido; es una acción frecuente pero menos que encender |
| Efecto vela | Triple toque, solo encendida | La luz empieza a temblar como una llama. Otro triple toque vuelve a luz fija | Función especial que se usa poco: un gesto más difícil evita activarla sin querer |

Tiempos que hay que decidir al programar (Parte 8, con `millis()`):
- Toque corto: el dedo está menos de 400 ms.
- Mantener: el dedo está 400 ms o más.
- Doble/triple toque: los toques están separados menos de 400 ms. Por eso, después de un toque, la lámpara espera 400 ms antes de decidir si era un toque simple, doble o triple.

## 7.4 Revisión del mapa

- **¿La acción más usada tiene el gesto más sencillo?** Sí: encender y apagar es un toque. Inconveniente: hay que esperar ~0,4 s para saber que no viene un segundo toque, así que encender tiene un pequeño retraso. Se acepta porque es casi imperceptible.
- **¿Hay alguna acción que se pueda hacer sin querer?** Con la lámpara apagada, solo el toque hace algo, así que no se puede cambiar el color o el brillo de una lámpara apagada por accidente. Con el filtro de la Parte 5, los picos de ruido no llegan al umbral, así que ningún gesto se activa solo. Acercar la mano sin tocar no hace nada.
- **¿Se puede usar a oscuras, sin mirar la lámpara?** Sí: solo hay un sensor y todos los gestos son con un dedo. Cada gesto tiene una respuesta en la propia luz (encender, cambio de brillo, cambio de color y vela).
- **¿Algún gesto se puede confundir con otro?** El toque corto y el inicio de mantener: se distinguen por el tiempo (400 ms). El doble y el triple toque: se distinguen esperando 400 ms después del último toque. Para evitar confusiones, cada gesto tiene un tiempo claro y la respuesta de la luz confirma qué se ha entendido.

## 7.5 Antes de programar

Enseñar este mapa al profesor y apuntar los cambios que proponga.
