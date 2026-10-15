extends Node3D
## The bagatelle cabinet: draws Game.board (BoardSim) in 3D and turns its events into effects.

const S_ := 0.005          # metres per board unit
const BASE_Y := 0.9       # height of the board's bottom edge
const DEPTH := 0.04       # how far pegs stand out of the felt

signal shake(amount: float)

var sim: BoardSim
var peg_nodes := {}        # id -> MeshInstance3D
var peg_mats := {}         # id -> StandardMaterial3D
var ball_node: Node3D
var ball_light: OmniLight3D
var trail: Array[MeshInstance3D] = []
var trail_pts: Array[Vector3] = []
var aim_arm: Node3D
var aim_dots: MultiMeshInstance3D
var pocket_lamps: Array[MeshInstance3D] = []
var pocket_glow: Array[OmniLight3D] = []
var big_label: Label3D
var big_t := 9.0
var font_bold: Font
var t := 0.0

func _ready() -> void:
	sim = Game.board
	font_bold = load("res://assets/fonts/alegreya-sans-latin-800-normal.woff2")
	_cabinet()
	_ball()
	_aim()
	sim.built.connect(_rebuild)
	sim.fx_burst.connect(_burst)
	sim.fx_ring.connect(_ring)
	sim.fx_arc.connect(_arc)
	sim.fx_float.connect(_float)
	sim.fx_big.connect(_big)
	sim.fx_shake.connect(func(a): shake.emit(a))
	sim.peg_broken.connect(_peg_broken)
	sim.sunk.connect(_sunk)

## Board units -> this node's local space.
func bpos(x: float, y: float, z := 0.0) -> Vector3:
	return Vector3((x - D.PHYS.W / 2.0) * S_, BASE_Y + (D.PHYS.H - y) * S_, z)

func board_center_global() -> Vector3:
	return to_global(bpos(240, 330))

## Intersect a camera ray with the board plane; returns board coords or null.
func ray_to_board(cam: Camera3D, screen: Vector2):
	var from := cam.project_ray_origin(screen)
	var dir := cam.project_ray_normal(screen)
	var plane := Plane(global_transform.basis.z.normalized(), global_position)
	var hit = plane.intersects_ray(from, dir)
	if hit == null:
		return null
	var l := to_local(hit)
	return Vector2(l.x / S_ + D.PHYS.W / 2.0, D.PHYS.H - (l.y - BASE_Y) / S_)

func screen_of_board(cam: Camera3D, x: float, y: float) -> Vector2:
	return cam.unproject_position(to_global(bpos(x, y, DEPTH)))

