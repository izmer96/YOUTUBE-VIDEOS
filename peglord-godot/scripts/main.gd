extends Node3D
## Scene root: builds the pub diorama, the camera rig, post-processing and UI, and routes input.

var pub: Node3D
var board: Node3D
var fight: Node3D
var cam: Camera3D
var ui: CanvasLayer
var post: ColorRect
var focus := "board"          # "board" or "fight"
var shake_amt := 0.0
var cam_from := Transform3D()
var cam_to := Transform3D()
var cam_k := 1.0
var cam_fov_from := 40.0
var cam_fov_to := 40.0
var mouse := Vector2.ZERO
var t := 0.0
var shot_path := ""
var shot_frames := 0
var dragging := false

# Camera framings: where the camera sits and what it looks at.
const VIEWS := {
	"board": {"pos": Vector3(0.5, 2.9, 6.9), "look": Vector3(-1.1, 2.45, -0.2), "fov": 40.0},
	"fight": {"pos": Vector3(2.75, 3.4, 4.3), "look": Vector3(2.75, 0.55, -1.3), "fov": 42.0},
	"title": {"pos": Vector3(1.0, 2.6, 5.2), "look": Vector3(1.2, 1.7, -1.5), "fov": 50.0},
}

func _ready() -> void:
	_environment()
	pub = preload("res://scripts/world/pub.gd").new()
	pub.name = "Pub"
	add_child(pub)
	board = preload("res://scripts/world/board_view.gd").new()
	board.name = "Board"
	board.position = Vector3(-2.1, 0, 0.45)
	board.rotation_degrees = Vector3(0, 14, 0)
	add_child(board)
	fight = preload("res://scripts/world/fight_view.gd").new()
	fight.name = "Fight"
	add_child(fight)
	board.shake.connect(func(a): if not Game.settings.reducedMotion: shake_amt = maxf(shake_amt, a * 0.004))
	fight.shake.connect(func(a): if not Game.settings.reducedMotion: shake_amt = maxf(shake_amt, a * 0.006))
	cam = Camera3D.new()
	cam.near = 0.1
	cam.far = 60
	add_child(cam)
	cam.make_current()
	_post()
	ui = preload("res://scripts/ui/ui.gd").new()
	ui.name = "UI"
	ui.main = self
	add_child(ui)
	Bus.phase_changed.connect(_on_phase)
	Bus.new_run.connect(func(): _on_phase(S.G.phase))
	_set_view("title", true)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			shot_path = a.substr(7)
	if shot_path != "":
		_debug_shot()

func _environment() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.02, 0.02)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.32, 0.27, 0.34)
	env.ambient_light_energy = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.05
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 1.1
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.fog_enabled = true
	env.fog_light_color = Color(0.1, 0.08, 0.1)
	env.fog_density = 0.02
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.06
	env.adjustment_saturation = 0.92
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.82, 0.62)
	sun.light_energy = 0.35
	sun.rotation_degrees = Vector3(-52, -28, 0)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 18
	add_child(sun)

func _post() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 0
	add_child(layer)
	post = ColorRect.new()
	post.set_anchors_preset(Control.PRESET_FULL_RECT)
	post.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/post.gdshader")
	m.set_shader_parameter("focus_center", 0.5)
	m.set_shader_parameter("focus_width", 0.3)
	post.material = m
	layer.add_child(post)

var view_override := {}

func _view_transform(name_: String) -> Transform3D:
	var v: Dictionary = view_override if not view_override.is_empty() else VIEWS[name_]
	var pos: Vector3 = v.pos
	var look: Vector3 = v.look
	# On tall screens pull back so the board still fits.
	var vp := get_viewport().get_visible_rect().size
	var aspect := vp.x / maxf(1.0, vp.y)
	if aspect < 1.5:
		var k := clampf((1.5 - aspect) / 0.9, 0.0, 1.0)
		var back := (pos - look).normalized()
		pos += back * k * 3.2
		if name_ == "board":
			look.x = lerpf(look.x, -1.9, k)
			pos.x = lerpf(pos.x, -1.2, k)
	return Transform3D(Basis.looking_at(look - pos, Vector3.UP), pos)

func _set_view(name_: String, instant := false) -> void:
	focus = name_
	cam_from = cam.global_transform
	cam_to = _view_transform(name_)
	cam_fov_from = cam.fov
	cam_fov_to = view_override.fov if not view_override.is_empty() else VIEWS[name_].fov
	cam_k = 1.0 if instant else 0.0
	var m := post.material as ShaderMaterial
	var center := 0.5 if name_ == "board" else 0.6
	var tw := create_tween()
	tw.tween_method(func(x): m.set_shader_parameter("focus_center", x), m.get_shader_parameter("focus_center"), center, 0.9)
	m.set_shader_parameter("focus_width", 0.34 if name_ == "board" else 0.26)
	if instant:
		cam.global_transform = cam_to
		cam.fov = cam_fov_to

func _on_phase(p: String) -> void:
	Sfx.set_mood(p == "resolve" or p == "alloc")
	match p:
		"aim", "ball", "sink":
			_set_view("board")
		"alloc", "resolve", "draft", "over":
			_set_view("fight")
		"title":
			_set_view("title")

