"""Build every Peglord character from primitives in Blender and render HD-2D sprite frames.

Run: blender -b --python characters.py -- <out_dir> [only_name]
Each character faces +X and is turned three-quarters toward the camera.
Frames: idle (4), attack (6), hurt (3), cast (4), dead (1).
"""
import bpy, bmesh, math, os, sys
from mathutils import Vector, Euler

argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
OUT = argv[0] if argv else '/tmp/sprites'
ONLY = argv[1] if len(argv) > 1 else None
RES = 320

# ---------------------------------------------------------------- scene setup
def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.engine = 'CYCLES'
    sc.cycles.device = 'CPU'
    sc.cycles.samples = 32
    sc.cycles.use_denoising = True
    sc.render.film_transparent = True
    sc.render.resolution_x = RES
    sc.render.resolution_y = RES
    sc.render.filter_size = 0.6
    sc.render.image_settings.file_format = 'PNG'
    sc.render.image_settings.color_mode = 'RGBA'
    sc.view_settings.view_transform = 'Standard'
    sc.view_settings.look = 'Medium High Contrast'
    # Freestyle ink outline
    sc.render.use_freestyle = False
    sc.render.line_thickness_mode = 'ABSOLUTE'
    sc.render.line_thickness = 1.1
    vl = sc.view_layers[0]
    ls = vl.freestyle_settings.linesets[0] if vl.freestyle_settings.linesets else vl.freestyle_settings.linesets.new('ink')
    ls.select_by_visibility = True
    ls.select_silhouette = True; ls.select_border = True; ls.select_crease = False
    if ls.linestyle is None: ls.linestyle = bpy.data.linestyles.new('ink')
    ls.linestyle.color = (0.08, 0.05, 0.03)
    ls.linestyle.thickness = 1.2
    world = bpy.data.worlds.new('w'); sc.world = world
    world.use_nodes = True
    world.node_tree.nodes['Background'].inputs[0].default_value = (0.45, 0.4, 0.36, 1)
    world.node_tree.nodes['Background'].inputs[1].default_value = 0.6
    # Camera: orthographic, slightly above.
    cam = bpy.data.cameras.new('cam'); cam.type = 'ORTHO'; cam.ortho_scale = 4.2
    co = bpy.data.objects.new('cam', cam); sc.collection.objects.link(co); sc.camera = co
    co.location = (0, -12, 4.2); co.rotation_euler = Euler((math.radians(74), 0, 0))
    # Shift the frame so feet sit near the bottom.
    cam.shift_y = 0.18
    # Lights: warm key, cool fill, rim.
    def light(name, kind, loc, rot, energy, color, size=1.0):
        l = bpy.data.lights.new(name, kind); l.energy = energy; l.color = color
        if kind == 'AREA': l.size = size
        o = bpy.data.objects.new(name, l); o.location = loc; o.rotation_euler = Euler([math.radians(a) for a in rot]); sc.collection.objects.link(o)
    light('key', 'SUN', (0, 0, 0), (50, 0, -35), 5.0, (1.0, 0.86, 0.66))
    light('fill', 'SUN', (0, 0, 0), (60, 0, 140), 1.2, (0.6, 0.7, 1.0))
    light('rim', 'SUN', (0, 0, 0), (110, 0, 180), 2.5, (1.0, 0.75, 0.5))
    return sc

MATS = {}
def mat(name, color, metal=0.0, rough=0.55, emit=0.0):
    key = (name, color, metal, rough, emit)
    if key in MATS: return MATS[key]
    m = bpy.data.materials.new(name); m.use_nodes = True
    b = m.node_tree.nodes['Principled BSDF']
    c = tuple(int(color[i:i + 2], 16) / 255 for i in (1, 3, 5))
    b.inputs['Base Color'].default_value = (*[pow(x, 2.2) for x in c], 1)
    b.inputs['Metallic'].default_value = metal
    b.inputs['Roughness'].default_value = max(rough, 0.38) if metal > 0.5 else rough
    if emit:
        b.inputs['Emission Color'].default_value = (*[pow(x, 2.2) for x in c], 1)
        b.inputs['Emission Strength'].default_value = emit
    MATS[key] = m
    return m

# ---------------------------------------------------------------- primitives
def _finish(o, material, parent, bevel=0.0, smooth=True):
    if material: o.data.materials.append(material)
    if smooth:
        for p in o.data.polygons: p.use_smooth = True
    if bevel:
        mod = o.modifiers.new('bv', 'BEVEL'); mod.width = bevel; mod.segments = 2
    if parent: o.parent = parent
    return o

