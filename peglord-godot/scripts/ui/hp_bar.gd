class_name HpBar
extends Control
## HP bar with a pale "damage trail" that drains after a hit, and a shield strip.

var value := 1.0
var maxv := 1.0
var shield := 0.0
var trail := 1.0
var fixed_color := Color(0, 0, 0, 0)

func _init(w := 120.0, h := 10.0) -> void:
	custom_minimum_size = Vector2(w, h)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_hp(v: float, m: float, sh := 0.0) -> void:
	var f := clampf(v / maxf(1.0, m), 0.0, 1.0)
	if f > trail:
		trail = f
	value = v
	maxv = maxf(1.0, m)
	shield = sh
	queue_redraw()

func _process(dt: float) -> void:
	var f := clampf(value / maxv, 0.0, 1.0)
	if trail > f:
		trail = maxf(f, trail - dt * 0.5)
		queue_redraw()

func _draw() -> void:
	var f := clampf(value / maxv, 0.0, 1.0)
	var w := size.x - 2
	var h := size.y - 2
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.03, 0.03, 0.92))
	draw_rect(Rect2(1, 1, w * trail, h), Color(1.0, 0.92, 0.75, 0.85))
	var c := fixed_color if fixed_color.a > 0 else UIK.hp_color(f)
	draw_rect(Rect2(1, 1, w * f, h), c)
	draw_rect(Rect2(1, 1, w * f, maxf(1.0, h * 0.35)), Color(1, 1, 1, 0.22))
	if shield > 0:
		var sw := minf(w, w * shield / maxv)
		draw_rect(Rect2(1, size.y - 1 - maxf(2.0, h * 0.4), sw, maxf(2.0, h * 0.4)), Color(0.62, 0.82, 1.0, 0.95))
	draw_rect(Rect2(Vector2.ZERO, size), Color(UIK.GOLD_DIM, 0.9), false, 1.0)