func _process(dt: float) -> void:
	t += dt
	if cam_k < 1.0:
		cam_k = minf(1.0, cam_k + dt / 1.1)
		var e := cam_k * cam_k * (3.0 - 2.0 * cam_k)
		cam.global_transform = cam_from.interpolate_with(cam_to, e)
		cam.fov = lerpf(cam_fov_from, cam_fov_to, e)
	else:
		cam_to = _view_transform(focus)
		var base := cam_to
		# Gentle handheld drift and mouse parallax, like a diorama on a turntable.
		var vp := get_viewport().get_visible_rect().size
		var par := (mouse / vp - Vector2(0.5, 0.5)) if vp.x > 0 else Vector2.ZERO
		if Game.settings.reducedMotion:
			par = Vector2.ZERO
		var drift := Vector3(sin(t * 0.31) * 0.03, sin(t * 0.23) * 0.02, 0) + Vector3(par.x * 0.12, -par.y * 0.06, 0)
		base.origin += base.basis * drift
		cam.global_transform = base
	if shake_amt > 0.0005:
		cam.global_transform.origin += Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * shake_amt
		shake_amt = maxf(0.0, shake_amt - dt * 0.12)
	if shot_path != "":
		shot_frames += 1

# ---------- Input ----------
func _unhandled_input(e: InputEvent) -> void:
	var G := S.G
	if G.is_empty() or G.phase == "title":
		return
	if e is InputEventMouseMotion:
		mouse = e.position
		if G.phase == "aim" and (dragging or e.button_mask == 0):
			var bp = board.ray_to_board(cam, e.position)
			if bp != null and (dragging or _in_board(bp)):
				Game.board.set_aim_from(bp.x, bp.y)
		ui.hover_peg(_peg_under(e.position))
		_hover_foe(e.position)
	elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			Sfx.start()
			var f = fight.foe_at(cam, e.position)
			if f != null and G.phase != "resolve":
				G.target = f.id
				Sfx.play("ui")
				Bus.refresh.emit()
				return
			if G.phase == "aim":
				var bp2 = board.ray_to_board(cam, e.position)
				if bp2 != null and _in_board(bp2):
					dragging = true
					Game.board.set_aim_from(bp2.x, bp2.y)
		else:
			if G.phase == "sink":
				Game.board.skip_reveal()
			elif G.phase == "aim" and dragging:
				dragging = false
				var bp3 = board.ray_to_board(cam, e.position)
				if bp3 != null:
					Game.board.set_aim_from(bp3.x, bp3.y)
				Game.board.fire()
			dragging = false
	elif e is InputEventScreenTouch:
		Sfx.start()

func _in_board(bp: Vector2) -> bool:
	return bp.x > -40 and bp.x < D.PHYS.W + 40 and bp.y > -60 and bp.y < D.PHYS.H + 20

func _peg_under(screen: Vector2):
	var bp = board.ray_to_board(cam, screen)
	if bp == null:
		return null
	for p in Game.board.pegs:
		if not p.dead and p.type != "post" and Vector2(p.x, p.y).distance_to(bp) < p.r + 6:
			return p
	return null

func _hover_foe(screen: Vector2) -> void:
	var f = fight.foe_at(cam, screen)
	for u in fight.units.values():
		u.hover = false
	if f != null:
		var u2: Unit = fight.unit("foe", f.id)
		if u2:
			u2.hover = true

# ---------- Debug screenshots (used for automated visual checks) ----------
func _debug_shot() -> void:
	var mode := "board"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--mode="):
			mode = a.substr(7)
		if a.begins_with("--view="):
			var v := a.substr(7).split(",")
			view_override = {"pos": Vector3(float(v[0]), float(v[1]), float(v[2])), "look": Vector3(float(v[3]), float(v[4]), float(v[5])), "fov": float(v[6])}
	Game.new_run("SHOT")
	ui.close_all()
	await get_tree().create_timer(0.5).timeout
	if mode == "fight" or mode == "alloc" or mode == "resolve":
		S.G.balls = 0
		Game.after_ball()
	elif mode == "ball":
		Game.board.aim = 1.2
		Game.board.fire()
	elif mode == "title":
		Game.set_phase("title")
		ui.show_title()
	elif mode == "level":
		S.G.balls = 0
		S.G.bank = 400
		Game.after_ball()
		ui.open_level()
	elif mode == "gear":
		S.G.balls = 0
		for i in 6:
			S.drop_item(i % 5)
		Game.after_ball()
		ui.open_gear()
	elif mode == "draft":
		S.G.balls = 0
		Game.after_ball()
		Game.stage_cleared()
	await get_tree().create_timer(2.6 if mode != "ball" else 0.9).timeout
	if mode == "ball":
		if Game.board.ball != null:
			Game.board.sink(2)
		await get_tree().create_timer(0.8).timeout
	if mode == "resolve":
		Game.fight()
		await get_tree().create_timer(1.9).timeout
	var img := get_viewport().get_texture().get_image()
	img.save_png(shot_path)
	print("SHOT saved ", shot_path)
	get_tree().quit()
