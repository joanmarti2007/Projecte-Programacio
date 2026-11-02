size (600,600);
background (255);
strokeWeight(2);

int numVegades = int (random(10,201));

float xAnterior =  random(0,width);
float yAnterior = random(0,height);

for (int i = 0; i <= numVegades; i++)
{
float x = random(0,width);
float y = random(0,height);

//color
float vermell = map(i, 1, numVegades-1, 255, 0);
stroke (vermell, 0, 255);

//dibuix
line (xAnterior, yAnterior, x, y);
fill(255);
circle(xAnterior, yAnterior, 20);
textAlign(CENTER,CENTER);
fill (0);
text(i+1, xAnterior, yAnterior);

xAnterior=x;
yAnterior=y;
}

fill(255);
circle(xAnterior, yAnterior, 20);
textAlign(CENTER,CENTER);
