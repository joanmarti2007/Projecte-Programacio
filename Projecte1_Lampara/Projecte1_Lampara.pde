// ===== Estado de la lámpara =====
boolean encendida = false;  // boolean: solo dos estados, encendida o apagada
int brillo = 200;           // int: entero de 0 a 255, como un LED en Arduino
color colorLuz;             // color: guarda un color RGB en una sola variable
float xLuz, yLuz, diamLuz;  // posición y tamaño de la luz

// ===== Sensor =====
float xSensor, ySensor, diamSensor;  // posición y tamaño del sensor
float lectura;              // valor del sensor con ruido (lo que daría el real)
float media;                // media de las últimas lecturas (valor filtrado)

// ===== Parte 4: tocar =====
float umbral = 700;          // por encima de este valor se considera que se toca
boolean tocando = false;     // true mientras se toca el sensor
boolean tocandoAntes = false; // si se tocaba en el frame anterior (debounce)

// ===== Parte 5: filtro de media móvil =====
float[] ultimas = new float[10];   // las 10 últimas lecturas
int posicion = 0;                  // dónde se guarda la siguiente lectura

void setup() {
  size(900, 600);
  noStroke();

  xLuz = width / 2;
  yLuz = height * 0.3;
  diamLuz = height * 0.3;

  xSensor = width / 2;
  ySensor = height * 0.8;
  diamSensor = height * 0.12;

  colorLuz = color(255, 190, 90);
  textSize(height * 0.04);
}

void draw() {
  // 1. Leer el sensor una sola vez por frame, con el ruido de un sensor real
  lectura = anadirRuido(leerSensor());

  // 2. Filtrar: usamos la media de las 10 últimas lecturas, no la lectura suelta
  media = calcularMedia(lectura);

  // 3. ¿Se está tocando? Solo si la media supera el umbral
  tocando = media > umbral;

  // 4. Modo interruptor con debounce: solo cuenta el momento en que EMPIEZA
  //    el toque (ahora se toca y en el frame anterior no). Mantener el click
  //    no vuelve a cambiar la lámpara, y soltarlo tampoco.
  if (tocando && !tocandoAntes) {
    encendida = !encendida;
  }
  tocandoAntes = tocando;

  // 5. Dibujar
  background(20);

  if (encendida) {                       // halo
    for (int i = 8; i > 0; i--) {
      fill(colorLuz, brillo / (i * 3));
      float d = diamLuz * (1 + i * brillo / 2000.0);
      ellipse(xLuz, yLuz, d, d);
    }
  }

  fill(90);                              // luz
  ellipse(xLuz, yLuz, diamLuz, diamLuz);
  if (encendida) {
    fill(colorLuz, brillo);
    ellipse(xLuz, yLuz, diamLuz, diamLuz);
  }

  if (tocando) {                         // sensor: blanco al tocar
    fill(255);
  } else {
    fill(60 + media / 4);                // más claro cuanto más cerca
  }
  ellipse(xSensor, ySensor, diamSensor, diamSensor);

  fill(255);                             // valores para depurar
  text("Lectura: " + int(lectura), width * 0.03, height * 0.07);
  text("Media: " + int(media), width * 0.03, height * 0.13);
}

// Devuelve 0 lejos, de 0 a 200 al acercarse, 200 encima y 1000 con click encima
float leerSensor() {
  float d = dist(mouseX, mouseY, xSensor, ySensor);
  float radio = diamSensor / 2;
  float alcance = diamSensor * 2;

  if (d <= radio && mousePressed) {
    return 1000;
  } else if (d <= radio) {
    return 200;
  } else if (d < alcance) {
    return map(d, alcance, radio, 0, 200);
  } else {
    return 0;
  }
}

// Guarda la lectura nueva en el array (sustituyendo la más antigua)
// y devuelve la media de las 10 últimas
float calcularMedia(float nueva) {
  ultimas[posicion] = nueva;
  posicion = (posicion + 1) % ultimas.length;   // 0, 1, ... 9, 0, 1...

  float suma = 0;
  for (int i = 0; i < ultimas.length; i++) {
    suma = suma + ultimas[i];
  }
  return suma / ultimas.length;
}

// ===================================================================
// PARTE 4 – Pruebas
// a) Modo timbre: encendida = tocando;  -> se enciende solo mientras se toca.
// b) Modo interruptor directo: if (tocando) encendida = !encendida;
//    -> draw() va a ~60 frames por segundo, así que manteniendo el click
//    un segundo la lámpara cambiaba unas 60 veces, y debería cambiar 1.
//    Solución (debounce): comparar con tocandoAntes y cambiar solo cuando
//    tocando pasa de false a true.
// Acercar el ratón sin click no la enciende (la lectura llega como mucho a
// 200, muy por debajo del umbral) y soltar el click encima tampoco la apaga
// (soltar es pasar de true a false, y eso no cambia nada).
// Las teclas L, W, S y C se han quitado (4.3).
//
// PARTE 5 – Ruido
// 5.1 Sin tocar nada, el valor nunca es 0: oscila alrededor de 120, sube y
//     baja lentamente (de ~80 a ~160), tiembla en cada frame unos ±12 y de
//     vez en cuando da un pico falso de 400 a 1100 durante un solo frame.
// 5.2 Sin filtro (comparando la lectura directamente con el umbral), en la
//     prueba de 1 minuto sin tocar + 30 s con el ratón encima, la lámpara
//     se encendía y apagaba sola muchas veces por culpa de los picos.
// 5.3/5.4 Estrategia: media móvil (rolling average) de las 10 últimas
//     lecturas. Un pico falso dura un solo frame, así que dentro de la
//     media pesa una décima parte: un pico de 1100 sube la media como
//     mucho ~110. Con el ratón encima sin click la media ronda 320 (+110
//     de un pico = ~430), lejos del umbral de 700. Un toque real da ~1100
//     en TODOS los frames, así que la media sí pasa de 700 en unos 5
//     frames (menos de 0,1 s) y el toque funciona siempre.
//     El umbral 700 queda entre lo máximo sin tocar (~430) y lo mínimo
//     tocando (~1050), con margen por los dos lados.
// ===================================================================
