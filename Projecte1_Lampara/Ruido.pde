// ===================================================================
//  Pestaña RUIDO – Proyecto 1: Lámpara Táctil
//
//  Un sensor capacitivo real nunca da un valor limpio. Esta función
//  coge el valor "ideal" de vuestro sensor y le añade lo que haría
//  el mundo real:
//    - una base que nunca es 0,
//    - una deriva lenta (la base sube y baja con el tiempo),
//    - un temblor constante,
//    - y, de vez en cuando, un pico falso sin que nadie toque.
//
//  Uso (una sola vez por fotograma y por sensor):
//    float valor = anadirRuido(leerSensor());
//
//  Podéis cambiar los números de abajo para hacer el sensor más o
//  menos ruidoso y poner a prueba vuestra solución.
// ===================================================================

float RUIDO_BASE       = 120;      // valor sin tocar nada
float RUIDO_DERIVA     = 40;       // cuánto sube y baja la base
float RUIDO_VEL_DERIVA = 0.00005;  // lo rápido que sube y baja la base
float RUIDO_TEMBLOR    = 12;       // temblor de cada lectura
float RUIDO_PICOS      = 0.004;    // probabilidad de un pico falso en cada lectura
float RUIDO_PICO_MIN   = 400;      // altura mínima de un pico falso
float RUIDO_PICO_MAX   = 1100;     // altura máxima de un pico falso

float anadirRuido(float valorIdeal) {
  float deriva = (noise(millis() * RUIDO_VEL_DERIVA) - 0.5) * 2 * RUIDO_DERIVA;
  float temblor = randomGaussian() * RUIDO_TEMBLOR;

  float pico = 0;
  if (random(1) < RUIDO_PICOS) {
    pico = random(RUIDO_PICO_MIN, RUIDO_PICO_MAX);
  }

  return max(0, valorIdeal + RUIDO_BASE + deriva + temblor + pico);
}
