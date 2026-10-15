"""Generate the pub's pixel-art textures (HD-2D style: low-res, hand-tuned palettes, nearest filtering).

Run: python3 tools/textures.py assets/textures
"""
import os, sys, random, math
from PIL import Image

OUT = sys.argv[1] if len(sys.argv) > 1 else 'assets/textures'
os.makedirs(OUT, exist_ok=True)
R = random.Random(7)

def hexc(h):
    h = h.lstrip('#'); return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))

def ramp(*cols):
    return [hexc(c) for c in cols]

def save(im, name):
    im.save(os.path.join(OUT, name)); print('wrote', name, im.size)

def noise2(w, h, scale, seed):
    rr = random.Random(seed)
    gw, gh = w // scale + 2, h // scale + 2
    g = [[rr.random() for _ in range(gw)] for _ in range(gh)]
    def at(x, y):
        fx, fy = x / scale, y / scale
        x0, y0 = int(fx), int(fy); tx, ty = fx - x0, fy - y0
        tx = tx * tx * (3 - 2 * tx); ty = ty * ty * (3 - 2 * ty)
        a = g[y0 % gh][x0 % gw] * (1 - tx) + g[y0 % gh][(x0 + 1) % gw] * tx
        b = g[(y0 + 1) % gh][x0 % gw] * (1 - tx) + g[(y0 + 1) % gh][(x0 + 1) % gw] * tx
        return a * (1 - ty) + b * ty
    return at

def planks(name, w, h, ph, pal, vertical=False, seed=1, nails=True):
    im = Image.new('RGB', (w, h)); px = im.load()
    rr = random.Random(seed)
    n = noise2(w, h, 6, seed)
    rows = h // ph
    for r in range(rows):
        cut = rr.randrange(8, w - 8); shade = rr.choice([0, 0, 1, -1])
        for y in range(r * ph, (r + 1) * ph):
            for x in range(w):
                yy = y - r * ph
                v = 2 + shade
                grain = math.sin((x + (cut if x > cut else 0)) * 0.35 + yy * 1.7 + rr.random() * 0.2)
                v += 1 if grain > 0.75 else 0
                v -= 1 if n(x, y) < 0.3 else 0
                if yy == 0: v = 0
                elif yy == ph - 1: v = 1
                if x == cut: v = 0
                if nails and (x == cut + 2 or x == cut - 3) and yy == ph // 2: v = 0
                px[x, y] = pal[max(0, min(len(pal) - 1, v))]
    if vertical: im = im.transpose(Image.Transpose.ROTATE_90)
    save(im, name)