def box(name, size, loc, material, parent=None, rot=(0, 0, 0), bevel=0.04):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot)
    o = bpy.context.active_object; o.name = name; o.scale = size
    bpy.ops.object.transform_apply(scale=True)
    return _finish(o, material, parent, bevel, smooth=False)

def ball(name, r, loc, material, parent=None, scale=(1, 1, 1), seg=24):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=r, location=loc, segments=seg, ring_count=seg // 2)
    o = bpy.context.active_object; o.name = name; o.scale = scale
    bpy.ops.object.transform_apply(scale=True)
    return _finish(o, material, parent)

def cyl(name, r, depth, loc, material, parent=None, rot=(0, 0, 0), r2=None, verts=20):
    if r2 is None:
        bpy.ops.mesh.primitive_cylinder_add(radius=r, depth=depth, location=loc, rotation=rot, vertices=verts)
    else:
        bpy.ops.mesh.primitive_cone_add(radius1=r, radius2=r2, depth=depth, location=loc, rotation=rot, vertices=verts)
    o = bpy.context.active_object; o.name = name
    return _finish(o, material, parent, 0.0)

def torus(name, r, t, loc, material, parent=None, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_torus_add(major_radius=r, minor_radius=t, location=loc, rotation=rot, major_segments=28, minor_segments=10)
    o = bpy.context.active_object; o.name = name
    return _finish(o, material, parent)

def empty(name, loc, parent=None):
    o = bpy.data.objects.new(name, None); o.location = loc
    bpy.context.scene.collection.objects.link(o)
    if parent: o.parent = parent
    return o

# ---------------------------------------------------------------- weapons (built along local -Z from the hand)
def weapon(kind, hand):
    if kind == 'sword':
        cyl('grip', 0.05, 0.28, (0, 0, 0.02), mat('grip', '#5a3a1e'), hand)
        box('guard', (0.08, 0.36, 0.07), (0, 0, -0.14), mat('brass', '#c9a24a', 0.9, 0.3), hand)
        box('blade', (0.05, 0.14, 1.05), (0, 0, -0.7), mat('steel', '#dfe6ee', 1.0, 0.18), hand, bevel=0.02)
    elif kind == 'staff':
        cyl('shaft', 0.05, 1.9, (0, 0, -0.3), mat('wood', '#6b4226'), hand)
        ball('orb', 0.17, (0, 0, -1.3), mat('orb', '#cfb3ff', 0, 0.1, 6.0), hand)
    elif kind == 'mace':
        cyl('handle', 0.05, 0.9, (0, 0, -0.35), mat('wood', '#6b4226'), hand)
        ball('head', 0.2, (0, 0, -0.85), mat('iron', '#9aa0a8', 0.9, 0.35), hand)
        for i in range(6):
            a = i * math.pi / 3
            cyl('spike', 0.06, 0.18, (math.cos(a) * 0.2, math.sin(a) * 0.2, -0.85), mat('iron', '#9aa0a8', 0.9, 0.35), hand, rot=(math.pi / 2, 0, a + math.pi / 2), r2=0.0)
    elif kind == 'dagger':
        cyl('grip', 0.045, 0.2, (0, 0, 0.0), mat('grip', '#3b2414'), hand)
        box('guard', (0.06, 0.24, 0.05), (0, 0, -0.1), mat('brass', '#c9a24a', 0.9, 0.3), hand)
        box('blade', (0.04, 0.1, 0.5), (0, 0, -0.38), mat('steel', '#e8eef4', 1.0, 0.15), hand, bevel=0.015)
    elif kind == 'bow':
        wood = mat('wood', '#7a4a22')
        # a "(" arc in the hand's XZ plane, bulging forward
        R, segs = 0.75, 9
        for i in range(segs):
            a0 = -1.05 + 2.1 * i / segs; a1 = -1.05 + 2.1 * (i + 1) / segs
            p0 = (R * math.cos(a0) - R + 0.25, 0, R * math.sin(a0)); p1 = (R * math.cos(a1) - R + 0.25, 0, R * math.sin(a1))
            mid = tuple((p0[k] + p1[k]) / 2 for k in range(3))
            ang = math.atan2(p1[0] - p0[0], p1[2] - p0[2])
            cyl('bowseg', 0.045, 2.1 * R / segs + 0.03, mid, wood, hand, rot=(0, ang, 0))
        ztop = R * math.sin(1.05)
        cyl('string', 0.012, 2 * ztop, (R * math.cos(1.05) - R + 0.25, 0, 0), mat('string', '#eeeeee'), hand)
    elif kind == 'tankard':
        cyl('mug', 0.2, 0.36, (0, 0.05, -0.15), mat('pewter', '#c98a2a', 0.6, 0.4), hand)
        cyl('foam', 0.21, 0.1, (0, 0.05, 0.05), mat('foam', '#fff8e0', 0, 0.9), hand)
    elif kind == 'cane':
        cyl('cane', 0.04, 1.5, (0, 0, -0.65), mat('ebony', '#1a120c', 0.2, 0.3), hand)
        ball('knob', 0.09, (0, 0, 0.1), mat('gold', '#d4a94e', 1.0, 0.25), hand)
    elif kind == 'bottle':
        cyl('bottle', 0.12, 0.42, (0, 0, -0.2), mat('glassg', '#3d7a3a', 0.0, 0.15), hand)
        cyl('neck', 0.05, 0.2, (0, 0, 0.05), mat('glassg', '#3d7a3a', 0.0, 0.15), hand)
    elif kind == 'skull':
        cyl('stick', 0.045, 1.7, (0, 0, -0.25), mat('wood', '#5a4632'), hand)
        ball('skull', 0.17, (0, 0, -1.15), mat('bone', '#ece4cf', 0, 0.6), hand)
        ball('glow', 0.06, (0.12, -0.05, -1.15), mat('eye', '#7dff9a', 0, 0.2, 8.0), hand)
    elif kind == 'shield':
        box('shield', (0.1, 0.62, 0.78), (0.12, 0, -0.1), mat('shieldred', '#8a2a2a', 0.1, 0.5), hand, bevel=0.06)
        box('boss', (0.12, 0.36, 0.5), (0.17, 0, -0.1), mat('brass', '#c9a24a', 0.9, 0.3), hand, bevel=0.05)
    elif kind == 'tower':
        box('tower', (0.12, 0.85, 1.3), (0.18, 0, 0.1), mat('planks', '#7a4a33', 0, 0.8), hand, bevel=0.04)
        for z in (-0.3, 0.1, 0.5):
            box('band', (0.14, 0.88, 0.07), (0.2, 0, z), mat('iron', '#5a5a62', 0.8, 0.4), hand, bevel=0.01)
    elif kind == 'bomb':
        ball('bomb', 0.28, (0.05, 0, -0.2), mat('bombm', '#2b2b2b', 0.4, 0.4), hand)
        cyl('fuse', 0.03, 0.2, (0.05, 0, 0.1), mat('rope', '#c9a24a'), hand)
        ball('spark', 0.06, (0.05, 0, 0.22), mat('spark', '#ffcf3f', 0, 0.2, 12.0), hand)

# ---------------------------------------------------------------- humanoid builder
def humanoid(spec):
    """Returns (root, rig) where rig holds pivots to animate."""
    root = empty('root', (0, 0, 0))
    body = empty('body', (0, 0, 0), root)
    s = spec.get('bulk', 1.0)
    skin = mat('skin' + spec['skin'], spec['skin'], 0, 0.5)
    top = mat('top' + spec['body'], spec['body'], spec.get('bodymetal', 0.0), spec.get('bodyrough', 0.55))
    leg = mat('leg' + spec['legs'], spec['legs'], spec.get('legmetal', 0.0), 0.6)
    boot = mat('boot', '#2a1a10', 0, 0.7)
    # legs
    for side, y in (('L', 0.17), ('R', -0.17)):
        cyl('leg' + side, 0.13 * s, 0.62, (0, y * s, 0.35), leg, body)
        box('foot' + side, (0.34, 0.2 * s, 0.14), (0.07, y * s, 0.07), boot, body)
    # torso and robe
    if spec.get('robe'):
        cyl('robe', 0.46 * s, 0.9, (0, 0, 0.62), top, body, r2=0.3 * s, verts=24)
    torso = box('torso', (0.52 * s, 0.68 * s, 0.72), (0, 0, 1.0), top, body, bevel=0.14)
    if spec.get('belt'):
        box('belt', (0.55 * s, 0.71 * s, 0.1), (0, 0, 0.72), mat('belt' + spec['belt'], spec['belt'], 0.3, 0.5), body, bevel=0.03)
    head = empty('head', (0.04, 0, 1.62), body)
    ball('skull', 0.42, (0, 0, 0), skin, head, scale=(1, 0.95, 0.95))
    if not spec.get('noface'):
        eye = mat('eye', '#1a120c', 0, 0.3)
        for y in (0.13, -0.13):
            ball('eye', 0.055, (0.38, y, 0.02), eye, head)
        ball('nose', 0.06, (0.42, 0, -0.08), skin, head)
    # arms on shoulder pivots
    sleeve = mat('sleeve' + spec.get('sleeve', spec['body']), spec.get('sleeve', spec['body']), spec.get('bodymetal', 0.0) * 0.8, 0.55)
    rig = {'root': root, 'body': body, 'head': head}
    for side, y in (('front', -0.42), ('back', 0.42)):
        sh = empty('shoulder_' + side, (0.02, y * s, 1.22), body)
        cyl('arm', 0.1 * s, 0.5, (0, 0, -0.25), sleeve, sh)
        hand = empty('hand_' + side, (0, 0, -0.55), sh)
        ball('hand', 0.12 * s, (0, 0, 0), skin, hand)
        rig[side] = sh; rig['hand_' + side] = hand
    if spec.get('weapon'):
        weapon(spec['weapon'], rig['hand_front'])
    if spec.get('off'):
        weapon(spec['off'], rig['hand_back'])
    if spec.get('extra'):
        spec['extra'](rig, head, body, s)
    rig['idle_arm'] = spec.get('idle_arm', 25)
    rig['wkind'] = spec.get('weapon')
    return root, rig

# ---------------------------------------------------------------- characters
def knight_extra(rig, head, body, s):
    steel = mat('steel2', '#aab5c2', 0.9, 0.3)
    ball('helm', 0.46, (0, 0, 0.06), steel, head, scale=(1.02, 1, 1))
    box('visor', (0.06, 0.62, 0.08), (0.44, 0, 0.0), mat('dark', '#1d2228', 0.5, 0.5), head, bevel=0.02)
    cyl('plume', 0.12, 0.5, (-0.05, 0, 0.6), mat('plume', '#c0392b', 0, 0.7), head, rot=(0, -0.4, 0), r2=0.02)
    for y in (0.4, -0.4):
        ball('pauldron', 0.2, (0, y * s, 1.3), steel, body, scale=(1, 1, 0.7))

def mage_extra(rig, head, body, s):
    hat = mat('hat', '#4a2d75', 0, 0.6)
    torus('brim', 0.5, 0.06, (0, 0, 0.3), hat, head)
    cyl('cone', 0.42, 0.95, (-0.08, 0, 0.75), hat, head, rot=(0, -0.3, 0), r2=0.03)
    ball('star', 0.07, (-0.32, 0, 1.18), mat('starm', '#ffd23f', 0, 0.3, 4.0), head)
    ball('beard', 0.3, (0.3, 0, -0.32), mat('beard', '#e8e2d0', 0, 0.9), head, scale=(0.8, 1, 1.3))

def priest_extra(rig, head, body, s):
    ball('tonsure', 0.43, (-0.04, 0, 0.0), mat('hairbrown', '#7a5130', 0, 0.8), head, scale=(1, 1, 0.75))
    ball('cheeks', 0.07, (0.36, 0.18, -0.12), mat('blush', '#e8907a', 0, 0.6), head)
    ball('cheeks2', 0.07, (0.36, -0.18, -0.12), mat('blush', '#e8907a', 0, 0.6), head)
    box('stole', (0.56, 0.18, 0.75), (0.02, 0, 1.0), mat('stole', '#e8d9a8', 0, 0.6), body, bevel=0.03)

def rogue_extra(rig, head, body, s):
    hood = mat('hood', '#2f4a22', 0, 0.8)
    ball('hood', 0.5, (-0.16, 0, 0.08), hood, head, scale=(1, 1.02, 1.05))
    box('mask', (0.1, 0.55, 0.16), (0.4, 0, -0.14), mat('maskm', '#1a2a12', 0, 0.7), head, bevel=0.04)

def ranger_extra(rig, head, body, s):
    cap = mat('cap', '#2a5555', 0, 0.7)
    ball('cap', 0.45, (-0.02, 0, 0.12), cap, head, scale=(1.05, 1, 0.7))
    cyl('feather', 0.06, 0.6, (-0.3, 0.25, 0.4), mat('feather', '#c0392b', 0, 0.6), head, rot=(0.3, -0.9, 0), r2=0.01)
    cyl('quiver', 0.13, 0.8, (-0.36, 0, 1.15), mat('leather', '#7a4a22', 0, 0.7), body, rot=(0, 0.4, 0))

def brute_extra(rig, head, body, s):
    box('brow', (0.1, 0.5, 0.08), (0.36, 0, 0.14), mat('skinbrute', '#c48468', 0, 0.5), head, bevel=0.03)
    ball('chain', 0.08, (0.3, 0.2, -0.55), mat('brass', '#c9a24a', 0.9, 0.3), head)

def sneak_extra(rig, head, body, s):
    hood = mat('blackhood', '#18181e', 0, 0.8)
    ball('hood', 0.5, (-0.14, 0, 0.06), hood, head, scale=(1.0, 1.02, 1.1))
    for y in (0.13, -0.13):
        ball('reye', 0.06, (0.42, y, 0.0), mat('redeye', '#ff4a3a', 0, 0.2, 10.0), head)

def bomber_extra(rig, head, body, s):
    box('goggles', (0.12, 0.7, 0.16), (0.38, 0, 0.08), mat('goggle', '#88c0ff', 0.6, 0.1), head, bevel=0.05)
    ball('cap', 0.44, (-0.03, 0, 0.12), mat('beanie', '#4a4a4a', 0, 0.9), head, scale=(1, 1, 0.7))

def shaman_extra(rig, head, body, s):
    cols = ['#e74c3c', '#f1c40f', '#3498db', '#f1c40f', '#e74c3c']
    for i, c in enumerate(cols):
        a = (i - 2) * 0.35
        cyl('feather', 0.07, 0.7, (-0.1 + math.sin(a) * -0.1, math.sin(a) * 0.4, 0.55), mat('f' + c, c, 0, 0.6), head, rot=(a, -0.25, 0), r2=0.01)
    ball('mask', 0.2, (0.36, 0, 0.05), mat('bone', '#ece4cf', 0, 0.6), head, scale=(0.5, 1.4, 1.2))

def bulwark_extra(rig, head, body, s):
    iron = mat('ironhelm', '#7a7a84', 0.8, 0.4)
    box('helm', (0.86, 0.86, 0.75), (0, 0, 0.1), iron, head, bevel=0.12)
    box('slit', (0.06, 0.6, 0.06), (0.43, 0, 0.05), mat('dark', '#1d2228', 0.5, 0.5), head, bevel=0.01)

def drunk_extra(rig, head, body, s):
    ball('nose', 0.12, (0.44, 0, -0.08), mat('rednose', '#e85a4a', 0, 0.4), head)
    box('hat', (0.5, 0.55, 0.12), (-0.05, 0, 0.42), mat('flatcap', '#6b4226', 0, 0.8), head, rot=(0, -0.2, 0), bevel=0.05)

def landlord_extra(rig, head, body, s):
    silk = mat('silk', '#151520', 0.2, 0.3)
    cyl('crown', 0.32, 0.75, (0, 0, 0.72), silk, head)
    cyl('brim', 0.55, 0.06, (0, 0, 0.36), silk, head)
    cyl('band', 0.33, 0.12, (0, 0, 0.42), mat('ribbon', '#8a1a1a', 0, 0.5), head)
    torus('monocle', 0.11, 0.02, (0.42, -0.14, 0.04), mat('gold', '#d4a94e', 1.0, 0.25), head, rot=(0, math.pi / 2, 0))
    box('moustache', (0.08, 0.5, 0.08), (0.42, 0, -0.16), mat('stache', '#d8d8d8', 0, 0.8), head, bevel=0.03)
    box('shirt', (0.54, 0.25, 0.6), (0.03, 0, 1.02), mat('shirt', '#f2ead3', 0, 0.6), body, bevel=0.03)
    box('tie', (0.56, 0.08, 0.3), (0.04, 0, 1.12), mat('ribbon', '#8a1a1a', 0, 0.5), body, bevel=0.01)

HUMANS = {
    'knight':  dict(skin='#f0c8a0', body='#9aa7b4', bodymetal=0.85, bodyrough=0.3, legs='#6c7682', legmetal=0.6, sleeve='#7d8894', belt='#5a3a1e', weapon='sword', off='shield', extra=knight_extra),
    'mage':    dict(skin='#e9c49c', body='#5b3a8c', legs='#3e2766', sleeve='#6b47a3', belt='#c9a24a', robe=True, weapon='staff', extra=mage_extra, idle_arm=55),
    'priest':  dict(skin='#f2c9a5', body='#8a5a33', legs='#6b4226', sleeve='#9b6a3f', belt='#e8d9a8', robe=True, bulk=1.15, weapon='mace', off='tankard', extra=priest_extra),
    'rogue':   dict(skin='#e4b88f', body='#3d5a2e', legs='#2c3a22', sleeve='#4a6b37', belt='#5a3a1e', weapon='dagger', extra=rogue_extra),
    'ranger':  dict(skin='#e7bd93', body='#2e6b6b', legs='#4a3a22', sleeve='#3a7f7f', belt='#7a4a22', weapon='bow', extra=ranger_extra, idle_arm=70),
    'brute':   dict(skin='#d99a7a', body='#e8e2d0', legs='#3b4a6b', sleeve='#d99a7a', bulk=1.35, belt='#2a1a10', extra=brute_extra),
    'sneak':   dict(skin='#2b2b33', body='#1f1f26', legs='#151519', sleeve='#26262e', weapon='dagger', noface=True, extra=sneak_extra),
    'bomber':  dict(skin='#e0b090', body='#7a3a2a', legs='#4a2a1a', sleeve='#8a4a3a', bulk=1.35, belt='#c9a24a', off='bomb', extra=bomber_extra),
    'shaman':  dict(skin='#9fbf7a', body='#6b4a2a', legs='#4a3a22', sleeve='#7a5a3a', robe=True, weapon='skull', extra=shaman_extra, idle_arm=50),
    'bulwark': dict(skin='#d0a888', body='#6c6c74', bodymetal=0.7, legs='#4a4a52', sleeve='#5a5a62', bulk=1.3, off='tower', extra=bulwark_extra),
    'drunk':   dict(skin='#e8b090', body='#a85a3a', legs='#4a3a5a', sleeve='#b86a4a', belt='#2a1a10', weapon='bottle', extra=drunk_extra),
    'landlord': dict(skin='#e8c8a8', body='#2a2a3a', legs='#1e1e2a', sleeve='#33334a', belt='#c9a24a', bulk=1.2, weapon='cane', extra=landlord_extra, idle_arm=35),
}

# ---------------------------------------------------------------- creatures
def hound():
    root = empty('root', (0, 0, 0)); body = empty('body', (0, 0, 0), root)
    fur = mat('fur', '#6b4226', 0, 0.85); dark = mat('furdark', '#4a2e1a', 0, 0.85)
    ball('torso', 0.5, (0, 0, 0.75), fur, body, scale=(1.5, 0.75, 0.75))
    head = empty('head', (0.75, 0, 1.05), body)
    ball('skull', 0.33, (0, 0, 0), fur, head)
    box('snout', (0.4, 0.3, 0.24), (0.3, 0, -0.08), dark, head, bevel=0.08)
    ball('nose', 0.07, (0.5, 0, -0.02), mat('nose', '#111111', 0, 0.3), head)
    for y in (0.15, -0.15):
        ball('eye', 0.05, (0.24, y, 0.1), mat('yeye', '#ffcf3f', 0, 0.2, 5.0), head)
        cyl('ear', 0.1, 0.3, (-0.05, y, 0.3), dark, head, r2=0.01)
    box('collar', (0.18, 0.5, 0.5), (0.5, 0, 0.95), mat('collar', '#c0392b', 0, 0.5), body, bevel=0.05)
    legs = []
    for x in (0.45, -0.45):
        for y in (0.2, -0.2):
            piv = empty('legpiv', (x, y, 0.6), body)
            cyl('leg', 0.09, 0.6, (0, 0, -0.3), dark, piv)
            legs.append(piv)
    tail = empty('tail', (-0.7, 0, 0.9), body)
    cyl('tailm', 0.07, 0.5, (-0.15, 0, 0.18), fur, tail, rot=(0, -0.8, 0), r2=0.02)
    return root, {'root': root, 'body': body, 'head': head, 'legs': legs, 'tail': tail, 'creature': 'hound'}

def leech():
    """A round, front-facing bat with scalloped wings."""
    root = empty('root', (0, 0, 0)); body = empty('body', (0, 0, 1.5), root)
    skin = mat('batskin', '#6a4270', 0, 0.75); wing = mat('wing', '#3b2140', 0, 0.85)
    ball('torso', 0.44, (0, 0, 0), skin, body, scale=(0.9, 1.0, 1.0))
    ball('belly', 0.3, (0.18, 0, -0.08), mat('belly', '#9a6a8a', 0, 0.8), body, scale=(0.6, 1, 1.05))
    for y in (0.17, -0.17):
        ball('eye', 0.085, (0.36, y, 0.12), mat('yeye', '#ffcf3f', 0, 0.2, 6.0), body)
        cyl('ear', 0.14, 0.42, (0.0, y * 1.4, 0.5), skin, body, rot=(-0.35 if y > 0 else 0.35, 0, 0), r2=0.0)
    for y in (0.07, -0.07):
        cyl('fang', 0.035, 0.1, (0.4, y, -0.16), mat('bone', '#ece4cf', 0, 0.6), body, rot=(0, math.pi, 0), r2=0.0)
    wings = []
    for side in (1, -1):
        piv = empty('wingpiv', (0, 0.32 * side, 0.08), body)
        pts = [(0, 0, 0.15), (0, 0.55, 0.5), (0, 1.25, 0.55), (0, 1.35, 0.05), (0, 1.05, -0.25), (0, 0.85, -0.05),
               (0, 0.6, -0.32), (0, 0.4, -0.08), (0, 0.15, -0.28), (0, 0, -0.1)]
        bm = bmesh.new()
        vs = [bm.verts.new((x, y * side, z)) for x, y, z in pts]
        bm.faces.new(vs if side > 0 else list(reversed(vs)))
        me = bpy.data.meshes.new('wing'); bm.to_mesh(me); bm.free()
        o = bpy.data.objects.new('wing', me); bpy.context.scene.collection.objects.link(o)
        o.data.materials.append(wing); o.parent = piv
        sol = o.modifiers.new('sol', 'SOLIDIFY'); sol.thickness = 0.05
        wings.append((piv, side))
    return root, {'root': root, 'body': body, 'head': body, 'wings': wings, 'creature': 'leech', 'turn': -72}

CREATURES = {'hound': hound, 'leech': leech}

# ---------------------------------------------------------------- animation poses
def pose(rig, anim, f, n):
    """Set the rig for frame f of n in the given animation."""
    t = f / max(1, n)
    root, body, head = rig['root'], rig['body'], rig['head']
    root.location = (0, 0, 0); root.rotation_euler = (0, 0, 0)
    body.rotation_euler = (0, 0, 0)
    base_z = body.location.z if rig.get('creature') != 'leech' else 1.2
    body.location = (0, 0, 0) if rig.get('creature') != 'leech' else (0, 0, 1.2)
    head.rotation_euler = (0, 0, 0)
    c = rig.get('creature')
    if c == 'hound':
        for i, leg in enumerate(rig['legs']):
            ph = i * math.pi / 2
            sw = {'idle': 0.08, 'attack': 0.6, 'hurt': 0.2, 'cast': 0.1, 'dead': 0}[anim]
            leg.rotation_euler = (0, math.sin(t * 2 * math.pi + ph) * sw, 0)
        rig['tail'].rotation_euler = (math.sin(t * 2 * math.pi) * 0.4, 0, 0)
        if anim == 'attack': body.rotation_euler = (0, -0.25 * math.sin(t * math.pi), 0); body.location = (0.4 * math.sin(t * math.pi), 0, 0.15 * math.sin(t * math.pi))
        if anim == 'hurt': body.rotation_euler = (0, 0.25, 0); body.location = (-0.2, 0, 0)
        if anim == 'idle': body.location = (0, 0, 0.03 * math.sin(t * 2 * math.pi))
        if anim == 'dead': root.rotation_euler = (math.pi / 2, 0, 0); root.location = (0, 0.0, 0.3)
        return
    if c == 'leech':
        flap = math.sin(t * 2 * math.pi) * (0.55 if anim != 'dead' else 0)
        for piv, side in rig['wings']:
            piv.rotation_euler = (flap * side, 0, 0)
        body.location = (0, 0, 1.5 + 0.1 * math.sin(t * 2 * math.pi))
        if anim == 'attack': body.location = (0.35 * math.sin(t * math.pi), 0, 1.5 - 0.35 * math.sin(t * math.pi)); body.rotation_euler = (0, 0.5 * math.sin(t * math.pi), 0)
        if anim == 'hurt': body.rotation_euler = (0.3, -0.3, 0); body.location = (-0.15, 0, 1.6)
        if anim == 'dead':
            body.location = (0, 0, 0.4); body.rotation_euler = (0, 0, 0)
            for piv, side in rig['wings']: piv.rotation_euler = (-0.9 * side, 0, 0)
        return
    front, back = rig['front'], rig['back']
    idle = math.radians(rig['idle_arm'])
    front.rotation_euler = (0, -idle, 0); back.rotation_euler = (0, -0.25, 0)
    if anim == 'idle':
        body.location = (0, 0, 0.035 * math.sin(t * 2 * math.pi))
        head.rotation_euler = (0, 0.04 * math.sin(t * 2 * math.pi), 0)
        front.rotation_euler = (0, -idle - 0.06 * math.sin(t * 2 * math.pi), 0)
    elif anim == 'attack':
        # wind up (raise arm back over head), then slash down and forward
        keys = [(-idle, 0.0), (-2.9, -0.12), (-3.1, -0.15), (-0.4, 0.22), (-0.1, 0.26), (-idle, 0.05)]
        a, lean = keys[f]
        front.rotation_euler = (0, a, 0)
        body.rotation_euler = (0, lean, 0)
        body.location = (0.25 * math.sin(t * math.pi), 0, 0)
    elif anim == 'cast':
        front.rotation_euler = (0, -1.9 - 0.1 * math.sin(t * 2 * math.pi), 0)
        back.rotation_euler = (0, -1.2, 0)
        body.rotation_euler = (0, -0.08, 0)
        head.rotation_euler = (0, -0.15, 0)
    elif anim == 'hurt':
        k = [1.0, 0.7, 0.35][f]
        body.rotation_euler = (0, -0.35 * k, 0)
        body.location = (-0.25 * k, 0, 0)
        head.rotation_euler = (0, -0.3 * k, 0)
        front.rotation_euler = (0, -idle + 0.6 * k, 0); back.rotation_euler = (0, 0.5 * k, 0)
    elif anim == 'dead':
        root.rotation_euler = (0, -math.pi / 2, 0); root.location = (0.75, 0, 0.35)
    aim_weapon(rig, anim, f, n)

REST = {'sword': -2.55, 'staff': -3.05, 'mace': -2.35, 'dagger': -1.75, 'bow': 0.0,
        'cane': -0.12, 'bottle': -0.3, 'skull': -3.05, None: 0.0}

def aim_weapon(rig, anim, f, n):
    k = rig.get('wkind')
    th = rig['front'].rotation_euler[1]
    rest = REST.get(k, 0.0)
    a = rest
    if anim == 'attack' and k not in ('bow', None):
        a = [rest, -3.7, -3.9, -1.35, -0.95, rest][f]
    elif anim == 'attack' and k == 'bow':
        a = -1.57
    elif anim == 'cast' and k in ('staff', 'skull', 'sword', 'mace', 'cane'):
        a = -3.0
    elif anim == 'hurt':
        a = rest + 0.35 * [1.0, 0.7, 0.35][f]
    if k == 'bow':
        rig['hand_front'].rotation_euler = (0, -th, 0)
        return
    rig['hand_front'].rotation_euler = (0, a - th, 0)

ANIMS = [('idle', 4), ('attack', 6), ('hurt', 3), ('cast', 4), ('dead', 1)]

def render_char(name):
    sc = reset()
    MATS.clear()
    if name in HUMANS:
        root, rig = humanoid(HUMANS[name])
    else:
        root, rig = CREATURES[name]()
    big = name == 'landlord'
    root.rotation_euler = (0, 0, 0)
    turn = empty('turn', (0, 0, 0)); root.parent = turn
    turn.rotation_euler = (0, 0, math.radians(rig.get('turn', -24)))
    if big: turn.scale = (1.0, 1.0, 1.0)
    os.makedirs(os.path.join(OUT, name), exist_ok=True)
    for anim, n in ANIMS:
        for f in range(n):
            pose(rig, anim, f, n)
            bpy.context.view_layer.update()
            sc.render.filepath = os.path.join(OUT, name, f'{anim}_{f}.png')
            bpy.ops.render.render(write_still=True)
    print('RENDERED', name)

names = list(HUMANS.keys()) + list(CREATURES.keys())
for n in names:
    if ONLY and n not in ONLY.split(','):
        continue
    render_char(n)
