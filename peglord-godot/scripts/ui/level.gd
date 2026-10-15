extends PanelContainer
## Level Up screen in the Elden Ring mould: attributes on the left, base stats with before → after on the right,
## a description strip for whatever is hovered and the hero's perk track along the bottom.

var ui
var hero_idx := -1
var desc: RichTextLabel

const UP := Color("#8fc4ff")
const DOWN := Color("#ff8a7a")

func _ready() -> void:
	custom_minimum_size = Vector2(1140, 0)
	refresh()

func _before(h: Dictionary) -> Dictionary:
	var c: Dictionary = h.duplicate(true)
	for p in S.G.pending:
		if p.hid == h.id:
			c.bought[p.attr] -= 1
			c.level -= 1
	return c

func refresh() -> void:
	var G := S.G
	if hero_idx < 0:
		hero_idx = G.selHero
	var h: Dictionary = G.heroes[hero_idx]
	var b4 := _before(h)
	var st0 := S.hero_stats(b4)
	var st1 := S.hero_stats(h)
	var can := Game.can_manage()
	UIK.clear(self)
	var v := UIK.vbox(6)
	add_child(v)
	# Header: title, hero tabs, XP held.
	var head := UIK.hbox(14)
	v.add_child(head)
	var tv := UIK.vbox(0)
	head.add_child(tv)
	tv.add_child(UIK.label("LEVEL UP", 30, UIK.GOLD, "title", 4))
	tv.add_child(UIK.label("99 XP per level  ·  shift-click + buys 5", 14, UIK.INK_DIM))
	head.add_child(UIK.spacer())
	for i in G.heroes.size():
		head.add_child(_tab(G.heroes[i], i))
	head.add_child(UIK.spacer())
	var xp := UIK.panel()
	head.add_child(xp)
	var xv := UIK.vbox(0)
	xp.add_child(xv)
	xv.add_child(UIK.label("XP HELD", 13, UIK.INK_DIM, "head"))
	var xr := UIK.hbox(6)
	xv.add_child(xr)
	xr.add_child(UIK.icon("ui_xp", 1))
	xr.add_child(UIK.label(str(G.bank), 30, UIK.LOOT, "head", 4))
	var lv: int = int(G.bank / D.LEVEL_COST)
	xv.add_child(UIK.label("%d level%s affordable" % [lv, "" if lv == 1 else "s"], 13, UIK.GOOD if lv > 0 else UIK.INK_DIM))
	v.add_child(UIK.sep())
	# Body.
	var body := UIK.hbox(18)
	v.add_child(body)
	body.add_child(_portrait_col(h))
	body.add_child(_attr_col(h, b4, st0, st1, can))
	body.add_child(_stats_col(h, b4, st0, st1))
	# Description strip.
	var dp := UIK.panel()
	v.add_child(dp)
	desc = UIK.rich("", 16)
	desc.custom_minimum_size = Vector2(1080, 22)
	dp.add_child(desc)
	_describe("Hover an attribute or stat to see what it does. [color=#8fc4ff]Blue[/color] values change when you confirm.")
	# Perk track.
	v.add_child(_perk_track(h))
	# Footer.
	var foot := UIK.hbox(10)
	v.add_child(foot)
	if not can:
		foot.add_child(UIK.label("Levels are bought after the balls are dropped, before the fight.", 15, UIK.INK_DIM))
	foot.add_child(UIK.spacer())
	var undo := UIK.button("Undo this hero", func():
		for a in D.ATTRS:
			while Game.pending_for(h, a) > 0:
				Game.refund_level(h, a))
	undo.disabled = not can or b4.level == h.level
	foot.add_child(undo)
	var auto := UIK.button("Auto-level party", func(): Game.auto_level())
	auto.disabled = not can or G.bank < D.LEVEL_COST
	foot.add_child(auto)
	UIK.tip(auto, func(): return UIK.label("Spends all XP, lowest-level hero first, on each class's main stat.", 15))
	var done := UIK.button("Done", func(): ui._close_modal(), true, 20)
	done.custom_minimum_size.x = 160
	foot.add_child(done)

func _describe(bb: String) -> void:
	if desc:
		desc.text = bb

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

