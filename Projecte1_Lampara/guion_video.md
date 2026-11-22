# Guion del vídeo explicativo – Lámpara táctil

Texto que se oye en `video_explicacion.mp4`, por partes. En cada parte, arriba se marca la función de la que se habla y a la izquierda se resaltan las líneas de código.

## 1. La lámpara táctil  (0:00)

*En pantalla:* La lámpara real funcionando con todos los gestos; a la izquierda, las tarjetas de los gestos se iluminan cuando se reconocen.

Este es nuestro proyecto: una lámpara que se controla tocándola, sin interruptores.

El círculo grande es la luz, el pequeño es el sensor, y el ratón hace de dedo.

Con un toque, se enciende y se apaga.

Con dos toques, cambia de color.

Manteniendo el dedo encima, se regula el brillo.

Y con tres toques, se activa el efecto vela.

Vamos a ver qué parte del código hace posible cada cosa.

## 2. Cómo está organizado el código  (0:26)

*En pantalla:* Las dos pestañas, `setup()` (una vez) y el bucle de `draw()` con sus pasos: los que deciden se iluminan en amarillo y el de dibujar en rosa.

El sketch tiene dos pestañas: la nuestra, y la pestaña Ruido, que nos da el profesor.

`setup()` se ejecuta una sola vez, al empezar: prepara la ventana, las posiciones y los colores.

`draw()` se repite unas 60 veces por segundo, y está escrita como una lista de pasos.

Primero decide: lee el sensor, filtra el ruido, mira si se está tocando y reconoce el gesto. Es el cerebro de la lámpara: la parte que se llevaría a Arduino.

Después dibuja. En la lámpara real, esta parte la haría el LED.

## 3. Variables: el estado de la lámpara  (0:58)

*En pantalla:* Una tarjeta por variable: el interruptor de `encendida`, la barra 0–255 de `brillo`, el array de 4 colores y la llama de `vela`.

Las variables globales guardan el estado de la lámpara. encendida es un `boolean`, porque solo tiene dos valores: `true` o `false`.

brillo es un `int` de 0 a 255: el mismo rango con el que Arduino regula un LED.

`colorLuz` es el color actual, y los cuatro colores posibles están guardados en un array, colores.

Y vela es otro `boolean`, que dice si el efecto vela está activado.

## 4. setup(): un diseño responsive  (1:22)

*En pantalla:* La ventana con las guías `width / 2`, `height * 0.3` y `height * 0.8`; después, la misma lámpara en una ventana de 500 × 500.

En `setup()` se crea la ventana de 900 por 600 y se calcula dónde va cada cosa.

Las posiciones y los tamaños no son números fijos: se calculan con `width` y `height`, el ancho y el alto de la ventana.

Por eso el diseño es responsive: si cambiamos el tamaño en `size()`, la luz y el sensor se recolocan solos.

## 5. leerSensor(): el ratón hace de sensor  (1:42)

*En pantalla:* Un dedo se acerca al sensor y, a la vez, se mueve el punto sobre la gráfica valor–distancia; en el código se ilumina la rama del `if` que se está cumpliendo.

`leerSensor()` simula el sensor con el ratón. Primero, `dist()` calcula la distancia d entre el ratón y el centro del sensor.

Si el ratón está lejos, devuelve 0.

Dentro de la zona de alcance, que son dos diámetros, `map()` convierte la distancia en un valor que sube de 0 a 200 cuanto más se acerca.

Encima del sensor, devuelve 200.

Y si además se hace clic, devuelve 1000: eso es tocar.

Un clic fuera del círculo no cuenta: el clic solo se mira cuando el ratón ya está dentro.

## 6. El ruido: un sensor real nunca da un valor limpio  (2:15)

*En pantalla:* Gráfica en directo de la lectura del sensor: la base, el temblor y dos picos falsos; el segundo pasa el umbral de 700.

Un sensor real nunca da un valor limpio. Por eso, la lectura pasa por `anadirRuido()`, la función de la pestaña Ruido.

Le suma una base de unos 120, que además sube y baja lentamente: es la deriva.

Encima, cada lectura tiembla un poco.

Y, de vez en cuando, aparece un pico falso muy alto, que dura un solo frame.

Si comparáramos esta lectura directamente con el umbral de 700, cada pico encendería o apagaría la lámpara sin que nadie la toque.

## 7. calcularMedia(): el filtro de media móvil  (2:44)

*En pantalla:* El array de 10 casillas con el puntero `posicion` dando la vuelta, la media frente al umbral, y al final la gráfica real: lectura (gris) y media (amarilla).

Para quitar los picos usamos una media móvil. `calcularMedia()` guarda cada lectura en un array de 10 posiciones, sustituyendo la más antigua.

El operador % hace que, después de la posición 9, se vuelva a la 0: el array funciona como un círculo.

Después suma las 10 lecturas y devuelve la media.

