"""Modelo 3D de la habitación: propuesta "tranquila y moderna".

Uso en Blender (4.2 o superior): pestaña Scripting > Abrir este archivo > Run Script.
Uso sin interfaz:  blender -b -P habitacion_3d.py -- --render <carpeta_salida>

Las medidas son estimadas a partir de las fotos; ajústalas en la sección MEDIDAS.
Ejes: X recorre la pared de la ventana (0 = pared del escritorio), Y va desde la
ventana (0) hasta la pared del armario PAX. Unidades en metros.
"""
import math
import sys

import bpy
from mathutils import Vector

# ----------------------------------------------------------------- MEDIDAS
ANCHO = 2.90      # pared de la ventana / pared del PAX
LARGO = 3.60      # pared del escritorio / pared de las puertas
ALTO = 2.60
MURO = 0.10

CAMA = dict(x0=0.0, ancho=0.95, largo=1.95, alto=0.42)          # cabecero contra pared escritorio
VENTANA = dict(x0=0.55, ancho=1.00, alepizo=0.95, alto=1.35)
ESCRITORIO = dict(y0=1.15, ancho=1.50, fondo=0.60, alto=0.74)   # LINNMON + ALEX, pared x=0
PAX = dict(x0=0.20, modulos=5, ancho_mod=0.50, fondo=0.58, alto=2.36)
MESA2 = dict(y0=2.30, ancho=0.70, fondo=0.60, alto=0.80)         # mesa con tablero perforado, pared x=ANCHO
PUERTAS = dict(y0=0.95, ancho=1.10, alto=2.30)                   # puertas dobles, pared x=ANCHO
ESPEJO = dict(ancho=0.40, alto=1.50)                             # entre escritorio y PAX, colgado

# ----------------------------------------------------------------- UTILIDADES
def limpiar():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def mat(nombre, color, rough=0.6, metal=0.0, emision=None, fuerza=0.0,
        transmision=0.0, textura=None):
    m = bpy.data.materials.new(nombre)
    m.use_nodes = True
    nt = m.node_tree
    p = nt.nodes.get("Principled BSDF")
    p.inputs["Base Color"].default_value = (*color, 1)
    p.inputs["Roughness"].default_value = rough
    p.inputs["Metallic"].default_value = metal
    if transmision:
        p.inputs["Transmission Weight"].default_value = transmision
        p.inputs["IOR"].default_value = 1.45
    if emision:
        p.inputs["Emission Color"].default_value = (*emision, 1)
        p.inputs["Emission Strength"].default_value = fuerza
    if textura == "parquet":
        b = nt.nodes.new("ShaderNodeTexBrick")
        b.inputs["Color1"].default_value = (0.50, 0.34, 0.20, 1)
        b.inputs["Color2"].default_value = (0.60, 0.43, 0.27, 1)
        b.inputs["Mortar"].default_value = (0.33, 0.22, 0.13, 1)
        b.inputs["Scale"].default_value = 1.0
        b.inputs["Mortar Size"].default_value = 0.004
        b.inputs["Brick Width"].default_value = 1.2
        b.inputs["Row Height"].default_value = 0.2
        coord = nt.nodes.new("ShaderNodeTexCoord")
        nt.links.new(coord.outputs["Object"], b.inputs["Vector"])
        nt.links.new(b.outputs["Color"], p.inputs["Base Color"])
    if textura == "lino":
        n = nt.nodes.new("ShaderNodeTexNoise")
        n.inputs["Scale"].default_value = 180
        bump = nt.nodes.new("ShaderNodeBump")
        bump.inputs["Strength"].default_value = 0.15
        nt.links.new(n.outputs["Fac"], bump.inputs["Height"])
        nt.links.new(bump.outputs["Normal"], p.inputs["Normal"])
    return m