func _portrait_col(h: Dictionary) -> Control:
	var c := UIK.vbox(6)
	c.custom_minimum_size.x = 250
	c.add_theme_constant_override("separation", 3)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UIK.nine("res://assets/ui/slot.png", 5, 6))
	c.add_child(frame)
	var bg := ColorRect.new()
	bg.color = Color(D.HEROES[h.cls].color).darkened(0.82)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(bg)
	var spr := UIK.full_sprite(h.cls, 190)
	if h.dead:
		spr.modulate = Color(0.5, 0.45, 0.45)
	frame.add_child(spr)
	var def: Dictionary = D.HEROES[h.cls]
	c.add_child(UIK.label("%s, %s" % [def.name, def.title], 20, Color(def.color), "head"))
	var r := UIK.rich("[color=#e2bd6a]Passive[/color]  %s\n[color=#e2bd6a]Skill[/color]  %s: %s (cooldown %d)" % [def.passive, def.skill.name, def.skill.text, S.hero_stats(h).cd], 14)
	r.custom_minimum_size.x = 250
	c.add_child(r)
	return c

func _attr_col(h: Dictionary, b4: Dictionary, st0: Dictionary, st1: Dictionary, can: bool) -> Control:
	var c := UIK.vbox(4)
	c.custom_minimum_size.x = 400
	c.add_child(UIK.header("Attributes", 20))
	var lvrow := _row("Level", str(b4.level), str(h.level), h.level > b4.level)
	c.add_child(lvrow)
	c.add_child(UIK.sep())
	var w = h.gear.weapon
	for a in D.ATTRS:
		var row := UIK.hbox(6)
		row.mouse_filter = Control.MOUSE_FILTER_PASS
		row.custom_minimum_size.y = 33
		c.add_child(row)
		var nm := UIK.label(D.ATTR_NAMES[a], 18, UIK.INK, "bold")
		nm.custom_minimum_size.x = 120
		row.add_child(nm)
		var grade := ""
		if w != null and w.grades.has(a):
			grade = w.grades[a]
		var gl := UIK.label(grade, 14, UIK.GOLD, "head")
		gl.custom_minimum_size.x = 18
		row.add_child(gl)
		row.add_child(UIK.spacer())
		var v0: int = st0.attrs[a]
		var v1: int = st1.attrs[a]
		row.add_child(_val(str(v0), 20, UIK.INK_DIM, 40))
		row.add_child(UIK.label("→", 16, UIK.INK_DIM))
		row.add_child(_val(str(v1), 22, UP if v1 > v0 else UIK.INK, 40))
		var minus := UIK.button("−", func(): Game.refund_level(h, a), false, 20)
		minus.custom_minimum_size = Vector2(36, 30)
		minus.disabled = not can or Game.pending_for(h, a) == 0
		row.add_child(minus)
		var plus := UIK.button("+", func(): Game.buy_level(h, a, 5 if Input.is_key_pressed(KEY_SHIFT) else 1), false, 20)
		plus.custom_minimum_size = Vector2(36, 30)
		plus.disabled = not can or S.G.bank < D.LEVEL_COST or h.level >= D.LEVEL_CAP
		row.add_child(plus)
		var help: String = D.ATTR_HELP[a]
		var cap := ""
		if v1 >= D.SOFT_CAP_1:
			cap = " [color=#ff8a7a]Past %d each point counts less (soft cap).[/color]" % D.SOFT_CAP_1
		var gtxt := (" Your weapon scales with it at grade [b]%s[/b]." % grade) if grade != "" else ""
		var txt := "[b]%s[/b]  %s%s%s" % [D.ATTR_NAMES[a], help, gtxt, cap]
		for n in [row, minus, plus]:
			n.mouse_entered.connect(func(): _describe(txt))
	return c

