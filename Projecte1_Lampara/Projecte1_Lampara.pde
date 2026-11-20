// ===================================================================
// PROCEDENCIA DEL CÓDIGO
// Este código se ha escrito con la ayuda de Claude (asistente de IA de
// Anthropic): propuso la estructura y el código, y lo hemos revisado,
// probado y adaptado al enunciado.
//
// Visto en clase (presentaciones M1–M6 y problemas de los Temas 1–6):
//  - Variables y tipos int, float, boolean, String; operador % (M1)
//  - fill con transparencia, background, noStroke, ellipse/circle,
//    width y height (M2)
//  - Condicionales if/else, &&, || y ! (M3, Tema 3)
//  - Arrays y bucles for (M4, M5)
//  - setup(), draw(), funciones con y sin retorno (return), random(),
//    mousePressed() y keyPressed(), y calcular la media de un array con
//    una función (M6, problemas Tema 6)
//  - Tipo color, mouseX/mouseY y comprobar si el ratón está dentro de una
//    figura con && (problemas Tema 6)
//  - text(), textSize(), textAlign() y map(): usados en mis Challenges 3 y 4
//
// NO visto en clase (referencia de Processing / ayuda de Claude):
//  - dist(): distancia entre dos puntos           (leerSensor)
//  - millis(): tiempo desde que empieza el sketch (gestos; el enunciado
//    pide investigarla en la referencia)
//  - noise(): números aleatorios suaves           (efecto vela; también
//    se usa en la pestaña Ruido, que da el profesor)
//  - Media móvil con array circular (posicion % longitud)  -> Claude
//  - Debounce con tocandoAntes                              -> Claude
//  - Reconocimiento de gestos (toque, doble, triple, mantener) -> Claude
//
// La pestaña Ruido la proporciona el profesor (sin modificar).
// ===================================================================

// ===== Estado de la lámpara =====
boolean encendida = false;  // boolean: solo dos estados, encendida o apagada
int brillo = 200;           // int: entero de 0 a 255, como un LED en Arduino
color colorLuz;             // color: guarda un color RGB en una sola variable
boolean vela = false;       // true si el efecto vela está activado
float brilloVisible;        // brillo que se dibuja (con la vela, parpadea)
float xLuz, yLuz, diamLuz;  // posición y tamaño de la luz

// Colores de la lámpara, en un array (el doble toque pasa al siguiente)
color[] colores = new color[4];
int indiceColor = 0;

// ===== Sensor =====
float xSensor, ySensor, diamSensor;  // posición y tamaño del sensor
float lectura;              // valor del sensor con ruido
float media;                // valor filtrado (media de las últimas lecturas)

// ===== Tocar =====
float umbral = 700;           // por encima de este valor se considera que se toca
boolean tocando = false;      // true mientras se toca el sensor
boolean tocandoAntes = false; // si se tocaba en el frame anterior

// ===== Filtro de media móvil =====
float[] ultimas = new float[10];   // las 10 últimas lecturas
int posicion = 0;                  // dónde se guarda la siguiente lectura

// ===== Gestos (tiempos con millis()) =====
int TIEMPO_MANTENER = 400;   // ms con el dedo encima para que cuente como "mantener"
int TIEMPO_ENTRE_TOQUES = 400; // ms máximos entre toques de un doble/triple toque
int inicioToque = 0;         // millis() cuando empezó el toque actual
int finToque = 0;            // millis() cuando acabó el último toque
int numToques = 0;           // toques cortos seguidos que llevamos
boolean manteniendo = false; // true mientras se mantiene el dedo
boolean subiendo = true;     // dirección del brillo en el próximo "mantener"
String ultimoGesto = "-";    // nombre del último gesto (para depurar)


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

  colores[0] = color(255, 190, 90);   // cálido
  colores[1] = color(255, 240, 210);  // neutro
  colores[2] = color(140, 200, 255);  // frío
  colores[3] = color(255, 100, 170);  // rosa
  colorLuz = colores[0];

  textSize(height * 0.04);
}