def caja(nombre, sx, sy, sz, x, y, z, material, bisel=0.004, col=None):
    """Caja con la esquina mínima en (x, y, z)."""
    bpy.ops.mesh.primitive_cube_add(size=1, location=(x + sx / 2, y + sy / 2, z + sz / 2))
    o = bpy.context.active_object
    o.name = nombre
    o.scale = (sx, sy, sz)
    bpy.ops.object.transform_apply(scale=True)
    if bisel:
        mod = o.modifiers.new("bisel", "BEVEL")
        mod.width = bisel
        mod.segments = 3
    o.data.materials.append(material)
    for p in o.data.polygons:
        p.use_smooth = True
    return o


def luz_area(nombre, energia, color, tam, loc, rot=(0, 0, 0), forma="RECTANGLE", tam_y=None):
    d = bpy.data.lights.new(nombre, "AREA")
    d.energy = energia
    d.color = color
    d.shape = forma
    d.size = tam
    if tam_y:
        d.size_y = tam_y
    o = bpy.data.objects.new(nombre, d)
    o.location = loc
    o.rotation_euler = rot
    bpy.context.collection.objects.link(o)
    return o


def luz_punto(nombre, energia, color, loc, radio=0.05):
    d = bpy.data.lights.new(nombre, "POINT")
    d.energy = energia
    d.color = color
    d.shadow_soft_size = radio
    o = bpy.data.objects.new(nombre, d)
    o.location = loc
    bpy.context.collection.objects.link(o)
    return o


def camara(nombre, loc, mirar, lente=18):
    c = bpy.data.cameras.new(nombre)
    c.lens = lente
    o = bpy.data.objects.new(nombre, c)
    o.location = loc
    direc = Vector(mirar) - Vector(loc)
    o.rotation_euler = direc.to_track_quat("-Z", "Y").to_euler()
    bpy.context.collection.objects.link(o)
    return o


