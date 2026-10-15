extends Node3D
## The tavern diorama: floor, walls, bar, fireplace, lamps and props, all pixel-textured.

var flicker_lights: Array[OmniLight3D] = []
var flames: Array[MeshInstance3D] = []
var t := 0.0

func _ready() -> void:
	_room()
	_bar()
	_fireplace()
	_lamps()
	_props()

func _room() -> void:
	var floor_m := Kit.pmat("floor_planks", Vector2(8, 6), Color(0.62, 0.55, 0.52))
	Kit.box(self, Vector3(18, 0.2, 12), Vector3(1, -0.1, 0.5), floor_m)
	# Back wall: wood wainscot, plaster above, timber beams.
	var wain := Kit.pmat("bar_wood", Vector2(9, 1), Color(0.7, 0.65, 0.62))
	Kit.box(self, Vector3(18, 1.3, 0.2), Vector3(1, 0.65, -4.6), wain)
	Kit.box(self, Vector3(18, 0.12, 0.3), Vector3(1, 1.33, -4.5), Kit.pmat("beam", Vector2(18, 1)))
	Kit.box(self, Vector3(18, 4.2, 0.2), Vector3(1, 3.4, -4.7), Kit.pmat("plaster", Vector2(9, 2.2), Color(0.55, 0.48, 0.42)))
	for x in [-5.5, -2.7, 0.1, 2.9, 5.7, 8.5]:
		Kit.box(self, Vector3(0.28, 5.6, 0.25), Vector3(x, 2.8, -4.5), Kit.pmat("beam", Vector2(1, 6)))
	Kit.box(self, Vector3(18, 0.35, 0.4), Vector3(1, 5.3, -4.45), Kit.pmat("beam", Vector2(18, 1)))
	# Left wall with green wallpaper.
	Kit.box(self, Vector3(0.2, 5.6, 12), Vector3(-7.0, 2.8, 0.5), Kit.pmat("wallpaper", Vector2(14, 6), Color(0.7, 0.75, 0.8)))
	Kit.box(self, Vector3(0.25, 1.3, 12), Vector3(-6.9, 0.65, 0.5), wain)
	# Ceiling beams (seen from the low camera they frame the top of the shot).
	for z in [-3.0, -0.5, 2.0]:
		Kit.box(self, Vector3(18, 0.35, 0.35), Vector3(1, 5.4, z), Kit.pmat("beam", Vector2(18, 1)))
	Kit.box(self, Vector3(18, 0.1, 12), Vector3(1, 5.65, 0.5), Kit.cmat(Color(0.12, 0.08, 0.06)))
	# Windows with moonlight.
	for x in [-4.2, 1.5]:
		var w := Kit.quad(self, Vector2(1.1, 1.5), Vector3(x, 2.9, -4.58), Kit.sprite_mat("window", 0.25))
		w.name = "Window"
		var moon := SpotLight3D.new()
		moon.light_color = Color(0.55, 0.65, 1.0)
		moon.light_energy = 2.6
		moon.spot_range = 9.0
		moon.spot_angle = 32
		moon.position = Vector3(x, 3.2, -4.2)
		moon.rotation_degrees = Vector3(-38, 0, 0)
		add_child(moon)
	# Rug under the fight.
	var rug := Kit.box(self, Vector3(4.8, 0.02, 2.6), Vector3(2.75, 0.01, -1.35), Kit.pmat("rug", Vector2.ONE, Color(0.62, 0.55, 0.6)), Vector3.ZERO, false)
	rug.name = "Rug"
	# Dartboard and the rent notice.
	Kit.quad(self, Vector2(0.62, 0.62), Vector3(-1.2, 2.7, -4.55), Kit.sprite_mat("dartboard"))
	var notice := Kit.quad(self, Vector2(0.9, 0.6), Vector3(4.3, 3.6, -4.55), Kit.cmat(Color("#e8d9a8")), Vector3(0, 0, 3))
	var lbl := Label3D.new()
	lbl.text = "RENT DUE\nby order of\nThe Landlord"
	lbl.font = load("res://assets/fonts/cinzel-latin-900-normal.woff2")
	lbl.font_size = 64
	lbl.pixel_size = 0.0024
	lbl.modulate = Color("#5a1a12")
	lbl.outline_size = 0
	lbl.position = Vector3(0, 0, 0.01)
	notice.add_child(lbl)

