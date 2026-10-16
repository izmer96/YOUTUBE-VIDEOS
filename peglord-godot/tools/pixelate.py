"""Turn the supersampled Blender renders into crisp pixel-art sprite frames.

Run: python3 tools/pixelate.py <render_dir> <out_dir> [size]
Downsamples each frame (box filter), hardens alpha, adds a one-pixel dark ink outline
and quantizes each character to a shared small palette so frames don't shimmer.
"""
import os, sys
from PIL import Image, ImageFilter

SRC, DST = sys.argv[1], sys.argv[2]
SIZE = int(sys.argv[3]) if len(sys.argv) > 3 else 80
INK = (34, 22, 16)

def harden(im):
    r, g, b, a = im.split()
    a = a.point(lambda v: 255 if v >= 110 else 0)
    return Image.merge('RGBA', (r, g, b, a))

def outline(im):
    a = im.split()[3]
    grown = a.filter(ImageFilter.MaxFilter(3))
    ring = Image.eval(grown, lambda v: v)  # copy
    out = Image.new('RGBA', im.size, INK + (0,))
    ink = Image.new('RGBA', im.size, INK + (255,))
    out.paste(ink, (0, 0), grown)
    out.alpha_composite(im)
    return out

for name in sorted(os.listdir(SRC)):
    d = os.path.join(SRC, name)
    if not os.path.isdir(d):
        continue
    frames = sorted(f for f in os.listdir(d) if f.endswith('.png'))
    small = {}
    for f in frames:
        im = Image.open(os.path.join(d, f)).convert('RGBA')
        # premultiply-aware downscale
        im = im.resize((SIZE, SIZE), Image.BOX)
        small[f] = harden(im)
    # shared palette per character
    w = SIZE
    strip = Image.new('RGB', (w * len(frames), w), (0, 0, 0))
    for i, f in enumerate(frames):
        strip.paste(small[f].convert('RGB'), (i * w, 0), small[f])
    pal = strip.quantize(colors=40, method=Image.MEDIANCUT)
    os.makedirs(os.path.join(DST, name), exist_ok=True)
    for f in frames:
        im = small[f]
        q = im.convert('RGB').quantize(palette=pal, dither=Image.NONE).convert('RGB')
        q.putalpha(im.split()[3])
        outline(q).save(os.path.join(DST, name, f))
    print('pixelated', name, len(frames))
