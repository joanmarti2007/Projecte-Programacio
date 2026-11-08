// Joan Martí Muñoz
// Proyecto 1 – Estudio de Interacción: lámpara táctil
// Partes 1, 2 y 3 (entorno, luz y sensor)


// =====================================================================
// PARTE 2.1 – Variables de estado de la lámpara
// =====================================================================

// boolean: la lámpara solo tiene dos estados posibles, encendida (true)
// o apagada (false). No hace falta ningún otro valor.
boolean encendida = false;

// int: el brillo es un número ENTERO de 0 a 255. Es el mismo rango que usa
// Arduino con analogWrite() para regular un LED (8 bits = 256 niveles),
// así que no necesitamos decimales.
int brillo = 200;

// color: Processing guarda un color RGB entero (rojo, verde y azul) en una
// sola variable del tipo color, que después podemos pasar a fill().
color colorLuz;

// Colores entre los que cambia la tecla 'C' (array de 3 colores)
color[] colores = new color[3];
int indiceColor = 0;        // posición del color actual dentro del array

int brilloMinimo = 30;      // encendida con brillo 0 parecería apagada
int pasoBrillo = 15;        // cuánto sube o baja el brillo con 'W' y 'S'
int numHalos = 8;           // número de círculos del halo

// Posición y tamaño de la luz (se calculan en setup() con width y height)
float xLuz, yLuz, diamLuz;


// =====================================================================
// PARTE 3.1 – Variables del sensor
// =====================================================================

float xSensor, ySensor, diamSensor;
float distanciaDeteccion;   // a partir de aquí el sensor empieza a notar el ratón
float lectura;              // valor del sensor en el frame actual


// =====================================================================
// PARTE 1 – Configuración del entorno
// =====================================================================

void setup() {
  size(900, 600);

  // Todo en función de width y height -> responsive
  xLuz = width * 0.5;
  yLuz = height * 0.3;
  diamLuz = height * 0.3;

  xSensor = width * 0.5;
  ySensor = height * 0.78;
  diamSensor = height * 0.12;
  distanciaDeteccion = diamSensor * 2;   // dos diámetros desde el centro

  colores[0] = color(255, 190, 90);    // cálido
  colores[1] = color(140, 200, 255);   // frío
  colores[2] = color(255, 100, 170);   // rosa
  colorLuz = colores[indiceColor];

  textSize(height * 0.035);
}

void draw() {
  // 3.3 – Leemos el sensor UNA sola vez al principio de cada draw()
  lectura = leerSensor();

  background(15, 15, 25);   // 1.2 – fondo oscuro

  dibujarLuz();
  dibujarSensor();
  mostrarLectura();
}


// =====================================================================
// PARTE 2.2 y 2.3 – Dibujo de la luz y del halo
// =====================================================================

void dibujarLuz() {
  noStroke();

  // El halo solo tiene sentido con la luz encendida
  if (encendida) {
    dibujarHalo();
  }

  // Círculo gris de base: es lo que se ve cuando está apagada
  fill(90);
  circle(xLuz, yLuz, diamLuz);

  // Encendida: encima, el círculo de colorLuz con transparencia = brillo.
  // brillo 0 -> se ve el gris; brillo 255 -> se ve colorLuz entero.
  if (encendida) {
    fill(colorLuz, brillo);
    circle(xLuz, yLuz, diamLuz);
  }
}

void dibujarHalo() {
  // Dibujamos del círculo más grande al más pequeño: así, aunque fueran
  // opacos, se verían todos. Cuanto más grande (i mayor), más transparente.
  // Tanto el tamaño como la transparencia dependen del brillo.
  for (int i = numHalos; i >= 1; i--) {
    float diam = diamLuz + i * (diamLuz * 0.12) * brillo / 255.0;
    float transparencia = brillo * 0.35 / i;
    fill(colorLuz, transparencia);
    circle(xLuz, yLuz, diam);
  }
}


// =====================================================================
// PARTE 2.4 – Control provisional con teclado (se quita en la Parte 4)
// =====================================================================