Un pico falso ocupa una sola casilla de diez, así que la media apenas sube y no llega al umbral.

En cambio, un toque real es alto en todas las lecturas: en unos 5 frames, menos de una décima de segundo, la media supera el umbral.

Con datos reales se ve claro: la lectura, en gris, tiene picos; la media, en amarillo, solo pasa el umbral cuando de verdad se toca.

## 8. estaTocando() y el debounce  (3:25)

*En pantalla:* Una tira de 40 frames: sin debounce la lámpara cambiaría 30 veces; con `tocandoAntes` solo se detectan el inicio y el final del toque.

`estaTocando()` devuelve `true` cuando la media pasa del umbral.

Pero `draw()` se repite 60 veces por segundo: un toque de medio segundo deja tocando en `true` durante 30 frames. Si actuáramos en cada uno, la lámpara cambiaría 30 veces.

Por eso, al final de cada `draw()`, guardamos en `tocandoAntes` el valor de este frame.

Comparando los dos detectamos solo los cambios: el toque empieza cuando tocando es `true` y `tocandoAntes` es `false`, y acaba al revés. Así cada toque cuenta una sola vez: esto es el debounce.

## 9. reconocerGestos(): medir el tiempo con millis()  (3:57)

*En pantalla:* La lámpara real a cámara lenta con sus variables en directo (`millis()`, `inicioToque`, `finToque`, `numToques`…) y una línea de tiempo con los 400 ms; en el código se ilumina el bloque que se está ejecutando.

Para distinguir los gestos hay que medir el tiempo. `millis()` devuelve los milisegundos que han pasado desde que empezó el programa.

Cuando empieza un toque, se guarda la hora en `inicioToque`.

Si se suelta antes de 400 milisegundos, es un toque corto: `numToques` suma uno, y se guarda la hora en `finToque`.

Si pasan 400 milisegundos sin otro toque, se decide según `numToques`: con uno, la lámpara se enciende o se apaga.

Con dos toques cambia el color, y con tres se activa la vela.

Y si el dedo sigue encima 400 milisegundos o más, es mantener: el brillo cambia mientras dura. Al soltar, subiendo se invierte, y la próxima vez va al revés.

## 10. Acciones: una función para cada cosa  (4:36)

*En pantalla:* Gesto → función → respuesta de la luz; el array de colores con el `%`; la barra de brillo con los topes 30 y 255; y los gestos que no hacen nada con la lámpara apagada.

Cada acción de la lámpara es una función: encender, apagar, `cambiarEstado`, `cambiarColor`, `regularBrillo` y `cambiarVela`. Así, cambiar qué gesto hace qué es cambiar una sola línea.

`cambiarColor()` pasa al siguiente color del array, con el mismo truco del % que en la media móvil.

`regularBrillo()` suma o resta 2 en cada frame, sin pasar de 255 ni bajar de 30: con brillo 0 la lámpara parecería apagada.

Y todas, menos encender y apagar, solo funcionan con la lámpara encendida: así nada cambia sin querer.

## 11. calcularBrilloVisible(): el efecto vela  (5:08)

*En pantalla:* La fórmula del brillo visible, `random()` frente a `noise()`, y la lámpara en modo vela con la gráfica de `brilloVisible`.

El efecto vela está en `calcularBrilloVisible()`: si vela es `true`, el brillo se multiplica por un valor entre 0,55 y 1.

Ese valor sale de `noise()`, que da números aleatorios pero suaves: `random()` salta de golpe, y `noise()` se mueve poco a poco.

Por eso la luz tiembla como una llama, sin saltos. El brillo guardado no cambia: solo cambia el que se dibuja.

## 12. Las funciones que dibujan  (5:32)

*En pantalla:* El halo dibujándose círculo a círculo (i = 8 … 1), el gris + el color con transparencia, y el texto de depuración tachado.

`dibujarHalo()` dibuja 8 círculos con un for, del más grande al más pequeño, para que ninguno tape a los otros. Cuanto más grande, más transparente.

`dibujarLuz()` pinta un círculo gris y, encima, el del color con transparencia igual al brillo: con poco brillo se ve el gris, y con mucho, el color.

`dibujarSensor()` ya lo hemos visto: se pone blanco al tocar. Y `dibujarValores()` solo sirve para depurar: en la entrega se quita, porque la lámpara real no tiene pantalla.

## 13. Resumen  (6:02)

*En pantalla:* El bucle de `draw()` con el origen de cada parte: visto en clase, referencia de Processing o ayuda de Claude.

En resumen, en cada frame: leer el sensor, filtrar el ruido, ver si se toca, reconocer el gesto, actuar y dibujar.

De lo que no hemos visto en clase usamos `dist()`, `millis()` y `noise()`, de la referencia de Processing. La media móvil, el debounce y los gestos se hicieron con ayuda de Claude, como indican los comentarios del código.
