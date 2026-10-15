extends PanelContainer
## Equipment screen in the Diablo mould: a paper doll with nine slots around the hero, the shared pack
## as a grid, item cards with compare-on-hover, and equip / salvage / lock actions.

var ui
var hero_idx := -1
var sel_id := -1
var scroll_y := 0

const SLOT_POS := {
	"helm": Vector2(16, 8), "chest": Vector2(16, 104), "legs": Vector2(16, 200), "boots": Vector2(16, 296),
	"weapon": Vector2(416, 8), "offhand": Vector2(416, 104), "gloves": Vector2(416, 200),
	"amulet": Vector2(178, 330), "ring": Vector2(254, 330),
}
const SLOT_SIZE := 66.0

func _ready() -> void:
	custom_minimum_size = Vector2(1180, 0)
	refresh()

func _find(id: int):
	var G := S.G
	for it in G.pack:
		if it.id == id:
			return it
	for s in D.SLOTS:
		var e = G.heroes[hero_idx].gear[s]
		if e != null and e.id == id:
			return e
	return null

func refresh() -> void:
	var G := S.G
	if hero_idx < 0:
		hero_idx = G.selHero
	var h: Dictionary = G.heroes[hero_idx]
	var old_scroll := get_node_or_null("V/Body/Pack/Scroll")
	if old_scroll:
		scroll_y = (old_scroll as ScrollContainer).scroll_vertical
	UIK.clear(self)
	var v := UIK.vbox(10)
	v.name = "V"
	add_child(v)
	var head := UIK.hbox(14)
	v.add_child(head)
	var tv := UIK.vbox(0)
	head.add_child(tv)
	tv.add_child(UIK.label("EQUIPMENT", 30, UIK.GOLD, "title", 4))
	tv.add_child(UIK.label("Click an item to inspect  ·  double-click to equip", 14, UIK.INK_DIM))
	head.add_child(UIK.spacer())
	for i in G.heroes.size():
		head.add_child(_tab(G.heroes[i], i))
	head.add_child(UIK.spacer())
	var done := UIK.button("Done", func(): ui._close_modal(), true, 20)
	done.custom_minimum_size = Vector2(140, 48)
	head.add_child(done)
	v.add_child(UIK.sep())
	var body := UIK.hbox(16)
	body.name = "Body"
	v.add_child(body)
	body.add_child(_doll(h))
	body.add_child(_pack(h))
	if not Game.can_manage():
		v.add_child(UIK.label("Gear can be changed after the balls are dropped, before the fight. You can still look.", 15, UIK.INK_DIM))

func _tab(h: Dictionary, i: int) -> Control:
	var sel := i == hero_idx
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(150, 56)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if sel:
		b.add_theme_stylebox_override("normal", UIK.nine("res://assets/ui/button_hover.png", 5, 8))
	var row := UIK.hbox(6)
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 6
	b.add_child(row)
	row.add_child(UIK.portrait(h.cls, 44))
	var nv := UIK.vbox(-2)
	nv.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(nv)
	nv.add_child(UIK.label(h.name, 16, Color(D.HEROES[h.cls].color) if sel else UIK.INK, "bold"))
	nv.add_child(UIK.label("Level %d" % h.level, 14, UIK.GOLD if sel else UIK.INK_DIM))
	b.pressed.connect(func():
		Sfx.play("ui")
		hero_idx = i
		S.G.selHero = i
		refresh())
	return b

func _doll(h: Dictionary) -> Control:
	var col := UIK.vbox(8)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UIK.nine("res://assets/ui/slot.png", 5, 6))
	col.add_child(frame)
	var area := Control.new()
	area.custom_minimum_size = Vector2(500, 420)
	area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(area)
	var glow := TextureRect.new()
	var g := Gradient.new()
	g.set_color(0, Color(Color(D.HEROES[h.cls].color).darkened(0.55), 0.9))
	g.set_color(1, Color(0, 0, 0, 0))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(0.5, 0.0)
	glow.texture = gt
	glow.position = Vector2(110, 20)
	glow.size = Vector2(280, 300)
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	area.add_child(glow)
	var spr := UIK.full_sprite(h.cls, 300)
	spr.position = Vector2(100, 0)
	spr.size = Vector2(300, 300)
	area.add_child(spr)
	var nm := UIK.label("%s  ·  Level %d" % [h.name, h.level], 18, Color(D.HEROES[h.cls].color), "head", 4)
	nm.position = Vector2(100, 296)
	nm.size = Vector2(300, 24)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	area.add_child(nm)
	for s in D.SLOTS:
		var it = h.gear[s]
		var slot := _item_cell(it, h, true, s)
		slot.position = SLOT_POS[s]
		area.add_child(slot)
		var lbl := UIK.label(D.SLOT_NAMES[s], 11, UIK.INK_DIM, "head")
		lbl.position = SLOT_POS[s] + Vector2(0, SLOT_SIZE + 1)
		lbl.size = Vector2(SLOT_SIZE, 14)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		area.add_child(lbl)
	# Summary line and set bonuses.
	var st := S.hero_stats(h)
	var sum := UIK.hbox(14)
	col.add_child(sum)
	for p in [["ui_hp", "%d HP" % st.maxHp], ["ui_attack", "AR %d" % st.ar], ["ui_guard", "Def %d" % st.def], ["ui_sparkle", "Res %d" % st.res], ["ui_star", "Crit %d%%" % st.crit]]:
		var r := UIK.hbox(3)
		var ic := UIK.icon(p[0], 1)
		ic.custom_minimum_size = Vector2(18, 18)
		r.add_child(ic)
		r.add_child(UIK.label(p[1], 16, UIK.INK, "bold"))
		sum.add_child(r)
	for sid in D.SETS:
		var n := S.set_count(h, sid)
		if n > 0:
			var SD: Dictionary = D.SETS[sid]
			var r2 := UIK.rich("[color=#7dffa6]%s %d/5[/color]  [color=%s]2: %s[/color]  [color=%s]4: %s[/color]" % [SD.name, n,
				"#f2ead3" if n >= 2 else "#6b6253", SD.two, "#f2ead3" if n >= 4 else "#6b6253", SD.four], 14)
			r2.custom_minimum_size.x = 500
			col.add_child(r2)
	return col