func _stats_col(h: Dictionary, b4: Dictionary, st0: Dictionary, st1: Dictionary) -> Control:
	var c := UIK.vbox(4)
	c.custom_minimum_size.x = 400
	c.add_child(UIK.header("Base Stats", 20))
	var rows := [
		["HP", "maxHp", "Maximum hit points. Vigor, armour and HP affixes raise it."],
		["Attack rating", "ar", "Damage of a basic Attack before foe armour. Comes from the weapon's base and its attribute grades."],
		["Defense", "def", "Subtracted from every physical hit."],
		["Resist", "res", "Subtracted from every magic hit."],
		["Crit chance", "crit", "Chance for a hit to deal double. Dexterity +1%, Arcane +0.5%, capped at 75%."],
		["Skill cooldown", "cd", "Rounds between uses of the class skill."],
	]
	if h.cls == "priest":
		rows.append(["Mend heals", "mendAmount", "Mend heals the weakest ally this much."])
		rows.append(["Blessing", "blessing", "Every ally attack deals this much extra while the Priest stands."])
	else:
		rows.append(["Heal power", "heal", "Multiplies healing done by this hero."])
	for r in rows:
		var k: String = r[1]
		var a0 = st0[k]
		var a1 = st1[k]
		var s0 := str(a0)
		var s1 := str(a1)
		if k == "crit":
			s0 += "%"
			s1 += "%"
		if k == "heal":
			s0 = "%d%%" % roundi(a0 * 100)
			s1 = "%d%%" % roundi(a1 * 100)
		var better: bool = (a1 < a0) if k == "cd" else (a1 > a0)
		var worse: bool = (a1 > a0) if k == "cd" else (a1 < a0)
		var row := _row(r[0], s0, s1, better, worse)
		var help: String = r[2]
		var nm: String = r[0]
		row.mouse_entered.connect(func(): _describe("[b]%s[/b]  %s" % [nm, help]))
		c.add_child(row)
	c.add_child(UIK.sep())
	var w = h.gear.weapon
	var wa: Dictionary = st1.weapon
	var line := ""
	if w == null:
		line = "Bare fists: base 3, Strength D."
	else:
		var parts := []
		for p in wa.parts:
			parts.append("%s %s +%d" % [D.ATTR_NAMES[p.attr].substr(0, 3), p.grade, roundi(p.bonus)])
		line = "[color=%s]%s[/color]%s\nBase %s  ·  %s%s" % [D.RARITIES[w.rarity].color, UIK.esc(w.name), (" +%d" % w.upg) if w.upg else "",
			str(w.base), ",  ".join(parts), "  ·  favoured +10%" if wa.fav > 0 else ""]
		if not wa.short.is_empty():
			var need := []
			for s in wa.short:
				need.append("%s %d (have %d)" % [D.ATTR_NAMES[s.attr], s.need, s.have])
			line += "\n[color=#ff8a7a]Needs %s: AR −40%%[/color]" % ", ".join(need)
	var wr := UIK.rich(line, 14)
	wr.custom_minimum_size.x = 400
	c.add_child(wr)
	return c

func _row(name_: String, a: String, b: String, better := false, worse := false) -> HBoxContainer:
	var row := UIK.hbox(6)
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	row.custom_minimum_size.y = 28
	row.add_child(UIK.label(name_, 17, UIK.INK, "bold"))
	row.add_child(UIK.spacer())
	row.add_child(_val(a, 18, UIK.INK_DIM, 56))
	row.add_child(UIK.label("→", 16, UIK.INK_DIM))
	row.add_child(_val(b, 20, UP if better else (DOWN if worse else UIK.INK), 56))
	return row

func _val(text: String, size: int, col: Color, w: float) -> Label:
	var l := UIK.label(text, size, col, "head")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l.custom_minimum_size.x = w
	return l

func _perk_track(h: Dictionary) -> Control:
	var p := UIK.panel()
	var v := UIK.vbox(3)
	p.add_child(v)
	var head := UIK.hbox(8)
	v.add_child(head)
	head.add_child(UIK.label("PERK TRACK", 15, UIK.GOLD, "head"))
	var nxt := -1
	for L in D.PERK_LEVELS:
		if h.level < L:
			nxt = L
			break
	head.add_child(UIK.label(("Next perk at level %d (%d to go)" % [nxt, nxt - h.level]) if nxt > 0 else "Every perk unlocked", 14, UIK.INK_DIM))
	var row := UIK.hbox(10)
	v.add_child(row)
	var perks: Dictionary = D.HEROES[h.cls].perks
	for L in D.PERK_LEVELS:
		var got: bool = h.level >= L
		var col := UIK.vbox(3)
		col.custom_minimum_size.x = 262
		row.add_child(col)
		var top := UIK.hbox(6)
		col.add_child(top)
		var dm := TextureRect.new()
		dm.texture = UIK.tex2x("res://assets/ui/diamond.png")
		dm.modulate = Color.WHITE if got else Color(0.35, 0.32, 0.3)
		dm.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		top.add_child(dm)
		top.add_child(UIK.label("Level %d" % L, 16, UIK.GOLD if got else UIK.INK_DIM, "head"))
		if got:
			top.add_child(UIK.label("✓", 16, UIK.GOOD, "bold"))
		var bar := ColorRect.new()
		bar.custom_minimum_size = Vector2(250, 3)
		bar.color = UIK.GOLD if got else Color(0.3, 0.26, 0.22)
		col.add_child(bar)
		var txt := UIK.label(perks[L], 13, UIK.INK if got else UIK.INK_DIM)
		txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		txt.custom_minimum_size.x = 255
		col.add_child(txt)
	return p
