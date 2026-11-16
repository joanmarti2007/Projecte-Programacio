// ===== Estado de la lámpara =====
boolean encendida = false;  // boolean: solo dos estados, encendida o apagada
int brillo = 200;           // int: entero de 0 a 255, como un LED en Arduino
color colorLuz;             // color: guarda un color RGB en una sola variable
float xLuz, yLuz, diamLuz;  // posición y tamaño de la luz

// ===== Sensor =====
float xSensor, ySensor, diamSensor;  // posición y tamaño del sensor
float lectura;              // valor del sensor con ruido
float media;                // valor filtrado (media de las últimas lecturas)

// ===== Tocar =====
float umbral = 700;           // por encima de este valor se considera que se toca
boolean tocando = false;      // true mientras se toca el sensor
boolean tocandoAntes = false; // si se tocaba en el frame anterior (debounce)

// ===== Filtro de media móvil =====
float[] ultimas = new float[10];   // las 10 últimas lecturas
int posicion = 0;                  // dónde se guarda la siguiente lectura


void setup() {
  size(900, 600);
  noStroke();

  // Todo en función de width y height (responsive)
  xLuz = width / 2;
  yLuz = height * 0.3;
  diamLuz = height * 0.3;

  xSensor = width / 2;
  ySensor = height * 0.8;
  diamSensor = height * 0.12;

  colorLuz = color(255, 190, 90);
  textSize(height * 0.04);
}

// draw() se lee como una lista de pasos: primero decide, después dibuja
void draw() {
  // --- Decidir (el "cerebro": lo que se llevará a Arduino) ---
  lectura = anadirRuido(leerSensor());   // leer una vez por frame
  media = calcularMedia(lectura);        // filtrar el ruido
  tocando = estaTocando(media);          // ¿se toca?

  if (empiezaToque(tocando, tocandoAntes)) {
    cambiarEstado();                     // un toque = un cambio
  }
  tocandoAntes = tocando;

  // --- Dibujar (solo pantalla: en Arduino será el LED) ---
  background(20);
  dibujarHalo();
  dibujarLuz();
  dibujarSensor();
  dibujarValores();
}


// =====================================================================
// FUNCIONES QUE DECIDEN
// =====================================================================

// Simula el sensor con el ratón:
// 0 lejos, de 0 a 200 al acercarse, 200 encima y 1000 con click encima
float leerSensor() {
  float d = dist(mouseX, mouseY, xSensor, ySensor);
  float radio = diamSensor / 2;
  float alcance = diamSensor * 2;        // empieza a notar a 2 diámetros

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

// Guarda la lectura en el array (sustituye la más antigua)
// y devuelve la media de las 10 últimas
float calcularMedia(float nueva) {
  ultimas[posicion] = nueva;
  posicion = (posicion + 1) % ultimas.length;

  float suma = 0;
  for (int i = 0; i < ultimas.length; i++) {
    suma = suma + ultimas[i];
  }
  return suma / ultimas.length;
}

// true si el valor filtrado supera el umbral
boolean estaTocando(float valor) {
  return valor > umbral;
}

// true solo en el frame en que empieza el toque (antes no, ahora sí): debounce
boolean empiezaToque(boolean ahora, boolean antes) {
  return ahora && !antes;
}


// =====================================================================
// ACCIONES DE LA LÁMPARA (una función por acción)
// =====================================================================

void encender() {
  encendida = true;
}

void apagar() {
  encendida = false;
}

// Si estaba encendida la apaga, y si estaba apagada la enciende
void cambiarEstado() {
  if (encendida) {
    apagar();
  } else {
    encender();
  }
}


// =====================================================================
// FUNCIONES QUE DIBUJAN
// =====================================================================

// Círculo a partir del diámetro (se usa en todos los dibujos)
void circulo(float x, float y, float diametro) {
  ellipse(x, y, diametro, diametro);
}

// Halo: solo encendida. Del círculo más grande al más pequeño;
// cuanto más grande, más transparente. Depende del brillo.
void dibujarHalo() {
  if (encendida) {
    for (int i = 8; i > 0; i--) {
      fill(colorLuz, brillo / (i * 3));
      circulo(xLuz, yLuz, diamLuz * (1 + i * brillo / 2000.0));
    }
  }
}

// Luz: círculo gris y, si está encendida, encima el color con transparencia = brillo
void dibujarLuz() {
  fill(90);
  circulo(xLuz, yLuz, diamLuz);
  if (encendida) {
    fill(colorLuz, brillo);
    circulo(xLuz, yLuz, diamLuz);
  }
}

// Sensor: blanco al tocar, y más claro cuanto más cerca está el ratón
void dibujarSensor() {
  if (tocando) {
    fill(255);
  } else {
    fill(60 + media / 4);
  }
  circulo(xSensor, ySensor, diamSensor);
}

// Valores del sensor en la esquina (para depurar)
void dibujarValores() {
  fill(255);
  text("Lectura: " + int(lectura), width * 0.03, height * 0.07);
  text("Media: " + int(media), width * 0.03, height * 0.13);
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
