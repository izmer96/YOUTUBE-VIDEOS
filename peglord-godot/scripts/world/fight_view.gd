extends Node3D
## The fight floor on the pub rug: hero and foe sprites, spell effects and floating numbers.

const HERO_SPOTS := [Vector3(1.6, 0, -2.25), Vector3(0.95, 0, -1.3), Vector3(1.6, 0, -0.35)]
const FOE_SPOTS := [Vector3(3.9, 0, -2.25), Vector3(4.55, 0, -1.3), Vector3(3.9, 0, -0.35)]
const CENTER := Vector3(2.75, 0.6, -1.25)

signal shake(amount: float)

var units := {}     # "hero:id" / "foe:id" -> Unit
var font_bold: Font
var glyph_shader: Shader

func _ready() -> void:
	font_bold = load("res://assets/fonts/alegreya-sans-latin-800-normal.woff2")
	glyph_shader = load("res://shaders/glyph.gdshader")
	Bus.new_run.connect(rebuild)
	Bus.refresh.connect(sync)
	Bus.unit_fx.connect(_unit_fx)
	Bus.unit_anim.connect(_unit_anim)
	Bus.effect.connect(_effect)
	Bus.projectile.connect(_projectile)
	Bus.cast.connect(_cast)
	var stage := SpotLight3D.new()
	stage.light_color = Color(1.0, 0.86, 0.68)
	stage.light_energy = 1.8
	stage.spot_range = 9.0
	stage.spot_angle = 34
	stage.spot_attenuation = 0.7
	stage.shadow_enabled = true
	add_child(stage)
	stage.look_at_from_position(Vector3(2.75, 5.2, 1.6), Vector3(2.75, 0, -1.3))

func unit(side: String, id: int) -> Unit:
	return units.get("%s:%d" % [side, id])

