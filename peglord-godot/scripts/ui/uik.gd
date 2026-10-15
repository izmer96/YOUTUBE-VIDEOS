class_name UIK
extends RefCounted
## UI kit: fonts, the shared theme and small widget builders, so every screen shares one look.

const GOLD := Color("#e2bd6a")
const GOLD_DIM := Color("#9c7c3c")
const INK := Color("#f2ead3")
const INK_DIM := Color("#b9ab8e")
const GOOD := Color("#7dffa6")
const BAD := Color("#ff8a7a")
const LOOT := Color("#ffcf6a")
const BLUE := Color("#9cc8ff")

static var _fonts := {}
static var _tex2x := {}
static var theme: Theme
static var root: Node          # the UI CanvasLayer, for tooltips

static func font(kind: String) -> Font:
	if _fonts.has(kind):
		return _fonts[kind]
	var path: String = {
		"title": "res://assets/fonts/cinzel-latin-900-normal.woff2",
		"head": "res://assets/fonts/cinzel-latin-700-normal.woff2",
		"body": "res://assets/fonts/alegreya-sans-latin-500-normal.woff2",
		"bold": "res://assets/fonts/alegreya-sans-latin-800-normal.woff2",
	}[kind]
	var f: FontFile = load(path)
	var sym: FontFile = load("res://assets/fonts/symbols.ttf")
	f.fallbacks = [sym]
	_fonts[kind] = f
	return f

static func tex(path: String) -> Texture2D:
	return load(path)

## Pixel frames are drawn at 2x so their gold rules stay crisp after the canvas stretch.
static func tex2x(path: String) -> Texture2D:
	if _tex2x.has(path):
		return _tex2x[path]
	var img: Image = (load(path) as Texture2D).get_image()
	img.decompress()
	img.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
	var t := ImageTexture.create_from_image(img)
	_tex2x[path] = t
	return t

static func nine(path: String, margin := 6, content := 8) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = tex2x(path)
	sb.texture_margin_left = margin * 2
	sb.texture_margin_right = margin * 2
	sb.texture_margin_top = margin * 2
	sb.texture_margin_bottom = margin * 2
	sb.content_margin_left = content
	sb.content_margin_right = content
	sb.content_margin_top = content * 0.7
	sb.content_margin_bottom = content * 0.7
	return sb

static func build_theme() -> Theme:
	if theme:
		return theme
	theme = Theme.new()
	theme.default_font = font("body")
	theme.default_font_size = 17
	theme.set_color("font_color", "Label", INK)
	theme.set_constant("outline_size", "Label", 0)
	theme.set_stylebox("panel", "PanelContainer", nine("res://assets/ui/panel.png", 7, 12))
	theme.set_stylebox("panel", "Panel", nine("res://assets/ui/panel.png", 7, 12))
	theme.set_stylebox("normal", "Button", nine("res://assets/ui/button.png", 5, 12))
	theme.set_stylebox("hover", "Button", nine("res://assets/ui/button_hover.png", 5, 12))
	theme.set_stylebox("pressed", "Button", nine("res://assets/ui/button_press.png", 5, 12))
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	var dis := nine("res://assets/ui/button_press.png", 5, 12)
	dis.modulate_color = Color(0.6, 0.6, 0.6, 0.7)
	theme.set_stylebox("disabled", "Button", dis)
	theme.set_font("font", "Button", font("bold"))
	theme.set_font_size("font_size", "Button", 17)
	theme.set_color("font_color", "Button", INK)
	theme.set_color("font_hover_color", "Button", Color("#fff6dc"))
	theme.set_color("font_pressed_color", "Button", GOLD)
	theme.set_color("font_disabled_color", "Button", Color(0.6, 0.55, 0.48))
	theme.set_stylebox("panel", "TooltipPanel", nine("res://assets/ui/panel_light.png", 7, 10))
	theme.set_color("font_color", "TooltipLabel", INK)
	theme.set_font("font", "TooltipLabel", font("body"))
	theme.set_font_size("font_size", "TooltipLabel", 16)
	var le := StyleBoxFlat.new()
	le.bg_color = Color(0.05, 0.04, 0.05, 0.9)
	le.border_color = GOLD_DIM
	le.set_border_width_all(1)
	le.content_margin_left = 8
	le.content_margin_right = 8
	theme.set_stylebox("normal", "LineEdit", le)
	theme.set_stylebox("focus", "LineEdit", le)
	theme.set_font("font", "LineEdit", font("bold"))
	var grab := StyleBoxFlat.new()
	grab.bg_color = GOLD
	grab.set_corner_radius_all(2)
	var slider := StyleBoxFlat.new()
	slider.bg_color = Color(0.2, 0.16, 0.12)
	slider.content_margin_top = 3
	slider.content_margin_bottom = 3
	theme.set_stylebox("slider", "HSlider", slider)
	theme.set_stylebox("grabber_area", "HSlider", grab)
	theme.set_stylebox("grabber_area_highlight", "HSlider", grab)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.3, 0.24, 0.16, 0.8)
	theme.set_stylebox("scroll", "VScrollBar", StyleBoxEmpty.new())
	theme.set_stylebox("grabber", "VScrollBar", sb)
	return theme