func _item_cell(it, h: Dictionary, equipped: bool, slot := "") -> Control:
	var c := UIK.item_icon(it, int(SLOT_SIZE))
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	c.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if it != null else Control.CURSOR_ARROW
	if it == null:
		var ghost := UIK.icon("slot_" + slot, 1)
		ghost.modulate = Color(1, 1, 1, 0.18)
		ghost.custom_minimum_size = Vector2(SLOT_SIZE - 18, SLOT_SIZE - 18)
		c.add_child(ghost)
		return c
	if it.id == sel_id:
		var hl := ReferenceRect.new()
		hl.border_color = Color.WHITE
		hl.border_width = 2
		hl.editor_only = false
		hl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.add_child(hl)
	UIK.tip(c, func(): return UIK.item_tip(it, null if equipped else h))
	c.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			Sfx.start()
			if e.double_click:
				sel_id = -1
				if equipped:
					Game.unequip(h, it.slot)
				else:
					Game.equip(h, it)
			else:
				Sfx.play("ui")
				sel_id = it.id
				refresh())
	return c

func _pack(h: Dictionary) -> Control:
	var G := S.G
	var col := UIK.vbox(8)
	col.name = "Pack"
	col.custom_minimum_size.x = 610
	var head := UIK.hbox(8)
	col.add_child(head)
	head.add_child(UIK.icon("ui_pack", 1))
	head.add_child(UIK.label("PACK", 20, UIK.GOLD, "head"))
	head.add_child(UIK.label("%d item%s, shared by the party" % [G.pack.size(), "" if G.pack.size() == 1 else "s"], 14, UIK.INK_DIM))
	var sc := ScrollContainer.new()
	sc.name = "Scroll"
	sc.custom_minimum_size = Vector2(610, 228)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(sc)
	var grid := GridContainer.new()
	grid.columns = 8
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	sc.add_child(grid)
	var items: Array = G.pack.duplicate()
	items.sort_custom(func(a, b): return a.rarity > b.rarity if a.rarity != b.rarity else D.SLOTS.find(a.slot) < D.SLOTS.find(b.slot))
	for it in items:
		grid.add_child(_item_cell(it, h, false))
	for i in maxi(0, 24 - items.size()):
		var e := UIK.item_icon(null, int(SLOT_SIZE))
		e.modulate.a = 0.45
		grid.add_child(e)
	sc.set_deferred("scroll_vertical", scroll_y)
	# Details of the selected item.
	var det := UIK.panel()
	det.custom_minimum_size = Vector2(610, 190)
	col.add_child(det)
	var it = _find(sel_id) if sel_id >= 0 else null
	if it == null:
		var hint := UIK.label("Select an item. Hover any item to compare it with what %s wears." % h.name, 15, UIK.INK_DIM)
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		det.add_child(hint)
		return col
	var row := UIK.hbox(12)
	det.add_child(row)
	var equipped: bool = G.pack.find(it) < 0
	row.add_child(UIK.item_tip(it, null if equipped else h))
	row.add_child(UIK.spacer())
	var acts := UIK.vbox(6)
	acts.custom_minimum_size.x = 210
	row.add_child(acts)
	var can := Game.can_manage()
	if equipped:
		var ub := UIK.button("Unequip", func():
			sel_id = -1
			Game.unequip(h, it.slot))
		ub.disabled = not can
		acts.add_child(ub)
	else:
		var eb := UIK.button("Equip on %s" % h.name, func():
			sel_id = -1
			Game.equip(h, it), true)
		eb.disabled = not can
		acts.add_child(eb)
		var sb := UIK.button("Salvage  +%d XP" % Game.salvage_value(it), func():
			sel_id = -1
			Game.salvage(it))
		sb.icon = load("res://assets/icons/ui_salvage.png")
		sb.add_theme_constant_override("icon_max_width", 18)
		sb.disabled = not can or it.locked
		acts.add_child(sb)
		var lb := UIK.button("Unlock" if it.locked else "Lock", func():
			it.locked = not it.locked
			Sfx.play("ui")
			refresh())
		lb.icon = load("res://assets/icons/ui_lock.png")
		lb.add_theme_constant_override("icon_max_width", 18)
		acts.add_child(lb)
		UIK.tip(lb, func(): return UIK.label("Locked items can't be salvaged.", 15))
	return col