# ---------- Cabinet ----------
func _cabinet() -> void:
	var W: float = D.PHYS.W * S_
	var H: float = D.PHYS.H * S_
	var cx := 0.0
	var cy := BASE_Y + H / 2.0
	var felt := Kit.pmat("felt", Vector2(6, 8), Color(1, 1, 1), 0.95)
	Kit.box(self, Vector3(W, H, 0.04), Vector3(cx, cy, -0.02), felt)
	var walnut := Kit.pmat("walnut", Vector2(1, 4))
	var brass := Kit.cmat(Color("#c9a24a"), 0.85, 0.32)
	var fw := 0.16
	# Frame sides, top crest and the pocket tray.
	Kit.box(self, Vector3(fw, H + 0.3, 0.22), Vector3(-W / 2 - fw / 2, cy, 0.05), walnut)
	Kit.box(self, Vector3(fw, H + 0.3, 0.22), Vector3(W / 2 + fw / 2, cy, 0.05), walnut)
	Kit.box(self, Vector3(W + fw * 2, 0.16, 0.22), Vector3(cx, BASE_Y + H + 0.08, 0.05), Kit.pmat("walnut", Vector2(4, 1)))
	Kit.box(self, Vector3(W + fw * 2 + 0.1, 0.06, 0.26), Vector3(cx, BASE_Y + H + 0.18, 0.06), brass)
	Kit.box(self, Vector3(W + fw * 2, BASE_Y, 0.5), Vector3(cx, BASE_Y / 2, 0.1), Kit.pmat("walnut", Vector2(4, 2)))
	Kit.box(self, Vector3(W + fw * 2 + 0.06, 0.05, 0.56), Vector3(cx, BASE_Y + 0.0, 0.1), brass)
	Kit.box(self, Vector3(W + fw * 2, H + 0.3, 0.1), Vector3(cx, cy, -0.09), walnut)
	# Brass trim strips on the frame.
	for sx in [-1, 1]:
		Kit.box(self, Vector3(0.02, H + 0.3, 0.02), Vector3(sx * (W / 2 + 0.005), cy, 0.17), brass)
	# Crest with the game name.
	var crest := Kit.box(self, Vector3(1.5, 0.42, 0.12), Vector3(cx, BASE_Y + H + 0.42, 0.02), Kit.pmat("walnut", Vector2(3, 1)))
	Kit.box(crest, Vector3(1.56, 0.04, 0.14), Vector3(0, 0.22, 0), brass)
	var title := Label3D.new()
	title.text = "PEGLORD"
	title.font = load("res://assets/fonts/cinzel-latin-900-normal.woff2")
	title.font_size = 96
	title.pixel_size = 0.0028
	title.modulate = Color("#ffd27a")
	title.outline_size = 10
	title.outline_modulate = Color("#2a160a")
	title.position = Vector3(0, 0, 0.07)
	crest.add_child(title)
	Kit.omni(crest, Vector3(0, -0.1, 0.5), Color(1, 0.8, 0.5), 0.6, 1.6)
	var spot := SpotLight3D.new()
	spot.light_color = Color(1.0, 0.9, 0.75)
	spot.light_energy = 2.2
	spot.spot_range = 5.0
	spot.spot_angle = 38
	spot.spot_attenuation = 0.6
	spot.shadow_enabled = true
	spot.position = Vector3(0, BASE_Y + H + 0.5, 1.7)
	spot.rotation_degrees = Vector3(-62, 0, 0)
	add_child(spot)
	# Pocket bins and dividers' lamps.
	var pw: float = W / D.PHYS.pocketCount
	for i in D.PHYS.pocketCount:
		var px: float = -W / 2 + pw * (i + 0.5)
		Kit.box(self, Vector3(pw - 0.03, (D.PHYS.H - D.PHYS.pocketTop) * S_, 0.02), Vector3(px, BASE_Y + (D.PHYS.H - D.PHYS.pocketTop) * S_ / 2, 0.0), Kit.cmat(Color(0.05, 0.08, 0.06)))
		var lamp := Kit.sphere(self, 0.022, bpos(pw / S_ * (i + 0.5), D.PHYS.pocketTop + 14, 0.03), Kit.cmat(Color("#8a6a2a"), 0, 0.4, 0.6), 8)
		pocket_lamps.append(lamp)
		var gl := Kit.omni(self, bpos(pw / S_ * (i + 0.5), D.PHYS.pocketTop + 24, 0.12), Color.WHITE, 0.0, 0.5)
		pocket_glow.append(gl)
	# Legs.
	for sx in [-1, 1]:
		Kit.box(self, Vector3(0.12, 0.3, 0.12), Vector3(sx * (W / 2 + 0.05), 0.0, 0.25), walnut)
	big_label = Label3D.new()
	big_label.font = font_bold
	big_label.font_size = 160
	big_label.pixel_size = 0.004
	big_label.outline_size = 28
	big_label.modulate = Color("#ffd23f")
	big_label.outline_modulate = Color("#4a2a10")
	big_label.position = bpos(240, 300, 0.25)
	big_label.visible = false
	big_label.no_depth_test = true
	add_child(big_label)

func _ball() -> void:
	ball_node = Node3D.new()
	add_child(ball_node)
	var m := Kit.cmat(Color(0.86, 0.88, 0.92), 0.7, 0.18)
	m.emission_enabled = true
	m.emission = Color(0.25, 0.25, 0.28)
	Kit.sphere(ball_node, D.PHYS.ballR * S_, Vector3.ZERO, m, 20)
	ball_light = Kit.omni(ball_node, Vector3(0, 0, 0.08), Color(1, 0.95, 0.85), 0.6, 0.7)
	ball_node.visible = false
	for i in 14:
		var tm := Kit.unshaded(Color(1, 1, 1, 0.0), true)
		var s := Kit.sphere(self, D.PHYS.ballR * S_, Vector3.ZERO, tm, 8)
		s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		s.visible = false
		trail.append(s)

func _aim() -> void:
	aim_arm = Node3D.new()
	aim_arm.position = bpos(D.PHYS.launcherX, D.PHYS.launcherY, 0.02)
	add_child(aim_arm)
	var brass := Kit.cmat(Color("#d8b25a"), 0.85, 0.3)
	Kit.cyl(self, 0.09, 0.06, bpos(D.PHYS.launcherX, D.PHYS.launcherY - 8, 0.03), Kit.cmat(Color("#5a3a1e")), Vector3(90, 0, 0))
	Kit.cyl(self, 0.06, 0.07, bpos(D.PHYS.launcherX, D.PHYS.launcherY - 8, 0.04), brass, Vector3(90, 0, 0))
	var barrel := Kit.box(aim_arm, Vector3(0.12, 0.035, 0.035), Vector3(0.06, 0, 0.02), brass)
	barrel.name = "Barrel"
	aim_dots = MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var sm := SphereMesh.new()
	sm.radius = 0.008
	sm.height = 0.016
	sm.radial_segments = 6
	sm.rings = 3
	mm.mesh = sm
	mm.instance_count = 90
	aim_dots.multimesh = mm
	var dm := Kit.unshaded(Color(1, 0.95, 0.8, 1.0), true)
	dm.vertex_color_use_as_albedo = true
	aim_dots.material_override = dm
	aim_dots.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(aim_dots)

