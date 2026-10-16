class_name Unit
extends Node3D
## One HD-2D character on the fight floor: a camera-facing pixel sprite with simple frame animation.

const PX := 0.024            # metres per sprite pixel
const FRAME := 80
const FEET_ROW := 70
const ANIMS := {"idle": 4, "attack": 6, "hurt": 3, "cast": 4, "dead": 1}
const FPS := {"idle": 5.0, "attack": 14.0, "hurt": 10.0, "cast": 8.0, "dead": 1.0}

static var _frames_cache := {}

var kind := ""               # sprite folder name
var side := "hero"
var uid := -1
var home := Vector3.ZERO
var mat: ShaderMaterial
var quad: MeshInstance3D
var shadow: MeshInstance3D
var frames := {}
var anim := "idle"
var frame_t := 0.0
var frame_i := 0
var dead := false
var big := 1.0
var hover := false
var target := false
var flash_t := 0.0
var bob := 0.0

static var _top_cache := {}

## Highest opaque row of the idle frame, so name plates sit right above each sprite's head.
static func top_row(k: String) -> int:
	if _top_cache.has(k):
		return _top_cache[k]
	var img: Image = (load("res://assets/sprites/%s/idle_0.png" % k) as Texture2D).get_image()
	img.decompress()
	var top := FEET_ROW - 50
	for y in img.get_height():
		var hit := false
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.5:
				hit = true
				break
		if hit:
			top = y
			break
	_top_cache[k] = top
	return top

static func load_frames(k: String) -> Dictionary:
	if _frames_cache.has(k):
		return _frames_cache[k]
	var out := {}
	for a in ANIMS:
		var arr := []
		for i in ANIMS[a]:
			arr.append(load("res://assets/sprites/%s/%s_%d.png" % [k, a, i]))
		out[a] = arr
	_frames_cache[k] = out
	return out

func setup(k: String, s: String, id: int, pos: Vector3, scale_ := 1.0) -> void:
	kind = k
	side = s
	uid = id
	home = pos
	big = scale_
	position = pos
	frames = load_frames(k)
	mat = ShaderMaterial.new()
	mat.shader = load("res://shaders/unit.gdshader")
	mat.set_shader_parameter("flip", 1.0 if s == "foe" else 0.0)
	mat.set_shader_parameter("texel", Vector2(1.0 / FRAME, 1.0 / FRAME))
	quad = MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(FRAME * PX, FRAME * PX) * big
	quad.mesh = qm
	quad.material_override = mat
	quad.position = Vector3(0, (FRAME / 2.0 - (FRAME - FEET_ROW)) * PX * big, 0)
	quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(quad)
	shadow = MeshInstance3D.new()
	var sm := QuadMesh.new()
	sm.size = Vector2(0.9, 0.42) * big
	shadow.mesh = sm
	var shm := ShaderMaterial.new()
	shm.shader = load("res://shaders/blob.gdshader")
	shadow.material_override = shm
	shadow.rotation_degrees = Vector3(-90, 0, 0)
	shadow.position = Vector3(0.05, 0.025, 0)
	add_child(shadow)
	_set_frame()

func head_global() -> Vector3:
	return global_position + Vector3(0, (FEET_ROW - top_row(kind)) * PX * big, 0)

func body_global() -> Vector3:
	return global_position + Vector3(0, (FEET_ROW - top_row(kind)) * PX * big * 0.5, 0)

func play(a: String) -> void:
	if dead and a != "dead":
		return
	anim = a
	frame_i = 0
	frame_t = 0.0
	_set_frame()

func _set_frame() -> void:
	var arr: Array = frames.get(anim, frames.idle)
	mat.set_shader_parameter("frame", arr[mini(frame_i, arr.size() - 1)])

func flash() -> void:
	flash_t = 0.18

func set_dead(v: bool, instant := false) -> void:
	if v == dead:
		return
	dead = v
	if v:
		anim = "dead"
		frame_i = 0
		_set_frame()
		if side == "foe":
			var tw := create_tween()
			tw.tween_interval(0.0 if instant else 0.5)
			tw.tween_method(func(x): mat.set_shader_parameter("dissolve", x), 0.0, 1.0, 0.01 if instant else 0.9)
			tw.tween_callback(func(): visible = false)
		else:
			mat.set_shader_parameter("tint", Color(0.6, 0.6, 0.7))
	else:
		visible = true
		mat.set_shader_parameter("dissolve", 0.0)
		mat.set_shader_parameter("tint", Color.WHITE)
		play("idle")

func lunge(to: Vector3) -> void:
	play("attack")
	var dir := (to - home)
	dir.y = 0
	var dest := home + dir * 0.55
	var tw := create_tween()
	tw.tween_property(self, "position", dest, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.14)
	tw.tween_property(self, "position", home, 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

func knockback() -> void:
	play("hurt")
	flash()
	var away := Vector3(-0.18 if side == "hero" else 0.18, 0, 0)
	var tw := create_tween()
	tw.tween_property(self, "position", home + away, 0.06)
	tw.tween_property(self, "position", home, 0.22).set_trans(Tween.TRANS_QUAD)

func _process(dt: float) -> void:
	frame_t += dt
	var fps: float = FPS[anim]
	var n: int = ANIMS[anim]
	if frame_t >= 1.0 / fps:
		frame_t = 0.0
		frame_i += 1
		if frame_i >= n:
			if anim == "idle":
				frame_i = 0
			elif anim == "dead":
				frame_i = 0
			else:
				anim = "idle"
				frame_i = 0
		_set_frame()
	if flash_t > 0:
		flash_t -= dt
	mat.set_shader_parameter("flash", 1.0 if flash_t > 0.09 else (0.5 if flash_t > 0 else 0.0))
	var g := 0.0
	if target:
		g = 0.65 + 0.35 * sin(Time.get_ticks_msec() / 160.0)
	elif hover:
		g = 0.5
	mat.set_shader_parameter("glow", g)
	mat.set_shader_parameter("glow_color", Color(1.0, 0.35, 0.25) if target else Color(1.0, 0.9, 0.5))
