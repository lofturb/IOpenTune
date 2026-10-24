# -*- coding: utf-8 -*-
"""
Genera los iconos e imagenes de arranque de OpenTune 9 a partir del icono
original (tools/icono-original.png), sin dependencias externas.

Solo usa la biblioteca estandar (zlib + struct), asi que funciona en Windows
con Python 3.8 sin Pillow.

Produce:
  app/Resources/              -> iconos del sistema e imagenes de arranque
  app/recursos-generados.txt  -> resumen de lo creado

Uso (desde la raiz del proyecto):
    python tools/generar_recursos.py
"""

import io
import math
import os
import struct
import sys
import zlib


def raiz_proyecto():
    if "--raiz" in sys.argv:
        i = sys.argv.index("--raiz")
        if i + 1 < len(sys.argv):
            return os.path.abspath(sys.argv[i + 1])
    actual = os.getcwd()
    if os.path.isdir(os.path.join(actual, "app")):
        return actual
    return os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


RAIZ = raiz_proyecto()
DESTINO = os.path.join(RAIZ, "app", "Resources")
ORIGEN = os.path.join(RAIZ, "tools", "icono-original.png")

FONDO_ARRANQUE = (0x0E, 0x0E, 0x10)
BLANCO = (0xFF, 0xFF, 0xFF)


