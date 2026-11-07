#!/usr/bin/env python3
"""Zeichnet thumbnail.png (144 × 144) für das Mod-Portal: Tablet mit Button-Raster im Factorio-Stil.
Aufruf: python3 tools/make_thumbnail.py   (braucht Pillow)"""
import math
import os
from PIL import Image, ImageDraw

S = 4                      # in 4-facher Größe zeichnen, dann glatt verkleinern
W = 144 * S
BG = (30, 30, 32)
ORANGE = (230, 160, 70)
BROWN = (74, 59, 34)
GREEN = (47, 158, 107)
BLUE = (47, 111, 158)
RED = (192, 57, 43)
LIGHT = (225, 225, 225)

img = Image.new("RGB", (W, W), BG)
d = ImageDraw.Draw(img)

# Zahnrad im Hintergrund (Factorio), angeschnitten rechts unten
cx, cy, r_out, r_in, teeth = 118 * S, 118 * S, 52 * S, 40 * S, 12
pts = []
for i in range(teeth * 2):
    for k in (0, 1):
        a = (i + k * 0.9) * math.pi / teeth
        r = r_out if i % 2 == 0 else r_in
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
d.polygon(pts, fill=(58, 52, 44))
d.ellipse((cx - 16 * S, cy - 16 * S, cx + 16 * S, cy + 16 * S), fill=BG)

# Tablet
x0, y0, x1, y1 = 16 * S, 22 * S, 124 * S, 112 * S
d.rounded_rectangle((x0, y0, x1, y1), radius=10 * S, fill=(18, 18, 20), outline=ORANGE, width=4 * S)
# Button-Raster 3 × 3
cols, rows, gap = 3, 3, 6 * S
gx0, gy0, gx1, gy1 = x0 + 10 * S, y0 + 10 * S, x1 - 10 * S, y1 - 10 * S
bw = (gx1 - gx0 - gap * (cols - 1)) / cols
bh = (gy1 - gy0 - gap * (rows - 1)) / rows
colors = [GREEN, BROWN, BROWN, BLUE, ORANGE, BROWN, BROWN, RED, BROWN]
for i, c in enumerate(colors):
    r, k = divmod(i, cols)
    bx, by = gx0 + k * (bw + gap), gy0 + r * (bh + gap)
    d.rounded_rectangle((bx, by, bx + bw, by + bh), radius=4 * S, fill=c)
# mittlerer Button: Fortschrittsbalken (Forschung)
bx, by = gx0 + (bw + gap), gy0 + (bh + gap)
d.rounded_rectangle((bx + 4 * S, by + bh - 9 * S, bx + bw - 4 * S, by + bh - 4 * S), radius=2 * S, fill=(40, 30, 15))
d.rounded_rectangle((bx + 4 * S, by + bh - 9 * S, bx + (bw - 8 * S) * 0.65 + 4 * S, by + bh - 4 * S), radius=2 * S, fill=LIGHT)
# erster Button: Pause-Zeichen, zweiter: Graph-Linie
bx, by = gx0, gy0
d.rectangle((bx + bw * 0.34, by + bh * 0.25, bx + bw * 0.44, by + bh * 0.75), fill=LIGHT)
d.rectangle((bx + bw * 0.56, by + bh * 0.25, bx + bw * 0.66, by + bh * 0.75), fill=LIGHT)
bx = gx0 + bw + gap
line = [(bx + bw * t, by + bh * (0.75 - 0.5 * v)) for t, v in ((0.12, 0.1), (0.35, 0.5), (0.55, 0.35), (0.88, 0.9))]
d.line(line, fill=LIGHT, width=3 * S, joint="curve")

img = img.resize((144, 144), Image.LANCZOS)
out = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "thumbnail.png")
img.save(out, optimize=True)
print(out)