func _bar() -> void:
	var bar := Node3D.new()
	bar.name = "Bar"
	bar.position = Vector3(3.2, 0, -3.65)
	add_child(bar)
	var wood := Kit.pmat("bar_wood", Vector2(5, 1))
	Kit.box(bar, Vector3(6.2, 1.1, 0.7), Vector3(0, 0.55, 0), wood)
	Kit.box(bar, Vector3(6.4, 0.08, 0.85), Vector3(0, 1.14, 0.05), Kit.pmat("walnut", Vector2(6, 1)))
	Kit.box(bar, Vector3(6.3, 0.06, 0.1), Vector3(0, 0.15, 0.38), Kit.cmat(Color("#c9a24a"), 0.9, 0.35))
	# Taps.
	for i in 3:
		var x := -0.9 + i * 0.45
		Kit.cyl(bar, 0.035, 0.42, Vector3(x, 1.38, -0.1), Kit.cmat(Color("#c9a24a"), 0.9, 0.3))
		Kit.box(bar, Vector3(0.05, 0.16, 0.05), Vector3(x, 1.62, -0.08), Kit.cmat(Color(["#7a2a2a", "#2a4a7a", "#2e6b3a"][i])))
	# Tankards on the counter.
	for x in [1.2, 1.5, 2.3]:
		Kit.cyl(bar, 0.08, 0.17, Vector3(x, 1.27, 0.12), Kit.cmat(Color("#b0863a"), 0.5, 0.45))
		Kit.cyl(bar, 0.085, 0.04, Vector3(x, 1.37, 0.12), Kit.cmat(Color("#fff3d0")))
	# Shelves with bottles.
	for y in [2.0, 2.65]:
		Kit.box(self, Vector3(4.6, 0.06, 0.3), Vector3(3.6, y, -4.42), Kit.pmat("walnut", Vector2(4, 1)))
		Kit.quad(self, Vector2(4.4, 0.55), Vector3(3.6, y + 0.3, -4.5), Kit.sprite_mat("bottles"))
	# Barrels behind the bar ends.
	for p in [Vector3(-0.4, 0, -3.9), Vector3(6.9, 0, -3.7), Vector3(7.6, 0, -2.9)]:
		_barrel(p)

func _barrel(p: Vector3, scale := 1.0) -> void:
	var b := Kit.cyl(self, 0.42 * scale, 1.0 * scale, p + Vector3(0, 0.5 * scale, 0), Kit.pmat("barrel", Vector2(3, 1)), Vector3.ZERO, -1, 14)
	for y in [-0.32, 0.32]:
		Kit.cyl(b, 0.44 * scale, 0.06, Vector3(0, y * scale, 0), Kit.cmat(Color("#3a3a40"), 0.7, 0.5), Vector3.ZERO, -1, 14)

func _fireplace() -> void:
	var fp := Node3D.new()
	fp.name = "Fireplace"
	fp.position = Vector3(7.7, 0, -4.1)
	add_child(fp)
	var stone := Kit.pmat("stone", Vector2(2, 2))
	Kit.box(fp, Vector3(0.45, 1.7, 0.8), Vector3(-0.85, 0.85, 0), stone)
	Kit.box(fp, Vector3(0.45, 1.7, 0.8), Vector3(0.85, 0.85, 0), stone)
	Kit.box(fp, Vector3(2.3, 0.6, 0.9), Vector3(0, 1.95, 0), stone)
	Kit.box(fp, Vector3(2.5, 0.12, 1.0), Vector3(0, 2.3, 0.05), Kit.pmat("walnut", Vector2(2, 1)))
	Kit.box(fp, Vector3(1.4, 1.6, 0.3), Vector3(0, 0.8, -0.3), Kit.cmat(Color(0.06, 0.04, 0.03)))
	Kit.box(fp, Vector3(0.9, 0.12, 0.3), Vector3(0, 0.12, 0.05), Kit.pmat("barrel"))
	for i in 3:
		var f := Kit.quad(fp, Vector2(0.5, 0.62), Vector3(-0.3 + i * 0.3, 0.45, 0.05 + i * 0.02), _flame_mat(i))
		flames.append(f)
	var l := Kit.omni(fp, Vector3(0, 0.8, 0.9), Color(1.0, 0.55, 0.22), 2.6, 7.0, true)
	flicker_lights.append(l)

