// --- Estado de la lámpara ---
boolean encendida = false;  // boolean: solo dos estados, encendida o apagada
int brillo = 200;           // int: entero de 0 a 255, como un LED en Arduino
color colorLuz;             // color: guarda un color RGB en una sola variable

color[] colores = new color[3];  // colores para la tecla 'C'
int indiceColor = 0;             // color actual dentro del array

// --- Posiciones y tamaños (se calculan en setup con width y height) ---
float xLuz, yLuz, diamLuz;
float xSensor, ySensor, diamSensor;
float lectura;              // valor del sensor en cada frame

void setup() {
  size(900, 600);
  noStroke();

  xLuz = width / 2;
  yLuz = height * 0.3;
  diamLuz = height * 0.3;

  xSensor = width / 2;
  ySensor = height * 0.8;
  diamSensor = height * 0.12;

  colores[0] = color(255, 190, 90);   // cálido
  colores[1] = color(140, 200, 255);  // frío
  colores[2] = color(255, 100, 170);  // rosa
  colorLuz = colores[0];

  textSize(height * 0.04);
}

void draw() {
  lectura = leerSensor();   // se lee el sensor una sola vez por frame
  background(20);           // fondo oscuro

  // Halo: solo si está encendida. Del círculo más grande al más pequeño;
  // cuanto más grande, más transparente. Tamaño y transparencia dependen del brillo.
  if (encendida) {
    for (int i = 8; i > 0; i--) {
      fill(colorLuz, brillo / (i * 3));
      float d = diamLuz * (1 + i * brillo / 2000.0);
      ellipse(xLuz, yLuz, d, d);
    }
  }

  // Luz: círculo gris y, si está encendida, encima el color con transparencia = brillo
  fill(90);
  ellipse(xLuz, yLuz, diamLuz, diamLuz);
  if (encendida) {
    fill(colorLuz, brillo);
    ellipse(xLuz, yLuz, diamLuz, diamLuz);
  }

  // Sensor: más claro cuanto mayor es la lectura (blanco al tocarlo)
  fill(50 + lectura);
  ellipse(xSensor, ySensor, diamSensor, diamSensor);

  // Valor del sensor en la esquina
  fill(255);
  text(lectura, width * 0.03, height * 0.07);
}

// Devuelve 0 lejos, de 0 a 200 al acercarse, 200 encima y 1000 con click encima
float leerSensor() {
  float d = dist(mouseX, mouseY, xSensor, ySensor);  // distancia ratón-sensor
  float radio = diamSensor / 2;
  float alcance = diamSensor * 2;                    // empieza a notar a 2 diámetros

  if (d <= radio && mousePressed) {
    return 1000;                 // click dentro del sensor
  } else if (d <= radio) {
    return 200;                  // encima sin click
  } else if (d < alcance) {
    return map(d, alcance, radio, 0, 200);   // más cerca = más valor
  } else {
    return 0;                    // lejos
  }
}

// Control provisional con teclado (mayúsculas y minúsculas)
void keyPressed() {
  if (key == 'l' || key == 'L') {
    encendida = !encendida;          // enciende / apaga
  }
  if (key == 'w' || key == 'W') {
    brillo = brillo + 15;            // sube el brillo...
    if (brillo > 255) brillo = 255;  // ...sin pasar de 255
  }
  if (key == 's' || key == 'S') {
    brillo = brillo - 15;            // baja el brillo...
    if (brillo < 30) brillo = 30;    // ...mínimo 30, si no parecería apagada
  }
  if (key == 'c' || key == 'C') {
    indiceColor = (indiceColor + 1) % 3;   // 0, 1, 2, 0, 1...
    colorLuz = colores[indiceColor];
  }
}