// draw() se lee como una lista de pasos: primero decide, después dibuja
void draw() {
  // --- Decidir ---
  lectura = anadirRuido(leerSensor());   // leer una vez por frame
  media = calcularMedia(lectura);        // filtrar el ruido
  tocando = estaTocando(media);          // ¿se toca?
  reconocerGestos();                     // toque, doble, triple o mantener
  tocandoAntes = tocando;
  brilloVisible = calcularBrilloVisible();

  // --- Dibujar ---
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
  float d = dist(mouseX, mouseY, xSensor, ySensor);   // dist(): referencia de Processing (no visto en clase)
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
// La media de un array con una función es de clase (M6). Guardar las lecturas
// en un array circular con % es idea de Claude (media móvil / rolling average).
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

// Reconoce los gestos midiendo el tiempo con millis():
//  - mantener 0,4 s  -> sube o baja el brillo (al revés que la vez anterior)
//  - 1 toque corto   -> encender / apagar
//  - 2 toques        -> cambiar de color
//  - 3 toques        -> efecto vela
// Lógica de gestos hecha con ayuda de Claude. millis(): referencia de Processing
// (el enunciado pide investigarla).
void reconocerGestos() {
  // Empieza un toque: apuntamos cuándo
  // Comparar con el frame anterior (tocandoAntes) es el debounce: ayuda de Claude
  if (tocando && !tocandoAntes) {
    inicioToque = millis();
  }

  // Dedo encima más de 0,4 s: es "mantener", no un toque
  if (tocando && millis() - inicioToque >= TIEMPO_MANTENER) {
    if (!manteniendo) {
      manteniendo = true;
      numToques = 0;                 // los toques de antes ya no cuentan
      if (subiendo) {
        ultimoGesto = "Mantener: subir brillo";
      } else {
        ultimoGesto = "Mantener: bajar brillo";
      }
    }
    regularBrillo();
  }

  // Acaba un toque
  if (!tocando && tocandoAntes) {
    if (manteniendo) {
      manteniendo = false;
      subiendo = !subiendo;          // la próxima vez, al revés
    } else {
      numToques = numToques + 1;     // era un toque corto: lo contamos
      finToque = millis();
    }
  }

  // Si ya hace 0,4 s del último toque y no ha llegado otro, decidimos cuántos han sido
  if (!tocando && numToques > 0 && millis() - finToque > TIEMPO_ENTRE_TOQUES) {
    if (numToques == 1) {
      ultimoGesto = "1 toque: encender/apagar";
      cambiarEstado();
    } else if (numToques == 2) {
      ultimoGesto = "2 toques: color";
      cambiarColor();
    } else {
      ultimoGesto = "3 toques: vela";
      cambiarVela();
    }
    numToques = 0;
  }
}

// Brillo que se ve: el normal, o con parpadeo si el efecto vela está activado
float calcularBrilloVisible() {
  if (vela) {
    // noise() da valores suaves entre 0 y 1: la llama tiembla sin saltos bruscos
    // noise(): referencia de Processing / ayuda de Claude (no visto en clase)
    return brillo * (0.55 + 0.45 * noise(millis() * 0.008));
  } else {
    return brillo;
  }
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

// Pasa al siguiente color del array (solo encendida)
void cambiarColor() {
  if (encendida) {
    indiceColor = (indiceColor + 1) % colores.length;
    colorLuz = colores[indiceColor];
  }
}

// Sube o baja el brillo un poco en cada frame mientras se mantiene (solo encendida)
void regularBrillo() {
  if (encendida) {
    if (subiendo) {
      brillo = brillo + 2;
      if (brillo > 255) brillo = 255;
    } else {
      brillo = brillo - 2;
      if (brillo < 30) brillo = 30;  // mínimo 30, si no parecería apagada
    }
  }
}

// Activa o desactiva el efecto vela (solo encendida)
void cambiarVela() {
  if (encendida) {
    vela = !vela;
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
      fill(colorLuz, brilloVisible / (i * 3));
      circulo(xLuz, yLuz, diamLuz * (1 + i * brilloVisible / 2000.0));
    }
  }
}

// Luz: círculo gris y, si está encendida, encima el color con transparencia = brillo
void dibujarLuz() {
  fill(90);
  circulo(xLuz, yLuz, diamLuz);
  if (encendida) {
    fill(colorLuz, brilloVisible);
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

// Valores y último gesto en la esquina (para depurar)
void dibujarValores() {
  fill(255);
  text("Lectura: " + int(lectura), width * 0.03, height * 0.07);
  text("Media: " + int(media), width * 0.03, height * 0.13);
  text("Gesto: " + ultimoGesto, width * 0.03, height * 0.19);
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
