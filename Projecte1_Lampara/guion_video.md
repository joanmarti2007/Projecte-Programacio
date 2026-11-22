# Guion del vídeo explicativo – Lámpara táctil

Texto que se oye en `video_explicacion.mp4`, por diapositivas.

## 1. Lámpara táctil – Proyecto 1

Este es el proyecto uno de Fundamentos de Programación: una lámpara táctil. Un círculo grande hace de luz, uno pequeño hace de sensor, y el ratón hace de dedo. Con un toque se enciende y se apaga, con dos toques cambia de color, manteniendo el dedo se regula el brillo, y con tres toques se activa un efecto vela. En este vídeo explicamos las partes más importantes del código: para qué sirven y qué funciones usan.

## 2. Estructura del programa

El programa tiene dos pestañas: la principal, y la pestaña Ruido, que nos da el profesor. En la principal hay tres bloques: las variables globales, la función setup(), que se ejecuta una sola vez, y la función draw(), que se repite unas sesenta veces por segundo. draw() está escrita como una lista de pasos. Primero decide: lee el sensor, filtra el ruido y reconoce el gesto. Y después dibuja. Las funciones que deciden son el cerebro de la lámpara: son las que se podrían llevar a Arduino, donde no hay pantalla.

## 3. Variables de estado

Las variables describen el estado de la lámpara. Encendida es un boolean, porque solo puede estar encendida o apagada. Brillo es un entero de cero a doscientos cincuenta y cinco: el mismo rango que usa Arduino para regular un LED. Color luz es de tipo color, y los cuatro colores disponibles se guardan en un array. Vela es otro boolean, que indica si el efecto vela está activado.

## 4. setup(): responsive

En setup() creamos la ventana de novecientos por seiscientos píxeles, y calculamos la posición y el tamaño de la luz y del sensor a partir del ancho y el alto de la ventana. Así el proyecto es responsive: si cambiamos el tamaño de la ventana, todo se recoloca solo. Aquí también rellenamos el array de colores.

## 5. leerSensor()

La función leer sensor simula un sensor capacitivo con el ratón. Primero calcula, con la función dist, la distancia entre el ratón y el centro del sensor. Después hay cuatro casos. Si el ratón está lejos, devuelve cero. Si se acerca, devuelve un valor que crece hasta doscientos, calculado con map. Si está encima, doscientos. Y si además se hace clic, mil. Un clic fuera del círculo no cuenta, porque el clic solo se comprueba cuando el ratón está dentro.

## 6. leerSensor() en acción

Aquí se ve funcionando. El sensor se vuelve más claro cuanto más cerca está el ratón, y blanco cuando se toca. Arriba a la izquierda se ve el valor. Fijaos en que, aunque el ratón esté lejos, el valor nunca es cero. Eso es por el ruido, que explicamos ahora.

## 7. El ruido (pestaña Ruido)

Un sensor real nunca da un valor limpio. Por eso, la lectura pasa por la función añadir ruido, de la pestaña del profesor. Esta función suma una base de unos ciento veinte, una deriva lenta, un temblor en cada lectura y, de vez en cuando, un pico falso muy alto que dura un solo frame. Si comparáramos la lectura directamente con el umbral, esos picos encenderían y apagarían la lámpara solos.

## 8. calcularMedia(): media móvil

Para eliminar los picos usamos una media móvil. La función calcular media guarda cada lectura nueva en un array de diez posiciones, sustituyendo la más antigua, y devuelve la media de las diez. Para recorrer el array en círculo usamos el operador módulo: después de la posición nueve, vuelve a la cero. Un pico falso dura un solo frame, así que dentro de la media pesa solo una décima parte, y nunca llega al umbral de setecientos. En cambio, un toque real es alto en todos los frames, y la media sí lo supera en menos de una décima de segundo.

## 9. Tocar y debounce

Estar tocando devuelve verdadero cuando la media supera el umbral. Pero draw() se ejecuta sesenta veces por segundo. Si cambiáramos la lámpara cada vez que tocando es verdadero, un clic de un segundo la encendería y apagaría sesenta veces. Este problema se llama debounce. La solución es guardar, en tocando antes, cómo estaba el sensor en el frame anterior, y actuar solo cuando el toque empieza: es decir, cuando ahora se toca y antes no.

## 10. reconocerGestos()

Para distinguir los gestos hace falta medir el tiempo, y para eso usamos millis(), que devuelve los milisegundos desde que empezó el programa. Cuando empieza un toque, guardamos la hora. Si el dedo sigue encima cuatrocientos milisegundos o más, es mantener, y el brillo va cambiando. Si se suelta antes, es un toque corto, y lo contamos. Cuando pasan cuatrocientos milisegundos sin ningún toque nuevo, decidimos según cuántos ha habido: uno enciende o apaga, dos cambian el color, y tres activan la vela.

## 11. Los gestos funcionando

Aquí se ven todos los gestos funcionando. En la esquina aparece el nombre del último gesto reconocido, que sirve para depurar. Fijaos en que, al mantener el dedo, el brillo sube; la siguiente vez baja; y la siguiente vuelve a subir. Eso es porque, al soltar, la variable subiendo se invierte. Con tres toques, la luz empieza a temblar como una vela, y con otros tres vuelve a ser fija.

## 12. Acciones de la lámpara

Cada acción de la lámpara es una función: encender, apagar, cambiar estado, cambiar color, regular brillo y cambiar vela. Así, cambiar qué gesto hace qué es cambiar una sola línea. Cambiar color pasa al siguiente color del array, con el mismo truco del módulo que en la media móvil. Regular brillo suma o resta dos en cada frame, sin pasar de doscientos cincuenta y cinco ni bajar de treinta, porque con brillo cero la lámpara parecería apagada. Y todas, menos encender y apagar, solo funcionan con la lámpara encendida, para que no se activen sin querer.

## 13. Efecto vela

El efecto vela está en calcular brillo visible. Si la vela está activada, multiplica el brillo por un valor que oscila entre cero coma cincuenta y cinco y uno, usando la función noise(). noise() da números aleatorios, pero suaves, así que la luz tiembla como una llama, sin saltos bruscos. El brillo guardado no cambia: solo cambia el que se dibuja.

## 14. Funciones que dibujan

Por último, las funciones que dibujan. El halo es un bucle for que dibuja ocho círculos, del más grande al más pequeño, para que ninguno tape a los demás. Cuanto más grande, más transparente, y todo depende del brillo. La luz es un círculo gris y, encima, el círculo del color, con transparencia igual al brillo. El sensor ya lo hemos visto. Y dibujar valores muestra la lectura, la media y el gesto, solo para depurar: en la entrega final se quita, porque la lámpara real no tiene pantalla.

## 15. Resumen

En resumen: leer, filtrar, reconocer el gesto, actuar y dibujar. De lo que no hemos visto en clase, usamos dist, millis() y noise(), que están en la referencia de Processing. Y la media móvil, el debounce y el reconocimiento de gestos se hicieron con ayuda de Claude, como indican los comentarios del código.