def bricks(name, w, h, bw, bh, pal, mortar, seed=2):
    im = Image.new('RGB', (w, h)); px = im.load(); rr = random.Random(seed)
    n = noise2(w, h, 5, seed)
    tones = {}
    for y in range(h):
        row = y // bh; off = (bw // 2) if row % 2 else 0
        for x in range(w):
            col = ((x + off) // bw)
            key = (row, col % (w // bw))
            if key not in tones: tones[key] = rr.choice([1, 2, 2, 3])
            yy, xx = y % bh, (x + off) % bw
            if yy == bh - 1 or xx == bw - 1:
                px[x, y] = mortar[0 if n(x, y) < 0.5 else 1]; continue
            v = tones[key]
            if yy == 0: v += 1
            if xx == 0: v += 1 if v < 3 else 0
            if n(x, y) < 0.28: v -= 1
            if rr.random() < 0.04: v -= 1
            px[x, y] = pal[max(0, min(len(pal) - 1, v))]
    save(im, name)

def plaster(name, w, h, pal, seed=3):
    im = Image.new('RGB', (w, h)); px = im.load()
    n = noise2(w, h, 8, seed); n2 = noise2(w, h, 3, seed + 1)
    for y in range(h):
        for x in range(w):
            v = n(x, y) * 0.7 + n2(x, y) * 0.3
            i = 3 if v > 0.62 else 2 if v > 0.42 else 1 if v > 0.25 else 0
            px[x, y] = pal[i]
    # a couple of cracks
    rr = random.Random(seed)
    for _ in range(2):
        x, y = rr.randrange(w), rr.randrange(h)
        for _ in range(12):
            px[x % w, y % h] = pal[0]; x += rr.choice([-1, 0, 1]); y += 1
    save(im, name)

def felt(name, w, h, pal, seed=4):
    im = Image.new('RGB', (w, h)); px = im.load()
    n = noise2(w, h, 4, seed); rr = random.Random(seed)
    for y in range(h):
        for x in range(w):
            v = n(x, y) + rr.random() * 0.25
            px[x, y] = pal[2 if v > 0.75 else 1 if v > 0.35 else 0]
    save(im, name)

def stones(name, w, h, pal, mortar, seed=5):
    im = Image.new('RGB', (w, h), mortar); px = im.load(); rr = random.Random(seed)
    pts = [(rr.randrange(w), rr.randrange(h), rr.choice([1, 2, 2, 3])) for _ in range(22)]
    for y in range(h):
        for x in range(w):
            best, second, tone = 1e9, 1e9, 0
            for (sx, sy, t) in pts:
                for ox in (-w, 0, w):
                    for oy in (-h, 0, h):
                        d = (x - sx - ox) ** 2 * 0.7 + (y - sy - oy) ** 2
                        if d < best: second = best; best = d; tone = t
                        elif d < second: second = d
            if math.sqrt(second) - math.sqrt(best) < 1.3: continue
            v = tone + (1 if rr.random() < 0.08 else 0) - (1 if rr.random() < 0.1 else 0)
            px[x, y] = pal[max(0, min(len(pal) - 1, v))]
    save(im, name)

def wallpaper(name, pal, seed=6):
    w = h = 32
    im = Image.new('RGB', (w, h), pal[0]); px = im.load()
    for y in range(h):
        for x in range(w):
            # damask diamond motif
            cx, cy = (x % 16) - 8, (y % 16) - 8
            if abs(cx) + abs(cy) in (6,) or (abs(cx) < 2 and abs(cy) < 2): px[x, y] = pal[1]
            if (x % 16 == 0 or x % 16 == 8) and y % 4 == 0 and abs(cx) + abs(cy) > 8: px[x, y] = pal[1]
            if x % 16 == 15: px[x, y] = pal[2]
    save(im, name)

def rug(name, pal, seed=7):
    w, h = 96, 48
    im = Image.new('RGB', (w, h), pal[0]); px = im.load(); rr = random.Random(seed)
    for y in range(h):
        for x in range(w):
            ex = min(x, w - 1 - x); ey = min(y, h - 1 - y); e = min(ex, ey)
            c = pal[0]
            if e < 2: c = pal[3]
            elif e < 4: c = pal[2]
            elif e == 5: c = pal[1]
            else:
                cx, cy = x - w / 2, y - h / 2
                d = abs(cx) / 2.2 + abs(cy)
                if int(d) % 7 == 0: c = pal[2]
                elif int(d) % 7 == 3: c = pal[1]
                if (x // 6 + y // 6) % 2 == 0 and e < 9 and e > 6: c = pal[1]
            if rr.random() < 0.05: c = tuple(max(0, v - 18) for v in c)
            px[x, y] = c
    save(im, name)

def window(name):
    w, h = 32, 44
    im = Image.new('RGBA', (w, h), (0, 0, 0, 0)); px = im.load()
    frame = hexc('3a2414'); frame2 = hexc('5a3a20')
    sky = ramp('0d1630', '16224a', '22336a', '30477f')
    for y in range(h):
        for x in range(w):
            edge = x < 2 or x >= w - 2 or y < 2 or y >= h - 2
            mull = x in (15, 16) or y in (21, 22)
            if edge or mull:
                px[x, y] = (*(frame2 if (x + y) % 5 else frame), 255)
            else:
                t = y / h
                i = 3 if t > 0.8 else 2 if t > 0.55 else 1 if t > 0.3 else 0
                c = sky[i]
                # moon
                if (x - 9) ** 2 + (y - 9) ** 2 < 14: c = hexc('f6eec8')
                if R.random() < 0.012 and y < 20: c = hexc('ffffff')
                # rooftops silhouette
                if y > 34 - (3 if (x // 5) % 2 else 0): c = hexc('0a0c18')
                px[x, y] = (*c, 255)
    save(im, name)

def dartboard(name):
    w = h = 32
    im = Image.new('RGBA', (w, h), (0, 0, 0, 0)); px = im.load()
    for y in range(h):
        for x in range(w):
            dx, dy = x - 15.5, y - 15.5; d = math.hypot(dx, dy); a = (math.atan2(dy, dx) + math.pi) / (2 * math.pi)
            seg = int(a * 20) % 2
            if d > 15.5: continue
            if d > 13: c = hexc('1c1410')
            elif d > 12: c = hexc('c0392b') if seg else hexc('27ae60')
            elif d > 7.5: c = hexc('f2e6c4') if seg else hexc('1c1410')
            elif d > 6.5: c = hexc('c0392b') if seg else hexc('27ae60')
            elif d > 2.5: c = hexc('f2e6c4') if seg else hexc('1c1410')
            elif d > 1.4: c = hexc('27ae60')
            else: c = hexc('c0392b')
            px[x, y] = (*c, 255)
    save(im, name)

def shelf_bottles(name):
    w, h = 64, 24
    im = Image.new('RGBA', (w, h), (0, 0, 0, 0)); px = im.load(); rr = random.Random(9)
    cols = ramp('2e6b3a', '7a2a2a', '6b4a1a', '2a4a7a', '8a6a2a', '4a2a5a')
    x = 1
    while x < w - 4:
        bw = rr.choice([3, 4, 4, 5]); bh = rr.randrange(10, 20); c = rr.choice(cols)
        neck = max(2, bw // 2)
        for yy in range(h - bh, h):
            for xx in range(x, x + bw):
                top = yy < h - bh + 5
                if top and not (x + (bw - neck) // 2 <= xx < x + (bw - neck) // 2 + neck): continue
                cc = c
                if xx == x + 1 and not top: cc = tuple(min(255, v + 70) for v in c)
                if yy == h - bh: cc = hexc('c9a24a')
                px[xx, yy] = (*cc, 255)
        x += bw + rr.choice([1, 1, 2])
    save(im, name)

def flame(name):
    # 4 frames of a pixel fire, side by side (16x20 each)
    fw, fh, n = 16, 20, 4
    im = Image.new('RGBA', (fw * n, fh), (0, 0, 0, 0)); px = im.load()
    pal = ramp('ffffff', 'fff3a0', 'ffc23a', 'ff7a1a', 'c8321a')
    for f in range(n):
        rr = random.Random(30 + f)
        for y in range(fh):
            for x in range(fw):
                cx = x - fw / 2 + 0.5
                t = y / fh
                width = (fw / 2 - 1) * (t ** 0.8) * (1 + 0.15 * math.sin(f * 1.7 + y * 0.9))
                if abs(cx + math.sin(y * 0.6 + f * 1.3) * (1 - t) * 1.5) > width: continue
                core = abs(cx) / max(width, 0.1)
                hgt = t + rr.random() * 0.15
                i = 4 if core > 0.8 else 3 if core > 0.55 or hgt < 0.35 else 2 if core > 0.3 or hgt < 0.55 else 1
                if hgt > 0.85 and core < 0.25: i = 0
                px[f * fw + x, y] = (*pal[i], 255)
    save(im, name)

# ----------------------------------------------------------------- build all
planks('floor_planks.png', 64, 64, 8, ramp('3b2414', '5c3a20', '754b29', '8a5a32', '9c6a3c'), seed=11)
planks('bar_wood.png', 64, 64, 8, ramp('2a160c', '43261a', '5a3422', '6b402a', '7a4a30'), seed=12)
planks('walnut.png', 64, 64, 16, ramp('1e120b', '2e1c12', '3e271a', '4c3020', '5a3a26'), seed=13, nails=False)
planks('beam.png', 32, 32, 32, ramp('20140c', '2c1b10', '3a2516', '46301c', '533820'), vertical=True, seed=14, nails=False)
planks('barrel.png', 64, 64, 8, ramp('3a2010', '573418', '6e4420', '80522a', '905e32'), vertical=True, seed=15, nails=False)
bricks('brick.png', 64, 64, 16, 8, ramp('3e1c14', '5a2a1c', '6e3624', '804230', '8f4e3a'), ramp('2a221c', '332a22'))
plaster('plaster.png', 64, 64, ramp('a8916c', 'bba37c', 'c9b28a', 'd6c29a'))
felt('felt.png', 64, 64, ramp('17432c', '1d5236', '24603f'))
stones('stone.png', 64, 64, ramp('3a3632', '4f4a44', '635d55', '77706650'[:6]), hexc('211d1a'))
wallpaper('wallpaper.png', ramp('1d3a2c', '2a5040', '15291f'))
rug('rug.png', ramp('6e1a1a', 'c9a24a', '3a1a2a', '1e0e12'))
window('window.png')
dartboard('dartboard.png')
shelf_bottles('bottles.png')
flame('flame.png')
