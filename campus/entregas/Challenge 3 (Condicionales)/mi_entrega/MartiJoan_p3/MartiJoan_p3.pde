size(200, 370);
background(255);
strokeWeight(2);
rect(50, 50, 100, 200);
line(55, 150, 145, 150);
strokeWeight(15);
stroke(219, 165, 13);
point(100, 150);

int randomNumtop = int (random(7));

if (randomNumtop == 1) {
  stroke(0);
  strokeWeight(15);
  point(100, 100);
}
else if (randomNumtop == 2) {
  stroke(0);
  strokeWeight(15);
  point(75, 75);
  point(125, 125);
}
else if (randomNumtop == 3) {
  stroke(0);
  strokeWeight(15);
  point(100, 100);
  point(75, 75);
  point(125, 125);
}
else if (randomNumtop == 4) {
  stroke(0);
  strokeWeight(15);
  point(75, 75);
  point(75, 125);
  point(125, 75);
  point(125, 125);
}
else if (randomNumtop == 5) {
  stroke(0);
  strokeWeight(15);
  point(100, 100);
  point(75, 75);
  point(75, 125);
  point(125, 75);
  point(125, 125);
}
else if (randomNumtop == 6) {
  stroke(0);
  strokeWeight(15);
  point(75, 75);
  point(75, 125);
  point(125, 75);
  point(125, 125);
  point(75, 100);
  point(125, 100);
}

int randomNumbot = int (random(7));

if (randomNumbot == 1) {
  stroke(0);
  strokeWeight(15);
  point(100, 200);
}
else if (randomNumbot == 2) {
  stroke(0);
  strokeWeight(15);
  point(75, 175);
  point(125, 225);
}
else if (randomNumbot == 3) {
  stroke(0);
  strokeWeight(15);
  point(100, 200);
  point(75, 175);
  point(125, 225);
}
else if (randomNumbot == 4) {
  stroke(0);
  strokeWeight(15);
  point(75, 175);
  point(75, 225);
  point(125, 175);
  point(125, 225);
}
else if (randomNumbot == 5) {
  stroke(0);
  strokeWeight(15);
  point(100, 200);
  point(75, 175);
  point(75, 225);
  point(125, 175);
  point(125, 225);
}
else if (randomNumbot == 6) {
  stroke(0);
  strokeWeight(15);
  point(75, 175);
  point(75, 225);
  point(125, 175);
  point(125, 225);
  point(75, 200);
  point(125, 200);
}

String Ficha = "Generada la Ficha " + randomNumtop + "-" + randomNumbot;
fill(0);
textSize(14);
text(Ficha,40,300);