func rebuild() -> void:
	for u in units.values():
		u.queue_free()
	units.clear()
	var G := S.G
	for i in G.heroes.size():
		var h: Dictionary = G.heroes[i]
		var u := Unit.new()
		add_child(u)
		u.setup(h.cls, "hero", h.id, HERO_SPOTS[i % 3] + Vector3(-0.6 * int(i / 3), 0, 0.3 * int(i / 3)))
		units["hero:%d" % h.id] = u
	var n: int = G.foes.size()
	for i in n:
		var f: Dictionary = G.foes[i]
		var kind: String = "landlord" if f.boss else f.type
		var u2 := Unit.new()
		add_child(u2)
		var spot: Vector3 = FOE_SPOTS[i % 3] + Vector3(0.6 * int(i / 3), 0, 0.3 * int(i / 3))
		u2.setup(kind, "foe", f.id, spot, 1.5 if f.boss else 1.0)
		units["foe:%d" % f.id] = u2
		# Foes walk in from the right.
		u2.position = spot + Vector3(2.5, 0, 0)
		var tw := create_tween()
		tw.tween_interval(0.15 * i)
		tw.tween_property(u2, "position", spot, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	sync()

func sync() -> void:
	var G := S.G
	if G.is_empty():
		return
	for h in G.heroes:
		var u := unit("hero", h.id)
		if u:
			u.set_dead(h.dead)
	for f in G.foes:
		var u2 := unit("foe", f.id)
		if u2:
			u2.set_dead(f.dead)
			u2.target = (f.id == G.target and not f.dead and (G.phase == "alloc" or G.phase == "aim" or G.phase == "ball" or G.phase == "sink"))

## Which foe sits under a screen point (for picking a target).
func foe_at(cam: Camera3D, screen: Vector2):
	var best = null
	var bd := 70.0
	for f in S.G.foes:
		if f.dead:
			continue
		var u := unit("foe", f.id)
		if u == null:
			continue
		var p := cam.unproject_position(u.body_global())
		var d := p.distance_to(screen)
		if d < bd:
			bd = d
			best = f
	return best

# ---------- Animations and effects ----------
func _unit_anim(side: String, id: int, anim: String) -> void:
	var u := unit(side, id)
	if u == null:
		return
	if anim == "lunge":
		var other := _first_living_opponent(side)
		u.lunge(other.global_position if other else CENTER)
	elif anim == "hit":
		u.knockback()
		if side == "hero":
			shake.emit(3.0)

func _first_living_opponent(side: String) -> Unit:
	var G := S.G
	if side == "hero":
		var t = Battle.current_target()
		if t != null:
			return unit("foe", t.id)
	else:
		for h in G.heroes:
			if not h.dead:
				return unit("hero", h.id)
	return null

func _cast(side: String, id: int) -> void:
	var u := unit(side, id)
	if u == null:
		return
	u.play("cast")
	var c := Color(0.75, 0.55, 1.0) if side == "hero" else Color(0.5, 1.0, 0.55)
	var circle := _glyph(u.global_position + Vector3(0, 0.03, 0), 1.3, c, 3, Vector3(-90, 0, 0))
	var tw := create_tween()
	tw.tween_method(func(x): circle.material_override.set_shader_parameter("progress", x), 0.0, 1.0, 0.8)
	tw.tween_callback(circle.queue_free)
	_flash_light(u.body_global(), c, 2.0, 0.6)

func _glyph(pos: Vector3, size: float, c: Color, kind: int, rot := Vector3.ZERO, billboard := false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	mi.mesh = q
	var m := ShaderMaterial.new()
	m.shader = glyph_shader
	m.set_shader_parameter("color", c)
	m.set_shader_parameter("kind", kind)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	mi.global_position = pos
	mi.rotation_degrees = rot
	if billboard:
		var cam := get_viewport().get_camera_3d()
		if cam:
			mi.look_at(cam.global_position, Vector3.UP, true)
	return mi

func _flash_light(pos: Vector3, c: Color, energy: float, dur: float) -> void:
	var l := OmniLight3D.new()
	l.light_color = c
	l.light_energy = energy
	l.omni_range = 2.5
	add_child(l)
	l.global_position = pos + Vector3(0, 0.3, 0.4)
	var tw := create_tween()
	tw.tween_property(l, "light_energy", 0.0, dur)
	tw.tween_callback(l.queue_free)

func _particles(pos: Vector3, c: Color, n: int, up := 1.0, spread := 180.0, speed := 1.4, life := 0.8, size := 0.05) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.amount = n
	p.lifetime = life
	p.explosiveness = 0.9
	p.direction = Vector3(0, 1, 0)
	p.spread = spread
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.gravity = Vector3(0, -3.0 * (1.0 - up) + 0.6 * up, 0)
	var bm := BoxMesh.new()
	bm.size = Vector3(size, size, size)
	p.mesh = bm
	var m := Kit.unshaded(c)
	p.material_override = m
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.0
	add_child(p)
	p.global_position = pos
	p.emitting = true
	get_tree().create_timer(life + 0.5).timeout.connect(p.queue_free)

func _effect(side: String, id: int, kind: String) -> void:
	if id < 0:
		# A blow that hits the whole party: flash every living hero.
		for h in S.G.heroes:
			if not h.dead:
				_effect(side, h.id, kind)
		return
	var u := unit(side, id)
	if u == null:
		return
	var at := u.body_global()
	var cam := get_viewport().get_camera_3d()
	var toward := (cam.global_position - at).normalized() * 0.25 if cam else Vector3(0, 0, 0.25)
	match kind:
		"slash":
			var g := _glyph(at + toward, 1.3, Color(1, 0.95, 0.85), 1, Vector3.ZERO, true)
			g.rotate_object_local(Vector3(0, 0, 1), randf_range(-0.6, 0.6))
			var tw := create_tween()
			tw.tween_method(func(x): g.material_override.set_shader_parameter("progress", x), 0.0, 1.0, 0.22)
			tw.tween_callback(g.queue_free)
			_particles(at + toward, Color(1, 0.9, 0.7), 10, 0.0, 120, 2.0, 0.35, 0.03)
		"zap":
			_bolt(at)
			_flash_light(at, Color(0.7, 0.6, 1.0), 4.0, 0.3)
			_particles(at + toward, Color(0.8, 0.7, 1.0), 12, 0.2, 180, 1.6, 0.4, 0.035)
		"holy":
			_particles(at + toward, Color(1, 0.88, 0.45), 16, 1.0, 40, 1.6, 0.7, 0.04)
			_flash_light(at, Color(1, 0.85, 0.4), 3.0, 0.4)
			var r := _glyph(at + toward, 1.2, Color(1, 0.85, 0.4), 0, Vector3.ZERO, true)
			var tw2 := create_tween().set_parallel(true)
			tw2.tween_property(r, "scale", Vector3.ONE * 1.6, 0.35)
			tw2.tween_method(func(x): r.material_override.set_shader_parameter("progress", x), 0.0, 1.0, 0.35)
			tw2.chain().tween_callback(r.queue_free)
		"heal":
			_particles(u.global_position + Vector3(0, 0.2, 0) + toward, Color(0.5, 1.0, 0.6), 18, 1.0, 25, 1.0, 1.0, 0.04)
			_flash_light(at, Color(0.5, 1.0, 0.6), 1.5, 0.6)
		"block":
			var s := _glyph(at + toward, 1.5, Color(0.5, 0.75, 1.0), 0, Vector3.ZERO, true)
			var tw3 := create_tween().set_parallel(true)
			tw3.tween_property(s, "scale", Vector3.ONE * 1.2, 0.3)
			tw3.tween_method(func(x): s.material_override.set_shader_parameter("progress", x), 0.0, 1.0, 0.45)
			tw3.chain().tween_callback(s.queue_free)
		"burn":
			_particles(at + toward, Color(1, 0.55, 0.2), 12, 1.0, 30, 1.0, 0.6, 0.04)
		"boom":
			_particles(at + toward, Color(1, 0.6, 0.25), 24, 0.0, 180, 2.5, 0.6, 0.06)
			_flash_light(at, Color(1, 0.6, 0.3), 5.0, 0.5)
			shake.emit(6.0)

func _bolt(at: Vector3) -> void:
	var im := ImmediateMesh.new()
	var mi := MeshInstance3D.new()
	mi.mesh = im
	mi.material_override = Kit.unshaded(Color(0.9, 0.85, 1.0))
	add_child(mi)
	im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	var p := at + Vector3(randf_range(-0.3, 0.3), 2.2, 0)
	for i in 9:
		im.surface_add_vertex(p)
		p = p.lerp(at, 0.35) + Vector3(randf_range(-0.15, 0.15), 0, randf_range(-0.1, 0.1))
	im.surface_add_vertex(at)
	im.surface_end()
	get_tree().create_timer(0.18).timeout.connect(mi.queue_free)

func _projectile(fs: String, fid: int, ts: String, tid: int, kind: String) -> void:
	var a := unit(fs, fid)
	var b := unit(ts, tid)
	if a == null or b == null:
		return
	a.play("cast")
	var orb := Node3D.new()
	add_child(orb)
	var start := a.body_global() + Vector3(0.3, 0.2, 0)
	var end := b.body_global()
	orb.global_position = start
	var core := Kit.sphere(orb, 0.11, Vector3.ZERO, Kit.unshaded(Color(1.0, 0.8, 0.4)), 10)
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var halo := _glyph(Vector3.ZERO, 0.7, Color(1, 0.5, 0.15), 2, Vector3.ZERO, true)
	halo.reparent(orb, false)
	var l := Kit.omni(orb, Vector3.ZERO, Color(1, 0.55, 0.2), 3.0, 3.0)
	var trail := CPUParticles3D.new()
	trail.amount = 30
	trail.lifetime = 0.35
	trail.local_coords = false
	trail.gravity = Vector3(0, 0.8, 0)
	trail.initial_velocity_max = 0.2
	var bm := BoxMesh.new()
	bm.size = Vector3(0.05, 0.05, 0.05)
	trail.mesh = bm
	trail.material_override = Kit.unshaded(Color(1, 0.6, 0.2))
	orb.add_child(trail)
	var tw := create_tween()
	tw.tween_method(func(k): orb.global_position = start.lerp(end, k) + Vector3(0, sin(k * PI) * 0.5, 0), 0.0, 1.0, 0.38)
	tw.tween_callback(func():
		_particles(end, Color(1, 0.6, 0.2), 26, 0.3, 180, 2.4, 0.6, 0.06)
		_flash_light(end, Color(1, 0.55, 0.2), 5.0, 0.5)
		shake.emit(5.0)
		orb.queue_free())
	l.light_energy = 3.0

func _unit_fx(side: String, id: int, text: String, kind: String) -> void:
	var u := unit(side, id)
	if u == null:
		return
	var l := Label3D.new()
	l.text = text
	l.font = font_bold
	var crit := kind == "crit"
	l.font_size = 120 if crit else 92
	l.pixel_size = 0.004
	l.outline_size = 22
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.render_priority = 5
	l.outline_render_priority = 4
	var col := Color.WHITE
	match kind:
		"dmg": col = Color("#fff1d6") if side == "foe" else Color("#ff8a7a")
		"crit": col = Color("#ffd23f")
		"heal": col = Color("#7dffa6")
		"block": col = Color("#9cc8ff")
	l.modulate = col
	l.outline_modulate = Color(0.12, 0.05, 0.03)
	add_child(l)
	var jitter := Vector3(randf_range(-0.15, 0.15), 0, 0)
	l.global_position = u.head_global() + jitter
	l.scale = Vector3.ONE * (0.4 if crit else 0.6)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(l, "scale", Vector3.ONE * (1.3 if crit else 1.0), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "global_position:y", l.global_position.y + 0.5, 1.1).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.5).set_delay(0.75)
	tw.tween_property(l, "outline_modulate:a", 0.0, 0.5).set_delay(0.75)
	tw.chain().tween_callback(l.queue_free)
	if crit:
		shake.emit(4.0)