void keyPressed() {
  // Comprobamos minúscula y MAYÚSCULA
  if (key == 'l' || key == 'L') {
    encendida = !encendida;
  } else if (key == 'w' || key == 'W') {
    brillo = brillo + pasoBrillo;
    if (brillo > 255) {
      brillo = 255;
    }
  } else if (key == 's' || key == 'S') {
    brillo = brillo - pasoBrillo;
    if (brillo < brilloMinimo) {
      brillo = brilloMinimo;
    }
  } else if (key == 'c' || key == 'C') {
    indiceColor = indiceColor + 1;
    if (indiceColor >= colores.length) {
      indiceColor = 0;
    }
    colorLuz = colores[indiceColor];
    // brillo es otra variable, por eso cambiar de color no lo modifica
  }
}


// =====================================================================
// PARTE 3 – El sensor
// =====================================================================

// 3.2 – Función con retorno que simula un sensor capacitivo
//   lejos (más de distanciaDeteccion)   -> 0
//   acercándose                         -> de 0 a 200
//   dentro del círculo                  -> 200
//   click DENTRO del círculo            -> 1000
float leerSensor() {
  float d = distancia(mouseX, mouseY, xSensor, ySensor);
  float radio = diamSensor / 2;

  if (d <= radio) {
    if (mousePressed) {
      return 1000;            // dedo tocando
    } else {
      return 200;             // dedo encima, sin tocar
    }
  } else if (d < distanciaDeteccion) {
    // Cuanto más cerca, más valor: en el borde 200, a distanciaDeteccion 0.
    // Un click aquí NO cuenta como click, solo cuenta la distancia.
    return map(d, distanciaDeteccion, radio, 0, 200);
  } else {
    return 0;                 // demasiado lejos
  }
}

// Distancia entre dos puntos (teorema de Pitágoras).
// Hace lo mismo que la función dist() de Processing.
float distancia(float x1, float y1, float x2, float y2) {
  float dx = x2 - x1;
  float dy = y2 - y1;
  return sqrt(dx * dx + dy * dy);
}

// 3.1 y 3.5 – Dibujo del sensor, con un color que cambia según la lectura
void dibujarSensor() {
  // Zona de detección (solo para depurar)
  noFill();
  stroke(255, 30);
  strokeWeight(1);
  circle(xSensor, ySensor, distanciaDeteccion * 2);

  if (lectura >= 1000) {
    fill(80, 255, 140);                          // tocando: verde
  } else {
    float t = lectura / 200.0;                   // 0 = lejos, 1 = encima
    fill(60 + 40 * t, 60 + 140 * t, 70 + 185 * t);   // de gris a azul claro
  }
  stroke(160);
  strokeWeight(2);
  circle(xSensor, ySensor, diamSensor);
  noStroke();
}

// 3.4 – Valor del sensor en una esquina (y el estado, para depurar)
void mostrarLectura() {
  fill(220);
  textAlign(LEFT, TOP);
  text("Sensor: " + int(lectura), width * 0.02, height * 0.02);
  text("Brillo: " + brillo, width * 0.02, height * 0.07);
  text("Encendida: " + encendida, width * 0.02, height * 0.12);
}


// =====================================================================
// Respuestas a las preguntas ¿?
// =====================================================================
// - Si bajo el brillo y cambio de color, ¿se mantiene? Sí: brillo y
//   colorLuz son variables distintas, 'C' solo cambia colorLuz.
// - ¿Encendida con brillo 0? No se distinguiría de apagada (solo se vería
//   el gris), por eso brilloMinimo = 30.
// - Halo: con círculos opacos hay que dibujar del más grande al más
//   pequeño, si no el grande tapa a los demás. Semitransparentes y del
//   mismo color se verían todos igualmente, pero dibujarlos del grande al
//   pequeño sigue funcionando en los dos casos.
// - Con la luz apagada no se dibuja el halo.
// - Gráfica distancia/valor: 0 lejos, recta que sube de 0 a 200 al
//   acercarse, 200 plano dentro del círculo y un salto a 1000 con click
//   dentro. Son 4 casos.