# ---------- Pegs ----------
func _peg_mat(type: String) -> StandardMaterial3D:
	var c := Color(D.PEGS[type].color)
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 0.45
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = 0.35
	match type:
		"brass", "chest":
			m.metallic = 0.5
			m.roughness = 0.3
		"gold":
			m.metallic = 0.25
			m.roughness = 0.25
			m.albedo_color = c.lightened(0.1)
		"crate":
			m.albedo_texture = Kit.tex("barrel")
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			m.albedo_color = Color(1.0, 0.85, 0.7)
		"glass":
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.albedo_color = Color(c.r, c.g, c.b, 0.55)
			m.roughness = 0.05
			m.metallic_specular = 1.0
		"bumper", "portal":
			m.metallic = 0.4
			m.roughness = 0.25
	return m

func _peg_mesh(p: Dictionary) -> Mesh:
	var shape: String = D.PEGS[p.type].shape if p.type != "post" else "circle"
	match shape:
		"ring", "donut":
			var tm := TorusMesh.new()
			tm.inner_radius = p.r * S_ * (0.45 if shape == "ring" else 0.4)
			tm.outer_radius = p.r * S_ * 1.05
			tm.rings = 18
			tm.ring_segments = 8
			return tm
		"circle":
			var cm := CylinderMesh.new()
			cm.top_radius = p.r * S_ * 0.82
			cm.bottom_radius = p.r * S_
			cm.height = DEPTH
			cm.radial_segments = 14
			cm.rings = 1
			return cm
	return Kit.extrude(Kit.shape_poly(shape, p.r), DEPTH, S_)