# ---------- Builders ----------
static func label(text: String, size := 17, color := INK, kind := "body", outline := 0) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font(kind))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if outline > 0:
		l.add_theme_constant_override("outline_size", outline)
		l.add_theme_color_override("font_outline_color", Color(0.06, 0.03, 0.02))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

static func rich(bb: String, size := 16) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.text = bb
	r.add_theme_font_override("normal_font", font("body"))
	r.add_theme_font_override("bold_font", font("bold"))
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_font_size_override("bold_font_size", size)
	r.add_theme_color_override("default_color", INK)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r

static func button(text: String, cb: Callable, go := false, size := 17) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", size)
	if go:
		b.add_theme_stylebox_override("normal", nine("res://assets/ui/button_go.png", 5, 16))
		b.add_theme_stylebox_override("hover", nine("res://assets/ui/button_go_hover.png", 5, 16))
		b.add_theme_font_override("font", font("head"))
	b.pressed.connect(func():
		Sfx.start()
		Sfx.play("ui")
		cb.call())
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return b

static func panel(light := false) -> PanelContainer:
	var p := PanelContainer.new()
	if light:
		p.add_theme_stylebox_override("panel", nine("res://assets/ui/panel_light.png", 7, 12))
	return p

static func icon(name: String, scale := 2) -> TextureRect:
	var t := TextureRect.new()
	var path := "res://assets/icons/%s.png" % name
	if ResourceLoader.exists(path):
		t.texture = load(path)
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.custom_minimum_size = Vector2(26, 26) * scale
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t

static func portrait(kind: String, size := 64, frame := "idle_0") -> TextureRect:
	var at := AtlasTexture.new()
	at.atlas = load("res://assets/sprites/%s/%s.png" % [kind, frame])
	at.region = Rect2(20, 14, 44, 44) if kind != "hound" and kind != "leech" else Rect2(14, 24, 52, 52)
	var t := TextureRect.new()
	t.texture = at
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.custom_minimum_size = Vector2(size, size)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t

static func full_sprite(kind: String, size := 160) -> TextureRect:
	var t := TextureRect.new()
	var at := AtlasTexture.new()
	at.atlas = load("res://assets/sprites/%s/idle_0.png" % kind)
	at.region = Rect2(12, 4, 56, 68) if kind != "hound" else Rect2(4, 20, 72, 52)
	t.texture = at
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.custom_minimum_size = Vector2(size, size)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t

static func hbox(sep := 8) -> HBoxContainer:
	var b := HBoxContainer.new()
	b.add_theme_constant_override("separation", sep)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b

static func vbox(sep := 6) -> VBoxContainer:
	var b := VBoxContainer.new()
	b.add_theme_constant_override("separation", sep)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b