# ----------------------------------------------------------------- ESCENA
def construir():
    limpiar()
    sc = bpy.context.scene

    M = dict(
        pared=mat("Pared blanca", (0.86, 0.86, 0.84), 0.9),
        techo=mat("Techo", (0.88, 0.88, 0.87), 0.95),
        suelo=mat("Parquet roble", (0.55, 0.38, 0.22), 0.45, textura="parquet"),
        blanco=mat("Lacado blanco", (0.88, 0.88, 0.87), 0.35),
        greige=mat("Greige BERGSHULT", (0.58, 0.53, 0.46), 0.55),
        negro=mat("Negro mate", (0.02, 0.02, 0.02), 0.5, metal=0.3),
        roble=mat("Roble claro", (0.66, 0.48, 0.30), 0.5),
        lino=mat("Algodón natural", (0.80, 0.74, 0.64), 0.85, textura="lino"),
        manta=mat("Manta beige", (0.55, 0.42, 0.30), 0.9, textura="lino"),
        cojin=mat("Cojín greige", (0.45, 0.41, 0.36), 0.9, textura="lino"),
        alfombra=mat("Alfombra STOENSE", (0.58, 0.49, 0.38), 0.95, textura="lino"),
        cristal=mat("Cristal ahumado", (0.22, 0.22, 0.23), 0.05),
        espejo=mat("Espejo", (0.95, 0.95, 0.95), 0.0, metal=1.0),
        pantalla=mat("Pantalla", (0.01, 0.01, 0.012), 0.15),
        led=mat("LED 2700K", (1, 0.8, 0.55), 0.5, emision=(1.0, 0.72, 0.42), fuerza=12),
        panel=mat("Panel techo", (1, 1, 1), 0.5, emision=(1.0, 0.85, 0.7), fuerza=1.5),
        verde=mat("Planta", (0.12, 0.25, 0.12), 0.7),
        ceramica=mat("Cerámica", (0.82, 0.78, 0.72), 0.4),
        lamina1=mat("Lámina beige", (0.74, 0.66, 0.55), 0.8),
        lamina2=mat("Lámina carbón", (0.18, 0.17, 0.16), 0.8),
        libro=mat("Libros", (0.45, 0.40, 0.35), 0.7),
        guitarra=mat("Guitarra", (0.04, 0.03, 0.03), 0.2),
        golpeador=mat("Golpeador", (0.9, 0.9, 0.88), 0.3),
        mastil=mat("Mástil", (0.72, 0.50, 0.28), 0.4),
        radiador=mat("Radiador", (0.9, 0.9, 0.9), 0.3),
        tablero=mat("Tablero SKÅDIS", (0.9, 0.9, 0.88), 0.5),
        exterior=mat("Exterior", (0.2, 0.25, 0.35), 1, emision=(0.25, 0.32, 0.5), fuerza=1.5),
    )

    global COL
    COL = None

    # Suelo y techo
    caja("Suelo", ANCHO, LARGO, 0.02, 0, 0, -0.02, M["suelo"], 0)
    techo = caja("Techo", ANCHO, LARGO, 0.05, 0, 0, ALTO, M["techo"], 0)
    for i, (x, y) in enumerate([(0.9, 0.9), (2.0, 0.9), (0.9, 2.4), (2.0, 2.4)]):
        caja(f"Panel LED {i}", 0.22, 0.22, 0.01, x - 0.11, y - 0.11, ALTO - 0.01, M["panel"], 0)

    # Paredes
    caja("Pared escritorio", MURO, LARGO, ALTO, -MURO, 0, 0, M["pared"], 0)
    caja("Pared PAX", ANCHO, MURO, ALTO, 0, LARGO, 0, M["pared"], 0)
    v = VENTANA
    caja("Ventana bajo", ANCHO, MURO, v["alepizo"], 0, -MURO, 0, M["pared"], 0)
    caja("Ventana sobre", ANCHO, MURO, ALTO - v["alepizo"] - v["alto"], 0, -MURO,
         v["alepizo"] + v["alto"], M["pared"], 0)
    caja("Ventana izq", v["x0"], MURO, v["alto"], 0, -MURO, v["alepizo"], M["pared"], 0)
    caja("Ventana der", ANCHO - v["x0"] - v["ancho"], MURO, v["alto"], v["x0"] + v["ancho"],
         -MURO, v["alepizo"], M["pared"], 0)
    # carpintería + persiana a medio bajar
    fx, fz = v["x0"], v["alepizo"]
    for nombre, sx, sz, x, z in [("Marco inf", v["ancho"], 0.05, fx, fz),
                                 ("Marco sup", v["ancho"], 0.05, fx, fz + v["alto"] - 0.05),
                                 ("Marco izq", 0.05, v["alto"], fx, fz),
                                 ("Marco der", 0.05, v["alto"], fx + v["ancho"] - 0.05, fz),
                                 ("Marco centro", 0.04, v["alto"], fx + v["ancho"] / 2 - 0.02, fz)]:
        caja(nombre, sx, 0.07, sz, x, -0.08, z, M["blanco"], 0.003)
    caja("Exterior noche", v["ancho"] + 0.2, 0.02, v["alto"] + 0.2, fx - 0.1, -0.13, fz - 0.1, M["exterior"], 0)

    # Pared de puertas (x = ANCHO) con hueco
    p = PUERTAS
    caja("Pared puertas 1", MURO, p["y0"], ALTO, ANCHO, 0, 0, M["pared"], 0)
    caja("Pared puertas 2", MURO, LARGO - p["y0"] - p["ancho"], ALTO, ANCHO, p["y0"] + p["ancho"], 0, M["pared"], 0)
    caja("Pared puertas 3", MURO, p["ancho"], ALTO - p["alto"], ANCHO, p["y0"], p["alto"], M["pared"], 0)
    for i in range(2):
        hoja = caja(f"Puerta {i}", 0.04, p["ancho"] / 2 - 0.01, p["alto"] - 0.01,
                    ANCHO - 0.03, p["y0"] + i * p["ancho"] / 2 + 0.005, 0, M["blanco"], 0.004)
        for z0, h in [(0.15, 0.85), (1.15, 0.55), (1.85, 0.32)]:
            caja(f"Moldura {i}-{z0}", 0.012, p["ancho"] / 2 - 0.16, h, ANCHO - 0.042,
                 p["y0"] + i * p["ancho"] / 2 + 0.075, z0, M["blanco"], 0.004)
    caja("Tapajuntas", 0.02, p["ancho"] + 0.14, 0.07, ANCHO - 0.02, p["y0"] - 0.07, p["alto"], M["blanco"])

    # Zócalo
    caja("Zócalo A", 0.012, LARGO, 0.07, 0, 0, 0, M["blanco"], 0.002)
    caja("Zócalo B", ANCHO, 0.012, 0.07, 0, LARGO - 0.012, 0, M["blanco"], 0.002)

    # ---------------- CAMA (ropa natural, manta beige, cojines greige)
    c = CAMA
    caja("Canapé", c["largo"], c["ancho"], 0.30, 0, 0.02, 0, M["blanco"], 0.01)
    caja("Colchón", c["largo"] - 0.02, c["ancho"] - 0.04, 0.17, 0.01, 0.04, 0.30, M["lino"], 0.05)
    caja("Funda nórdica", c["largo"] - 0.45, c["ancho"] + 0.04, 0.09, 0.45, 0.0, 0.43, M["lino"], 0.04)
    caja("Manta", 0.55, c["ancho"] + 0.08, 0.025, 1.30, -0.02, 0.51, M["manta"], 0.012)
    caja("Almohada", 0.38, 0.62, 0.13, 0.04, 0.17, 0.46, M["lino"], 0.06)
    for i, y in enumerate([0.12, 0.52]):
        cj = caja(f"Cojín {i}", 0.12, 0.40, 0.38, 0.07, y, 0.50, M["cojin"], 0.06)
        cj.rotation_euler = (0, math.radians(-12), 0)

    # Alfombra
    caja("Alfombra", 1.33, 1.95, 0.012, 0.75, 0.85, 0, M["alfombra"], 0.004)

    # Repisa MOSSLANDA sobre la cama + 2 láminas KNOPPÄNG
    caja("MOSSLANDA", 0.09, 1.15, 0.03, 0, 0.0 - 0.10 + 0.0 + 0.05, 1.20, M["roble"], 0.003)
    for i, (y, lam) in enumerate([(0.05, "lamina1"), (0.55, "lamina2")]):
        caja(f"Marco {i}", 0.025, 0.43, 0.53, 0.05, y, 1.23, M["negro"], 0.003)
        caja(f"Lámina {i}", 0.005, 0.33, 0.43, 0.077, y + 0.05, 1.28, M[lam], 0)
    # Aplique SKURUP
    caja("SKURUP base", 0.03, 0.08, 0.12, 0, 0.98, 1.05, M["negro"], 0.004)
    bpy.ops.mesh.primitive_cone_add(radius1=0.075, radius2=0.03, depth=0.12, location=(0.22, 1.02, 1.00))
    pant = bpy.context.active_object
    pant.name = "SKURUP pantalla"
    pant.data.materials.append(M["negro"])
    caja("SKURUP brazo", 0.20, 0.015, 0.015, 0.03, 1.015, 1.10, M["negro"], 0.002)
    luz_punto("Luz aplique", 25, (1, 0.75, 0.5), (0.22, 1.02, 0.92), 0.04)

    # ---------------- ESCRITORIO (pared x=0)
    e = ESCRITORIO
    caja("Tablero escritorio", e["fondo"], e["ancho"], 0.03, 0, e["y0"], e["alto"] - 0.03, M["blanco"])
    caja("ALEX", 0.58, 0.36, e["alto"] - 0.03, 0.01, e["y0"] + e["ancho"] - 0.37, 0, M["blanco"])
    for i in range(5):
        caja(f"Cajón {i}", 0.005, 0.32, 0.12, 0.59, e["y0"] + e["ancho"] - 0.35,
             0.03 + i * 0.135, M["blanco"], 0.002)
    for yy in [e["y0"] + 0.03, ]:
        for xx in [0.03, e["fondo"] - 0.06]:
            caja("Pata", 0.03, 0.03, e["alto"] - 0.03, xx, yy, 0, M["blanco"], 0.002)
    caja("Monitor", 0.02, 0.55, 0.33, 0.12, e["y0"] + 0.45, e["alto"] + 0.12, M["pantalla"], 0.004)
    caja("Pie monitor", 0.15, 0.05, 0.13, 0.08, e["y0"] + 0.70, e["alto"], M["negro"], 0.003)
    caja("Teclado", 0.14, 0.42, 0.02, 0.33, e["y0"] + 0.52, e["alto"], M["negro"], 0.003)
    # Silla
    caja("Asiento", 0.48, 0.48, 0.07, 0.62, e["y0"] + 0.48, 0.45, M["negro"], 0.02)
    caja("Respaldo", 0.06, 0.46, 0.55, 1.08, e["y0"] + 0.49, 0.52, M["negro"], 0.02)
    caja("Columna", 0.05, 0.05, 0.40, 0.84, e["y0"] + 0.70, 0.05, M["negro"], 0.005)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.30, depth=0.03, location=(0.86, e["y0"] + 0.72, 0.05))
    bpy.context.active_object.data.materials.append(M["negro"])
    # Flexo TERTIAL beige
    caja("TERTIAL base", 0.12, 0.12, 0.02, 0.05, e["y0"] + 0.08, e["alto"], M["manta"], 0.005)
    caja("TERTIAL brazo", 0.02, 0.02, 0.42, 0.10, e["y0"] + 0.13, e["alto"], M["manta"], 0.003)
    bpy.ops.mesh.primitive_cone_add(radius1=0.07, radius2=0.03, depth=0.14,
                                    location=(0.22, e["y0"] + 0.14, e["alto"] + 0.40),
                                    rotation=(0, math.radians(120), 0))
    bpy.context.active_object.data.materials.append(M["manta"])
    luz_punto("Luz flexo", 18, (1, 0.78, 0.55), (0.28, e["y0"] + 0.14, e["alto"] + 0.33), 0.03)

    # 2 baldas BERGSHULT greige 120x20 + RAMSHULT negro + MITTLED
    for i, z in enumerate([1.25, 1.62]):
        caja(f"BERGSHULT {i}", 0.20, 1.20, 0.025, 0, e["y0"] + 0.15, z, M["greige"], 0.003)
        for yy in [e["y0"] + 0.30, e["y0"] + 1.15]:
            caja("RAMSHULT", 0.18, 0.02, 0.012, 0, yy, z - 0.012, M["negro"], 0.002)
            caja("RAMSHULT v", 0.012, 0.02, 0.20, 0, yy, z - 0.20, M["negro"], 0.002)
        caja(f"MITTLED {i}", 0.012, 1.10, 0.006, 0.10, e["y0"] + 0.20, z - 0.008, M["led"], 0)
        luz_area(f"Luz MITTLED {i}", 14, (1, 0.72, 0.45), 0.05, (0.10, e["y0"] + 0.75, z - 0.02),
                 tam_y=1.10)
    # objetos sobre baldas
    for j in range(7):
        caja(f"Libro {j}", 0.16, 0.025, 0.20 + (j % 3) * 0.02, 0.02, e["y0"] + 0.25 + j * 0.03, 1.275, M["libro"], 0.002)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.05, depth=0.20, location=(0.10, e["y0"] + 0.95, 1.375))
    bpy.context.active_object.data.materials.append(M["ceramica"])
    bpy.ops.mesh.primitive_cylinder_add(radius=0.06, depth=0.10, location=(0.10, e["y0"] + 0.70, 1.695))
    bpy.context.active_object.data.materials.append(M["ceramica"])
    bpy.ops.mesh.primitive_ico_sphere_add(radius=0.11, subdivisions=2, location=(0.10, e["y0"] + 0.70, 1.84))
    planta = bpy.context.active_object
    planta.scale = (1, 1, 0.8)
    planta.data.materials.append(M["verde"])
    caja("Marquito", 0.02, 0.22, 0.28, 0.04, e["y0"] + 1.00, 1.645, M["negro"], 0.003)
    caja("Foto", 0.004, 0.17, 0.22, 0.061, e["y0"] + 1.025, 1.675, M["lamina1"], 0)

    # Espejo colgado entre escritorio y PAX
    ey = e["y0"] + e["ancho"] + 0.03
    caja("Espejo marco", 0.025, ESPEJO["ancho"], ESPEJO["alto"], 0, ey, 0.35, M["negro"], 0.004)
    caja("Espejo", 0.004, ESPEJO["ancho"] - 0.04, ESPEJO["alto"] - 0.04, 0.026, ey + 0.02, 0.37, M["espejo"], 0)

    # ---------------- PAX (pared y=LARGO)
    px = PAX
    y_pax = LARGO - px["fondo"]
    for i in range(px["modulos"]):
        x = px["x0"] + i * px["ancho_mod"]
        caja(f"PAX {i}", px["ancho_mod"], px["fondo"], px["alto"], x, y_pax, 0, M["blanco"], 0.003)
        if i == 2:  # columna abierta con baldas
            caja("Hueco", px["ancho_mod"] - 0.04, 0.02, px["alto"] - 0.10, x + 0.02, y_pax - 0.001, 0.05, M["greige"], 0)
            for k in range(7):
                caja(f"Balda PAX {k}", px["ancho_mod"] - 0.04, 0.05, 0.02, x + 0.02, y_pax - 0.03, 0.30 + k * 0.29, M["blanco"], 0.002)
            caja("Caja KUGGIS hueco", 0.30, 0.04, 0.15, x + 0.10, y_pax - 0.035, 2.07, M["blanco"], 0.004)
            caja("Bandeja perfumes", 0.30, 0.04, 0.02, x + 0.10, y_pax - 0.035, 1.18, M["roble"], 0.003)
            for k, xx in enumerate([0.12, 0.19, 0.27, 0.34]):
                caja(f"Perfume {k}", 0.05, 0.03, 0.10 + (k % 2) * 0.03, x + xx, y_pax - 0.032, 1.20, M["ceramica"], 0.004)
        else:
            caja(f"Puerta PAX {i}", px["ancho_mod"] - 0.01, 0.02, px["alto"] - 0.02, x + 0.005, y_pax - 0.02, 0.01, M["blanco"], 0.003)
            for z0, h in [(0.1, 0.75), (0.93, 0.62), (1.63, 0.62)]:
                caja(f"Vidrio PAX {i}-{z0}", px["ancho_mod"] - 0.10, 0.005, h, x + 0.05, y_pax - 0.025, z0, M["cristal"], 0)
    # cajas KUGGIS sobre el PAX
    for i in range(5):
        caja(f"KUGGIS {i}", 0.37, 0.54, 0.21, px["x0"] + 0.06 + i * 0.49, y_pax + 0.02, px["alto"], M["blanco"], 0.01)
        caja(f"Tapa {i}", 0.37, 0.54, 0.015, px["x0"] + 0.06 + i * 0.49, y_pax + 0.02, px["alto"] + 0.21, M["roble"], 0.005)

    # ---------------- MESA 2 con SKÅDIS (pared x=ANCHO)
    m2 = MESA2
    xm = ANCHO - m2["fondo"]
    caja("Mesa 2", m2["fondo"], m2["ancho"], 0.03, xm, m2["y0"], m2["alto"] - 0.03, M["blanco"])
    for yy in [m2["y0"] + 0.05, m2["y0"] + m2["ancho"] - 0.09]:
        caja("Pata mesa 2", 0.04, 0.04, m2["alto"] - 0.03, xm + m2["fondo"] / 2, yy, 0, M["blanco"], 0.003)
    caja("Radiador", 0.08, 0.60, 0.55, ANCHO - 0.09, m2["y0"] + 0.05, 0.12, M["radiador"], 0.004)
    caja("SKÅDIS", 0.015, 0.56, 0.36, ANCHO - 0.016, m2["y0"] + 0.07, m2["alto"] + 0.05, M["tablero"], 0.002)
    caja("Balda mesa 2", 0.20, 0.70, 0.025, ANCHO - 0.20, m2["y0"], 1.45, M["greige"], 0.003)
    caja("MITTLED mesa 2", 0.012, 0.60, 0.006, ANCHO - 0.10, m2["y0"] + 0.05, 1.442, M["led"], 0)
    luz_area("Luz MITTLED mesa 2", 8, (1, 0.72, 0.45), 0.05, (ANCHO - 0.10, m2["y0"] + 0.35, 1.43), tam_y=0.6)
    caja("Cesta KNIPSA", 0.32, 0.33, 0.32, xm + 0.10, m2["y0"] + 0.15, 0, M["manta"], 0.02)
    # Perchero TJUSIG junto a la puerta
    caja("TJUSIG", 0.02, 0.40, 0.04, ANCHO - 0.02, p["y0"] + p["ancho"] + 0.08, 1.60, M["negro"], 0.003)

    # ---------------- GUITARRA a los pies de la cama (pared x=ANCHO, y<PUERTAS)
    gy, gz = 0.45, 1.05
    bpy.ops.mesh.primitive_cylinder_add(radius=0.17, depth=0.045, location=(ANCHO - 0.06, gy, gz),
                                        rotation=(0, math.radians(90), 0))
    cuerpo = bpy.context.active_object
    cuerpo.scale = (1, 1.0, 1.25)
    cuerpo.data.materials.append(M["guitarra"])
    caja("Golpeador", 0.005, 0.18, 0.22, ANCHO - 0.087, gy - 0.07, gz - 0.10, M["golpeador"], 0.01)
    caja("Mástil", 0.025, 0.055, 0.62, ANCHO - 0.07, gy - 0.027, gz + 0.18, M["mastil"], 0.004)
    caja("Pala", 0.02, 0.08, 0.18, ANCHO - 0.07, gy - 0.04, gz + 0.80, M["mastil"], 0.005)
    caja("Soporte guitarra", 0.06, 0.06, 0.03, ANCHO - 0.06, gy - 0.03, gz + 0.78, M["roble"], 0.004)

    # ---------------- LUZ AMBIENTE
    luz_area("Relleno techo", 30, (1, 0.85, 0.7), 1.6, (ANCHO / 2, LARGO / 2, ALTO - 0.05), tam_y=2.4)
    w = bpy.data.worlds.new("Mundo")
    w.use_nodes = True
    w.node_tree.nodes["Background"].inputs["Color"].default_value = (0.02, 0.025, 0.04, 1)
    sc.world = w

    # ---------------- CÁMARAS
    camara("Cam_general", (2.55, 3.0, 1.65), (0.3, 0.2, 0.9), 16)
    camara("Cam_escritorio", (2.6, 1.85, 1.45), (0.0, 1.85, 1.20), 17)
    camara("Cam_cama_puertas", (0.55, 2.7, 1.5), (2.9, 0.6, 1.0), 16)
    sc.camera = bpy.data.objects["Cam_general"]

    # ---------------- RENDER
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = 64
    sc.cycles.use_denoising = True
    sc.render.resolution_x = 1400
    sc.render.resolution_y = 1050
    sc.view_settings.view_transform = "AgX"
    sc.view_settings.look = "AgX - Medium High Contrast"
    sc.view_settings.exposure = -0.3
    return sc


def renderizar(salida):
    sc = bpy.context.scene
    for nombre in ["Cam_general", "Cam_escritorio", "Cam_cama_puertas"]:
        sc.camera = bpy.data.objects[nombre]
        sc.render.filepath = f"{salida}/{nombre}.png"
        bpy.ops.render.render(write_still=True)
        print("Render:", sc.render.filepath)


if __name__ == "__main__":
    construir()
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    if "--render" in argv:
        out = argv[argv.index("--render") + 1]
        bpy.ops.wm.save_as_mainfile(filepath=f"{out}/habitacion.blend")
        renderizar(out)
