"""Coloca 4 pósters plafonados (sin marco, sobre tablero de 5 mm) encima del escritorio."""
import os
import sys
import numpy as np
from PIL import Image, ImageFilter

foto, salida, *posters = sys.argv[1:]
base = Image.open(foto).convert("RGB")
W, H = base.size

ALTO = int(os.environ.get("ALTO", 262))            # px ≈ 55 cm a la escala del escritorio (150 cm ≈ 720 px)
HUECO = int(os.environ.get("HUECO", 22))            # ≈ 4,5 cm entre pósters
CENTRO_X = 1155       # centro del escritorio
BASE_Y = int(os.environ.get("BASE_Y", 905))          # borde inferior ≈ 40 cm sobre la mesa
GROSOR = 4            # canto del plafonado visible desde abajo

imgs = []
for p in posters:
    im = Image.open(p).convert("RGB")
    m = 0.025  # recorte de bordes (quita restos blancos de las imágenes)
    im = im.crop((int(im.width*m), int(im.height*m), int(im.width*(1-m)), int(im.height*(1-m-0.02))))
    im = im.resize((round(ALTO * im.width / im.height), ALTO), Image.LANCZOS)
    imgs.append(im)
total = sum(i.width for i in imgs) + HUECO * (len(imgs) - 1)
x = CENTRO_X - total // 2
top = BASE_Y - ALTO

# Iluminación local de la pared (pared desenfocada) para sombrear los pósters igual que la pared
pared = np.asarray(base.filter(ImageFilter.GaussianBlur(40)), dtype=np.float32)
blanco_ref = 232.0

sombra = Image.new("L", (W, H), 0)
capa = base.copy()
mascara = Image.new("L", (W, H), 0)
pos = []
for im in imgs:
    pos.append((x, top, im))
    sombra.paste(150, (x + 3, top + 8, x + im.width + 5, BASE_Y + GROSOR + 10))
    x += im.width + HUECO
sombra = sombra.filter(ImageFilter.GaussianBlur(9))
s = np.asarray(sombra, dtype=np.float32)[..., None] / 255.0 * 0.32
arr = np.asarray(capa, dtype=np.float32) * (1 - s)

rng = np.random.default_rng(7)
for x0, y0, im in pos:
    a = np.asarray(im, dtype=np.float32)
    # bajar un poco contraste/saturación (papel mate fotografiado)
    gris = a.mean(axis=2, keepdims=True)
    a = gris + (a - gris) * 0.9
    a = 128 + (a - 128) * 0.92
    luz = pared[y0:y0 + im.height, x0:x0 + im.width] / blanco_ref
    a = a * luz
    a += rng.normal(0, 2.5, a.shape)
    arr[y0:y0 + im.height, x0:x0 + im.width] = a
    # canto inferior del tablero
    canto = pared[y0 + im.height:y0 + im.height + GROSOR, x0:x0 + im.width] * 0.72
    arr[y0 + im.height:y0 + im.height + GROSOR, x0:x0 + im.width] = canto

out = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8))
# suavizar bordes pegados para igualar la nitidez de la foto
zona = out.crop((pos[0][0] - 20, top - 20, pos[-1][0] + pos[-1][2].width + 20, BASE_Y + 30))
out.paste(zona.filter(ImageFilter.GaussianBlur(0.6)), (pos[0][0] - 20, top - 20))
out.save(salida, quality=95)
print("ok", salida, "zona x", pos[0][0], "-", pos[-1][0] + pos[-1][2].width)