func _flame_mat(i: int) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/flame.gdshader")
	m.set_shader_parameter("tex", Kit.tex("flame"))
	m.set_shader_parameter("offset", float(i))
	return m

func _lamps() -> void:
	for p in [Vector3(-4.9, 4.2, 1.4), Vector3(1.8, 3.9, -1.0), Vector3(3.9, 3.9, -1.0), Vector3(6.2, 3.9, 0.6), Vector3(-3.6, 4.2, -2.6)]:
		var lamp := Node3D.new()
		lamp.position = p
		add_child(lamp)
		Kit.cyl(lamp, 0.012, 5.5 - p.y, Vector3(0, (5.5 - p.y) / 2, 0), Kit.cmat(Color(0.1, 0.1, 0.1)))
		Kit.cyl(lamp, 0.16, 0.08, Vector3(0, 0.22, 0), Kit.cmat(Color("#3a3028"), 0.6, 0.5), Vector3.ZERO, 0.05)
		Kit.cyl(lamp, 0.11, 0.26, Vector3(0, 0.05, 0), Kit.cmat(Color(1.0, 0.8, 0.45), 0.0, 0.4, 3.0))
		Kit.cyl(lamp, 0.13, 0.04, Vector3(0, -0.1, 0), Kit.cmat(Color("#3a3028"), 0.6, 0.5))
		var l := Kit.omni(lamp, Vector3(0, -0.1, 0), Color(1.0, 0.74, 0.42), 1.5, 6.0, false)
		flicker_lights.append(l)

func _props() -> void:
	# Foreground table with candle and tankards (blurred by the tilt-shift, adds depth).
	var table := Node3D.new()
	table.position = Vector3(0.6, 0, 2.6)
	add_child(table)
	var walnut := Kit.pmat("walnut", Vector2(2, 1))
	Kit.box(table, Vector3(1.6, 0.08, 0.9), Vector3(0, 0.82, 0), walnut)
	for x in [-0.7, 0.7]:
		for z in [-0.35, 0.35]:
			Kit.box(table, Vector3(0.08, 0.8, 0.08), Vector3(x, 0.4, z), walnut)
	Kit.cyl(table, 0.04, 0.16, Vector3(-0.3, 0.94, 0.1), Kit.cmat(Color("#f2ead3")))
	var cf := Kit.quad(table, Vector2(0.09, 0.12), Vector3(-0.3, 1.07, 0.1), _flame_mat(3))
	flames.append(cf)
	flicker_lights.append(Kit.omni(table, Vector3(-0.3, 1.15, 0.1), Color(1.0, 0.7, 0.35), 0.7, 2.5))
	Kit.cyl(table, 0.08, 0.17, Vector3(0.3, 0.95, -0.1), Kit.cmat(Color("#b0863a"), 0.5, 0.45))
	_barrel(Vector3(-5.6, 0, 1.8))
	_barrel(Vector3(-5.9, 0, 0.8), 0.9)
	_barrel(Vector3(8.0, 0, 1.6))
	# Stools by the bar.
	for x in [1.6, 3.0, 4.4]:
		Kit.cyl(self, 0.22, 0.08, Vector3(x, 0.7, -2.85), Kit.pmat("walnut"))
		Kit.cyl(self, 0.04, 0.7, Vector3(x, 0.35, -2.85), Kit.pmat("walnut"))

func _process(dt: float) -> void:
	t += dt
	for i in flicker_lights.size():
		var l := flicker_lights[i]
		var base: float = l.get_meta("base", l.light_energy)
		if not l.has_meta("base"):
			l.set_meta("base", base)
		l.light_energy = base * (0.9 + 0.08 * sin(t * 7.0 + i * 1.7) + 0.05 * sin(t * 13.3 + i))