def leer_png(ruta):
    """Lee un PNG RGBA de 8 bits sin entrelazar y devuelve (w, h, bytearray)."""
    with io.open(ruta, "rb") as f:
        datos = f.read()
    if datos[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("no es un PNG: %s" % ruta)

    pos = 8
    idat = b""
    ancho = alto = 0
    profundidad = tipo = entrelazado = None
    while pos + 8 <= len(datos):
        longitud = struct.unpack(">I", datos[pos:pos + 4])[0]
        clase = datos[pos + 4:pos + 8]
        cuerpo = datos[pos + 8:pos + 8 + longitud]
        pos += 12 + longitud
        if clase == b"IHDR":
            ancho, alto, profundidad, tipo, _comp, _filt, entrelazado = \
                struct.unpack(">IIBBBBB", cuerpo)
        elif clase == b"IDAT":
            idat += cuerpo
        elif clase == b"IEND":
            break

    if profundidad != 8 or tipo != 6 or entrelazado != 0:
        raise ValueError("se esperaba PNG RGBA de 8 bits sin entrelazar")

    crudo = zlib.decompress(idat)
    bpp = 4
    paso = ancho * bpp
    salida = bytearray(alto * paso)
    previa = bytearray(paso)
    p = 0
    for y in range(alto):
        filtro = crudo[p]
        p += 1
        linea = bytearray(crudo[p:p + paso])
        p += paso
        if filtro == 1:
            for x in range(bpp, paso):
                linea[x] = (linea[x] + linea[x - bpp]) & 0xFF
        elif filtro == 2:
            for x in range(paso):
                linea[x] = (linea[x] + previa[x]) & 0xFF
        elif filtro == 3:
            for x in range(paso):
                izquierda = linea[x - bpp] if x >= bpp else 0
                linea[x] = (linea[x] + ((izquierda + previa[x]) >> 1)) & 0xFF
        elif filtro == 4:
            for x in range(paso):
                a = linea[x - bpp] if x >= bpp else 0
                b = previa[x]
                c = previa[x - bpp] if x >= bpp else 0
                estimado = a + b - c
                pa, pb, pc = abs(estimado - a), abs(estimado - b), abs(estimado - c)
                if pa <= pb and pa <= pc:
                    predictor = a
                elif pb <= pc:
                    predictor = b
                else:
                    predictor = c
                linea[x] = (linea[x] + predictor) & 0xFF
        salida[y * paso:(y + 1) * paso] = linea
        previa = linea
    return ancho, alto, salida


def redimensionar(ancho, alto, pixeles, destino_ancho, destino_alto):
    """Redimensiona RGBA. Caja para reducir, bilineal para ampliar."""
    salida = bytearray(destino_ancho * destino_alto * 4)
    reducir = destino_ancho <= ancho and destino_alto <= alto

    for y in range(destino_alto):
        if reducir:
            y0 = int(y * alto / destino_alto)
            y1 = max(y0 + 1, int((y + 1) * alto / destino_alto))
            y1 = min(y1, alto)
        for x in range(destino_ancho):
            if reducir:
                x0 = int(x * ancho / destino_ancho)
                x1 = max(x0 + 1, int((x + 1) * ancho / destino_ancho))
                x1 = min(x1, ancho)
                suma = [0, 0, 0, 0]
                cuenta = 0
                for sy in range(y0, y1):
                    base = sy * ancho * 4
                    for sx in range(x0, x1):
                        o = base + sx * 4
                        for k in range(4):
                            suma[k] += pixeles[o + k]
                        cuenta += 1
                destino = (y * destino_ancho + x) * 4
                for k in range(4):
                    salida[destino + k] = int(round(suma[k] / float(cuenta)))
            else:
                sx = (x + 0.5) * ancho / destino_ancho - 0.5
                sy = (y + 0.5) * alto / destino_alto - 0.5
                x0 = int(math.floor(sx))
                y0 = int(math.floor(sy))
                fx = sx - x0
                fy = sy - y0
                x0 = max(0, min(ancho - 1, x0))
                y0 = max(0, min(alto - 1, y0))
                x1 = min(ancho - 1, x0 + 1)
                y1 = min(alto - 1, y0 + 1)
                destino = (y * destino_ancho + x) * 4
                for k in range(4):
                    v00 = pixeles[(y0 * ancho + x0) * 4 + k]
                    v10 = pixeles[(y0 * ancho + x1) * 4 + k]
                    v01 = pixeles[(y1 * ancho + x0) * 4 + k]
                    v11 = pixeles[(y1 * ancho + x1) * 4 + k]
                    arriba = v00 * (1 - fx) + v10 * fx
                    abajo = v01 * (1 - fx) + v11 * fx
                    salida[destino + k] = int(round(arriba * (1 - fy) + abajo * fy))
    return salida


def sobre_fondo(pixeles, fondo):
    """Comprime el canal alfa sobre un color opaco."""
    salida = bytearray(len(pixeles))
    fr, fg, fb = fondo
    for i in range(0, len(pixeles), 4):
        a = pixeles[i + 3]
        if a == 255:
            salida[i] = pixeles[i]
            salida[i + 1] = pixeles[i + 1]
            salida[i + 2] = pixeles[i + 2]
        else:
            salida[i] = (pixeles[i] * a + fr * (255 - a)) // 255
            salida[i + 1] = (pixeles[i + 1] * a + fg * (255 - a)) // 255
            salida[i + 2] = (pixeles[i + 2] * a + fb * (255 - a)) // 255
        salida[i + 3] = 255
    return salida


def escribir_png(ruta, ancho, alto, pixeles):
    filas = []
    for y in range(alto):
        inicio = y * ancho * 4
        filas.append(b"\x00" + bytes(pixeles[inicio:inicio + ancho * 4]))
    crudo = b"".join(filas)

    def bloque(tipo, datos):
        return (struct.pack(">I", len(datos)) + tipo + datos
                + struct.pack(">I", zlib.crc32(tipo + datos) & 0xFFFFFFFF))

    cabecera = struct.pack(">IIBBBBB", ancho, alto, 8, 6, 0, 0, 0)
    contenido = (b"\x89PNG\r\n\x1a\n"
                 + bloque(b"IHDR", cabecera)
                 + bloque(b"IDAT", zlib.compress(crudo, 9))
                 + bloque(b"IEND", b""))
    with io.open(ruta, "wb") as f:
        f.write(contenido)


def arranque(ancho, alto, icono_ancho, icono_alto, icono_pixeles):
    """Fondo oscuro con el icono centrado."""
    pixeles = bytearray(ancho * alto * 4)
    for y in range(alto):
        base = y * ancho * 4
        for x in range(ancho):
            o = base + x * 4
            pixeles[o] = FONDO_ARRANQUE[0]
            pixeles[o + 1] = FONDO_ARRANQUE[1]
            pixeles[o + 2] = FONDO_ARRANQUE[2]
            pixeles[o + 3] = 255

    lado = int(min(ancho, alto) * 0.34)
    lado = max(64, lado)
    escalado = redimensionar(icono_ancho, icono_alto, icono_pixeles, lado, lado)
    ox = (ancho - lado) // 2
    oy = (alto - lado) // 2

    for y in range(lado):
        for x in range(lado):
            o = (y * lado + x) * 4
            a = escalado[o + 3]
            if a == 0:
                continue
            destino = ((oy + y) * ancho + (ox + x)) * 4
            for k in range(3):
                actual = pixeles[destino + k]
                pixeles[destino + k] = (escalado[o + k] * a + actual * (255 - a)) // 255
    return pixeles


ICONOS = [
    ("Icon-Small.png", 29),
    ("Icon-Small@2x.png", 58),
    ("Icon-Small-40.png", 40),
    ("Icon-Small-40@2x.png", 80),
    ("Icon-Small-40@3x.png", 120),
    ("Icon-60.png", 60),
    ("Icon-60@2x.png", 120),
    ("Icon-60@3x.png", 180),
    ("Icon-72.png", 72),
    ("Icon-72@2x.png", 144),
    ("Icon-76.png", 76),
    ("Icon-76@2x.png", 152),
    ("iTunesArtwork", 512),
]

ARRANQUES = [
    ("LaunchImage.png", 320, 480),
    ("LaunchImage@2x.png", 640, 960),
    ("LaunchImage-568h@2x.png", 640, 1136),
    ("LaunchImage-700.png", 320, 480),
    ("LaunchImage-700@2x.png", 640, 960),
    ("LaunchImage-700-568h@2x.png", 640, 1136),
    ("LaunchImage-700-Portrait.png", 768, 1024),
    ("LaunchImage-700-Portrait@2x.png", 1536, 2048),
    ("LaunchImage-700-Landscape.png", 1024, 768),
    ("LaunchImage-700-Landscape@2x.png", 2048, 1536),
]


def main():
    if not os.path.isfile(ORIGEN):
        print("ERROR: no existe %s" % ORIGEN)
        return 1
    if not os.path.isdir(DESTINO):
        os.makedirs(DESTINO)

    ancho, alto, pixeles = leer_png(ORIGEN)
    print("  Origen:  %s (%dx%d)" % (ORIGEN, ancho, alto))
    print("  Destino: %s" % DESTINO)
    print("")

    hechos = []
    for nombre, lado in ICONOS:
        escalado = redimensionar(ancho, alto, pixeles, lado, lado)
        opaco = sobre_fondo(escalado, BLANCO)
        escribir_png(os.path.join(DESTINO, nombre), lado, lado, opaco)
        hechos.append("%s  %dx%d" % (nombre, lado, lado))

    for nombre, ancho_img, alto_img in ARRANQUES:
        imagen = arranque(ancho_img, alto_img, ancho, alto, pixeles)
        escribir_png(os.path.join(DESTINO, nombre), ancho_img, alto_img, imagen)
        hechos.append("%s  %dx%d" % (nombre, ancho_img, alto_img))

    resumen = os.path.join(RAIZ, "app", "recursos-generados.txt")
    with io.open(resumen, "w", encoding="utf-8") as f:
        f.write("Recursos generados por tools/generar_recursos.py\n\n")
        f.write("\n".join(hechos) + "\n")

    print("Generados %d archivos en app/Resources" % len(hechos))
    for h in hechos:
        print("   ", h)
    return 0


if __name__ == "__main__":
    sys.exit(main())