func _rebuild() -> void:
	for n in peg_nodes.values():
		n.queue_free()
	peg_nodes.clear()
	peg_mats.clear()
	for p in sim.pegs:
		var mi := MeshInstance3D.new()
		mi.mesh = _peg_mesh(p)
		var m: StandardMaterial3D
		if p.type == "post":
			m = Kit.cmat(Color("#b8913f"), 0.8, 0.35)
		else:
			m = _peg_mat(p.type)
		mi.material_override = m
		var shape: String = D.PEGS[p.type].shape if p.type != "post" else "circle"
		if shape == "circle" or shape == "ring" or shape == "donut":
			mi.rotation_degrees = Vector3(90, 0, 0)
		mi.position = bpos(p.x, p.y, DEPTH / 2.0 if shape == "circle" else (0.012 if shape == "ring" or shape == "donut" else 0.0))
		mi.set_meta("z", mi.position.z)
		if p.type == "portal":
			Kit.cyl(mi, p.r * S_ * 0.42, 0.005, Vector3.ZERO, Kit.unshaded(Color("#1a0c33")))
		if p.type == "bomb":
			Kit.cyl(mi, 0.004, 0.03, Vector3(0.012, 0.03, DEPTH * 0.6), Kit.cmat(Color("#ffcc80"), 0, 0.5, 1.0), Vector3(0, 0, -30))
		if p.type == "crate" or p.type == "chest":
			var lbl := Label3D.new()
			lbl.font = font_bold
			lbl.font_size = 40
			lbl.pixel_size = 0.0011
			lbl.outline_size = 8
			lbl.position = Vector3(0, 0, DEPTH + 0.004)
			lbl.name = "Hits"
			lbl.text = ""
			mi.add_child(lbl)
		mi.scale = Vector3.ONE * 0.01
		var tw := create_tween()
		tw.tween_interval(randf() * 0.35)
		tw.tween_property(mi, "scale", Vector3.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		add_child(mi)
		peg_nodes[p.id] = mi
		peg_mats[p.id] = m

func _peg_broken(p: Dictionary) -> void:
	var n = peg_nodes.get(p.id)
	if n == null:
		return
	peg_nodes.erase(p.id)
	var tw := create_tween()
	tw.tween_property(n, "scale", Vector3.ONE * 1.5, 0.08)
	tw.tween_property(n, "scale", Vector3.ONE * 0.01, 0.14)
	tw.tween_callback(n.queue_free)

# ---------- Effects ----------
func _burst(pos: Vector2, color: Color, n: int) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = maxi(4, n)
	p.lifetime = 0.7
	p.explosiveness = 1.0
	p.direction = Vector3(0, 1, 0)
	p.spread = 180
	p.initial_velocity_min = 0.3
	p.initial_velocity_max = 1.0
	p.gravity = Vector3(0, -2.5, 0)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.2
	var bm := BoxMesh.new()
	bm.size = Vector3(0.016, 0.016, 0.016)
	p.mesh = bm
	var m := Kit.unshaded(color)
	m.emission_enabled = true
	p.material_override = m
	p.position = bpos(pos.x, pos.y, DEPTH)
	add_child(p)
	p.emitting = true
	get_tree().create_timer(1.2).timeout.connect(p.queue_free)
	var fl := Kit.omni(self, bpos(pos.x, pos.y, 0.15), color, 1.5, 0.8)
	var tw := create_tween()
	tw.tween_property(fl, "light_energy", 0.0, 0.35)
	tw.tween_callback(fl.queue_free)

func _ring(pos: Vector2, radius: float, color: Color) -> void:
	var tm := TorusMesh.new()
	tm.inner_radius = 0.9
	tm.outer_radius = 1.0
	tm.rings = 32
	tm.ring_segments = 4
	var mi := MeshInstance3D.new()
	mi.mesh = tm
	var m := Kit.unshaded(Color(color.r, color.g, color.b, 0.9), true)
	mi.material_override = m
	mi.rotation_degrees = Vector3(90, 0, 0)
	mi.position = bpos(pos.x, pos.y, DEPTH)
	mi.scale = Vector3.ONE * 0.01
	add_child(mi)
	var r := radius * S_
	var tw := create_tween().set_parallel(true)
	tw.tween_property(mi, "scale", Vector3(r, 0.2, r), 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(m, "albedo_color:a", 0.0, 0.4)
	tw.chain().tween_callback(mi.queue_free)
	if radius > 40:
		var fl := Kit.omni(self, bpos(pos.x, pos.y, 0.3), Color(1, 0.6, 0.25), 4.0, 1.8)
		var t2 := create_tween()
		t2.tween_property(fl, "light_energy", 0.0, 0.5)
		t2.tween_callback(fl.queue_free)

func _arc(a: Vector2, b: Vector2) -> void:
	var im := ImmediateMesh.new()
	var mi := MeshInstance3D.new()
	mi.mesh = im
	var m := Kit.unshaded(Color(0.85, 0.75, 1.0))
	mi.material_override = m
	add_child(mi)
	im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	im.surface_add_vertex(bpos(a.x, a.y, DEPTH + 0.01))
	for i in range(1, 6):
		var k := i / 6.0
		var q := a.lerp(b, k) + Vector2(randf_range(-6, 6), randf_range(-6, 6))
		im.surface_add_vertex(bpos(q.x, q.y, DEPTH + 0.01))
	im.surface_add_vertex(bpos(b.x, b.y, DEPTH + 0.01))
	im.surface_end()
	get_tree().create_timer(0.3).timeout.connect(mi.queue_free)

func _float(pos: Vector2, text: String, color: Color, size: int) -> void:
	var l := Label3D.new()
	l.text = text
	l.font = font_bold
	l.font_size = 48 if size < 13 else 56
	l.pixel_size = 0.0016
	l.outline_size = 12
	l.modulate = color
	l.outline_modulate = Color(0.1, 0.05, 0.02)
	l.no_depth_test = true
	l.position = bpos(pos.x, pos.y, 0.12)
	add_child(l)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y + 0.14, 1.0).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 1.0).set_delay(0.35)
	tw.tween_property(l, "outline_modulate:a", 0.0, 1.0).set_delay(0.35)
	tw.chain().tween_callback(l.queue_free)

func _big(text: String) -> void:
	big_label.text = text
	big_label.visible = true
	big_t = 0.0

func _sunk(slot: int, type: String) -> void:
	var good: bool = D.POCKETS[type].kind == "perk"
	var c := Color("#5ef08a") if good else Color("#ff5a4a")
	var lamp := pocket_lamps[slot]
	(lamp.material_override as StandardMaterial3D).albedo_color = c
	(lamp.material_override as StandardMaterial3D).emission = c
	(lamp.material_override as StandardMaterial3D).emission_energy_multiplier = 3.0
	pocket_glow[slot].light_color = c
	var tw := create_tween()
	tw.tween_property(pocket_glow[slot], "light_energy", 2.5, 0.15)
	_burst(Vector2((slot + 0.5) * D.PHYS.W / D.PHYS.pocketCount, D.PHYS.H - 20), c, 16)