static func spacer(w := 0, h := 0) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(w, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if w == 0 and h == 0:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c

static func header(text: String, size := 24) -> HBoxContainer:
	var h := hbox(10)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	var d1 := TextureRect.new()
	d1.texture = load("res://assets/ui/diamond.png")
	d1.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	d1.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	var d2 := d1.duplicate()
	h.add_child(d1)
	h.add_child(label(text, size, GOLD, "head"))
	h.add_child(d2)
	return h

static func clear(n: Node) -> void:
	for c in n.get_children():
		n.remove_child(c)
		c.queue_free()

## A thin HP-style bar drawn with two ColorRects.
static func bar(value: float, maxv: float, w: float, h: float, col: Color, back := Color(0.08, 0.05, 0.05, 0.9), shield := 0.0) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(w, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := ColorRect.new()
	bg.color = back
	bg.size = Vector2(w, h)
	c.add_child(bg)
	var fg := ColorRect.new()
	fg.color = col
	fg.size = Vector2(maxf(0.0, w * clampf(value / maxf(1.0, maxv), 0.0, 1.0)), h)
	c.add_child(fg)
	var hi := ColorRect.new()
	hi.color = Color(1, 1, 1, 0.18)
	hi.size = Vector2(fg.size.x, maxf(1.0, h * 0.3))
	c.add_child(hi)
	if shield > 0:
		var sh := ColorRect.new()
		sh.color = Color(0.6, 0.8, 1.0, 0.85)
		sh.size = Vector2(minf(w, w * shield / maxf(1.0, maxv)), maxf(2.0, h * 0.35))
		sh.position = Vector2(0, h - sh.size.y)
		c.add_child(sh)
	return c

static func hp_color(frac: float) -> Color:
	if frac > 0.5:
		return Color("#5fd16b")
	if frac > 0.25:
		return Color("#e8c547")
	return Color("#e0513c")

static func rarity_color(idx: int) -> Color:
	return Color(D.RARITIES[idx].color)

## Hover tooltip: `build` returns the Control shown in the shared tooltip panel.
static func tip(c: Control, build: Callable) -> void:
	if c.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		c.mouse_filter = Control.MOUSE_FILTER_PASS
	c.mouse_entered.connect(func(): if root: root.show_tip(build.call()))
	c.mouse_exited.connect(func(): if root: root.hide_tip())

static func text_tip(title: String, body: String, col := GOLD) -> Control:
	var v := vbox(4)
	v.add_child(label(title, 19, col, "head"))
	if body != "":
		var r := rich(body, 15)
		r.custom_minimum_size.x = 280
		v.add_child(r)
	return v

static func sep(w := 0.0) -> Control:
	var c := ColorRect.new()
	c.color = Color(GOLD_DIM, 0.6)
	c.custom_minimum_size = Vector2(w, 1)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

static func esc(t: String) -> String:
	return t.replace("[", "[lb]")

## Diablo-style item card: name, type line, stats, requirements and a compare block.
static func item_tip(it: Dictionary, h = null) -> Control:
	var v := vbox(3)
	v.custom_minimum_size.x = 300
	var rc := rarity_color(it.rarity)
	v.add_child(label(it.name + ((" +%d" % it.upg) if it.get("upg", 0) else ""), 20, rc, "head"))
	var kind: String = D.SLOT_NAMES[it.slot]
	if it.has("family"):
		kind = D.WEAPONS[it.family].name
	elif it.has("offType"):
		kind = D.OFFHANDS[it.offType].name
	v.add_child(label("%s %s · item level %d" % [D.RARITIES[it.rarity].name, kind, it.L], 14, INK_DIM))
	v.add_child(sep())
	var bb := ""
	for line in S.item_summary(it):
		var l: String = line
		var col := "#f2ead3"
		if l.begins_with("★"):
			col = "#ffa04a"
		elif l.begins_with("Needs"):
			col = "#b9ab8e"
		elif it.has("set") and l.begins_with(D.SETS[it.set].name):
			col = "#7dffa6"
		elif l.begins_with("+") or l.begins_with("Heal ") or l.begins_with("Reflect") or l.begins_with("Skill"):
			col = "#9cc8ff"
		bb += "[color=%s]%s[/color]\n" % [col, esc(l)]
	var r := rich(bb.strip_edges(), 15)
	r.custom_minimum_size.x = 300
	v.add_child(r)
	if h != null:
		var hh: Dictionary = h
		var attrs := S.total_attrs(hh)
		var warn := ""
		if it.slot == "weapon":
			var wa := S.weapon_ar(hh, it, attrs)
			if not wa.short.is_empty():
				warn = "%s lacks the stats: reduced damage" % hh.name
		elif it.has("reqAttr"):
			if not S.armor_value(it, attrs).ok:
				warn = "%s lacks the stats: half value" % hh.name
		if warn != "":
			v.add_child(label(warn, 14, BAD))
		var eq = hh.gear[it.slot]
		if eq == null or eq.id != it.id:
			var deltas := compare(hh, it)
			v.add_child(sep())
			v.add_child(label("If %s equips it:" % hh.name, 14, INK_DIM))
			if deltas.is_empty():
				v.add_child(label("No stat change", 15, INK_DIM))
			else:
				var hb := HFlowContainer.new()
				hb.add_theme_constant_override("h_separation", 12)
				for d in deltas:
					var dv: int = d[1]
					hb.add_child(label("%s %s%d" % [d[0], "+" if dv > 0 else "", dv], 15, GOOD if dv > 0 else BAD, "bold"))
				v.add_child(hb)
	return v

## Stat deltas if `h` equipped `it`: [[label, delta], ...]
static func compare(h: Dictionary, it: Dictionary) -> Array:
	var before := S.hero_stats(h)
	var old = h.gear[it.slot]
	h.gear[it.slot] = it
	var after := S.hero_stats(h)
	h.gear[it.slot] = old
	var out := []
	for k in [["ar", "AR"], ["maxHp", "HP"], ["def", "Def"], ["res", "Res"], ["crit", "Crit"], ["mendAmount", "Mend"]]:
		var dv: int = int(after[k[0]]) - int(before[k[0]])
		if dv != 0:
			out.append([k[1], dv])
	return out

static func item_icon(it, size := 56) -> Control:
	var c := PanelContainer.new()
	c.custom_minimum_size = Vector2(size, size)
	var sb := nine("res://assets/ui/slot.png", 5, 4)
	c.add_theme_stylebox_override("panel", sb)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if it == null:
		return c
	var rc := rarity_color(it.rarity)
	var glow := ColorRect.new()
	glow.color = Color(rc, 0.22)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(glow)
	var ic := icon("slot_" + it.slot, 1)
	ic.custom_minimum_size = Vector2(size - 14, size - 14)
	c.add_child(ic)
	var border := ReferenceRect.new()
	border.border_color = rc
	border.border_width = 2
	border.editor_only = false
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(border)
	if it.get("locked", false):
		var lk := icon("ui_lock", 1)
		lk.custom_minimum_size = Vector2(14, 14)
		lk.size_flags_horizontal = Control.SIZE_SHRINK_END
		lk.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		c.add_child(lk)
	return c
