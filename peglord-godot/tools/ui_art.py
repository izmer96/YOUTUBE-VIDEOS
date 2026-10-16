"""Nine-slice frames for the UI, in the Octopath style: dark lacquer panels with a fine double gold rule."""
import sys, os
from PIL import Image, ImageDraw
OUT = sys.argv[1] if len(sys.argv) > 1 else 'assets/ui'
os.makedirs(OUT, exist_ok=True)

def frame(name, size, fill_top, fill_bot, gold, gold2, alpha=236, corner=True, inner=3):
    w = h = size
    im = Image.new('RGBA', (w, h), (0, 0, 0, 0)); px = im.load()
    for y in range(h):
        t = y / (h - 1)
        c = tuple(int(fill_top[i] * (1 - t) + fill_bot[i] * t) for i in range(3))
        for x in range(w):
            if 1 <= x < w - 1 and 1 <= y < h - 1:
                px[x, y] = (*c, alpha)
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, w - 1, h - 1], outline=(*gold2, 255))
    d.rectangle([1, 1, w - 2, h - 2], outline=(*gold, 255))
    d.rectangle([inner + 1, inner + 1, w - inner - 2, h - inner - 2], outline=(*gold2, 200))
    if corner:
        for (cx, cy) in [(inner + 1, inner + 1), (w - inner - 2, inner + 1), (inner + 1, h - inner - 2), (w - inner - 2, h - inner - 2)]:
            for dx, dy in [(0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)]:
                px[cx + dx, cy + dy] = (*gold, 255)
    im.save(os.path.join(OUT, name)); print('wrote', name)

frame('panel.png', 24, (26, 22, 30), (14, 11, 14), (201, 162, 74), (92, 70, 34))
frame('panel_light.png', 24, (52, 42, 36), (30, 24, 22), (225, 190, 110), (110, 84, 40), alpha=245)
frame('card.png', 24, (40, 32, 28), (20, 16, 15), (235, 235, 235), (120, 120, 120), alpha=250)
frame('button.png', 18, (70, 52, 34), (40, 28, 20), (201, 162, 74), (92, 70, 34), alpha=255, corner=False, inner=2)
frame('button_hover.png', 18, (110, 80, 44), (62, 42, 26), (255, 214, 120), (140, 100, 44), alpha=255, corner=False, inner=2)
frame('button_press.png', 18, (36, 26, 18), (54, 38, 24), (201, 162, 74), (92, 70, 34), alpha=255, corner=False, inner=2)
frame('button_go.png', 18, (150, 46, 32), (90, 22, 16), (255, 214, 120), (120, 60, 30), alpha=255, corner=False, inner=2)
frame('button_go_hover.png', 18, (190, 66, 42), (120, 32, 22), (255, 236, 170), (150, 80, 40), alpha=255, corner=False, inner=2)
frame('slot.png', 18, (12, 10, 12), (24, 20, 22), (110, 88, 50), (50, 40, 26), alpha=255, corner=False, inner=2)
# Small diamond ornament for headers.
im = Image.new('RGBA', (9, 9), (0, 0, 0, 0)); px = im.load()
for y in range(9):
    for x in range(9):
        if abs(x - 4) + abs(y - 4) <= 4: px[x, y] = (201, 162, 74, 255)
        if abs(x - 4) + abs(y - 4) <= 2: px[x, y] = (255, 226, 150, 255)
im.save(os.path.join(OUT, 'diamond.png'))