func _reset_pockets() -> void:
	for i in pocket_lamps.size():
		var m := pocket_lamps[i].material_override as StandardMaterial3D
		m.albedo_color = Color("#8a6a2a")
		m.emission = Color("#8a6a2a")
		m.emission_energy_multiplier = 0.6
		pocket_glow[i].light_energy = 0.0

# ---------- Per-frame sync ----------
func _process(dt: float) -> void:
	t += dt
	var G := S.G
	if G.is_empty():
		return
	sim.update(dt)
	for p in sim.pegs:
		var n = peg_nodes.get(p.id)
		if n == null:
			continue
		var shape: String = D.PEGS[p.type].shape if p.type != "post" else "circle"
		var pos := bpos(p.x, p.y, n.get_meta("z"))
		n.position = pos
		if p.type == "post":
			continue
		var m: StandardMaterial3D = peg_mats[p.id]
		var lit: bool = p.lit
		var e: float = (1.0 if p.type == "gold" else 0.35) + p.glow * 3.0 + (1.8 if lit else 0.0)
		m.emission_energy_multiplier = e
		if lit and not D.REARM.has(p.type) and p.type != "crate" and p.type != "chest":
			m.emission = Color(D.PEGS[p.type].color).lightened(0.4)
		else:
			m.emission = Color(D.PEGS[p.type].color)
		if p.glow > 0.0:
			n.scale = Vector3.ONE * (1.0 + p.glow * 0.25)
		if p.type == "rover":
			n.rotation_degrees.z = 0
		if p.type == "crate" or p.type == "chest":
			var need: int = ((2 if S.has_joker("crowbar") else 3) if p.type == "crate" else 2)
			var lbl: Label3D = n.get_node_or_null("Hits")
			if lbl:
				lbl.text = str(need - p.hits) if p.hits > 0 else ""
		if shape == "star":
			n.rotation_degrees.z = sin(t * 2.0 + p.phase) * 8
	# Ball and trail.
	var b = sim.ball
	if b != null:
		ball_node.visible = true
		ball_node.position = bpos(b.x, b.y, D.PHYS.ballR * S_)
		var gold := sim.mult_for(b.combo) >= 2
		ball_light.light_color = Color(1, 0.8, 0.3) if gold else Color(1, 0.95, 0.85)
		ball_light.light_energy = 1.4 if gold else 0.6
		trail_pts.push_front(ball_node.position)
		if trail_pts.size() > trail.size():
			trail_pts.pop_back()
		for i in trail.size():
			var s := trail[i]
			if i < trail_pts.size():
				s.visible = true
				s.position = trail_pts[i]
				var k := 1.0 - float(i) / trail.size()
				s.scale = Vector3.ONE * k
				(s.material_override as StandardMaterial3D).albedo_color = Color(1, 0.82, 0.25, k * 0.55) if gold else Color(1, 1, 1, k * 0.22)
			else:
				s.visible = false
	else:
		ball_node.visible = false
		trail_pts.clear()
		for s in trail:
			s.visible = false
	# Aim arm and the dotted preview.
	aim_arm.rotation.z = -sim.aim
	var mm := aim_dots.multimesh
	if G.phase == "aim":
		var pts := sim.preview_path()
		mm.visible_instance_count = mini(pts.size(), mm.instance_count)
		for i in mm.visible_instance_count:
			var q := pts[i]
			mm.set_instance_transform(i, Transform3D(Basis(), bpos(q.x, q.y, 0.03)))
			mm.set_instance_color(i, Color(1, 0.95, 0.8, 1.0 - i / 90.0))
	else:
		mm.visible_instance_count = 0
	# Pocket lamps: glint (Peephole) and reset after a reveal.
	if sim.reveal == null:
		if G.phase != "sink":
			_reset_pockets()
		if sim.glint >= 0 and G.phase == "ball":
			var gm := pocket_lamps[sim.glint].material_override as StandardMaterial3D
			gm.emission = Color.WHITE
			gm.emission_energy_multiplier = 1.5 + 1.5 * sin(t * 10.0)
	if big_label.visible:
		big_t += dt
		var k2 := big_t
		var sc := 1.0 + maxf(0.0, 0.4 - k2) * 1.5
		big_label.scale = Vector3.ONE * sc
		big_label.modulate.a = clampf(2.0 * (0.9 - k2) + 0.2, 0, 1)
		big_label.outline_modulate.a = big_label.modulate.a
		if big_t > 0.9:
			big_label.visible = false
