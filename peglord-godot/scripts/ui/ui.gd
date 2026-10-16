extends CanvasLayer
## The HUD and every menu, drawn over the 3D pub. Listens to Bus; game rules stay in Game/Battle.

const LevelScreen := preload("res://scripts/ui/level.gd")
const GearScreen := preload("res://scripts/ui/gear.gd")
const Screens := preload("res://scripts/ui/screens.gd")

var main
var root: Control
var hud: Control
var plates_layer: Control
var modal_host: Control
var modal: Control = null
var modal_kind := ""
var draft_hidden := false
var t := 0.0

# Top bar.
var top_bar: Control
var stage_name: Label
var stage_sub: Label
var pips: HBoxContainer
var joker_row: HBoxContainer
var joker_cards := {}          # joker id -> inner card Control
var joker_key := ""
var bank_lbl: Label
var bank_bar: HpBar
var levels_lbl: Label
var balls_row: HBoxContainer
var shown_bank := 0.0

# Board-phase widgets.
var ball_panel: PanelContainer
var ball_title: Label
var combo_lbl: Label
var mult_lbl: Label
var pts_lbl: Label
var last_mult := 1
var hint: Label
var side_panel: PanelContainer
var side_box: VBoxContainer
var reveal_plate: Control
var reveal_inner: PanelContainer
var reveal_bar: HpBar
var reveal_key := ""

# Fight-phase widgets.
var cmd_bar: Control
var cmd_heroes: HBoxContainer
var cmd_side: VBoxContainer
var plates := {}               # "hero:id" -> plate Control

# Log, banner, tooltip.
var log_box: VBoxContainer
var banner: Control
var banner_lbl: Label
var banner_sub: Label
var tip_panel: PanelContainer
var tip_holder: MarginContainer
var tip_peg := -1

func _ready() -> void:
	layer = 2
	UIK.root = self
	root = Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UIK.build_theme()
	add_child(root)
	plates_layer = _layer("Plates")
	hud = _layer("Hud")
	_build_top()
	_build_board_widgets()
	_build_cmd_bar()
	_build_log()
	_build_banner()
	modal_host = _layer("Modals")
	_build_tip()
	Bus.refresh.connect(_refresh)
	Bus.hud.connect(_hud)
	Bus.log_msg.connect(_log)
	Bus.pulse_joker.connect(_pulse_joker)
	Bus.phase_changed.connect(_on_phase)
	Bus.new_run.connect(_on_new_run)
	Bus.show_draft.connect(_show_draft)
	Bus.show_end.connect(_show_end)
	Bus.boss_phase2.connect(func(): _banner("Foreclosure", "The Landlord tears up the lease", UIK.BAD))
	_on_phase(S.G.get("phase", "title"))
	if S.G.get("phase", "title") == "title":
		_boot_title.call_deferred()

func _boot_title() -> void:
	if S.G.get("phase", "title") == "title" and modal == null:
		show_title()

func _layer(n: String) -> Control:
	var c := Control.new()
	c.name = n
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(c)
	return c

func _vp() -> Vector2:
	return root.get_viewport_rect().size

# ======================================================================
# Top bar: stage plaque, Balatro-style joker row, XP bank and balls.
# ======================================================================
func _build_top() -> void:
	top_bar = Control.new()
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.custom_minimum_size.y = 100
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(top_bar)
	var shade := TextureRect.new()
	var g := Gradient.new()
	g.set_color(0, Color(0.02, 0.01, 0.01, 0.85))
	g.set_color(1, Color(0.02, 0.01, 0.01, 0.0))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	shade.texture = gt
	shade.set_anchors_preset(Control.PRESET_TOP_WIDE)
	shade.offset_bottom = 130
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_bar.add_child(shade)
	# Stage plaque (left).
	var plaque := UIK.panel()
	plaque.position = Vector2(14, 10)
	top_bar.add_child(plaque)
	var pv := UIK.vbox(2)
	plaque.add_child(pv)
	stage_name = UIK.label("", 22, UIK.GOLD, "head")
	pv.add_child(stage_name)
	stage_sub = UIK.label("", 15, UIK.INK_DIM)
	pv.add_child(stage_sub)
	pips = UIK.hbox(3)
	pv.add_child(pips)
	UIK.tip(plaque, func(): return UIK.text_tip("The road to the Landlord", "Ten stages of goons, then [b]The Landlord[/b]. Clear a stage to pick a reward; the party heals 30%."))
	# Jokers (centre).
	joker_row = UIK.hbox(10)
	joker_row.set_anchors_preset(Control.PRESET_CENTER_TOP)
	joker_row.alignment = BoxContainer.ALIGNMENT_CENTER
	joker_row.position = Vector2(-230, 8)
	joker_row.custom_minimum_size = Vector2(460, 96)
	joker_row.size = Vector2(460, 96)
	top_bar.add_child(joker_row)
	# Bank and balls (right).
	var right := UIK.hbox(10)
	right.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	right.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	right.position = Vector2(-14, 10)
	top_bar.add_child(right)
	var bank := UIK.panel()
	right.add_child(bank)
	var bv := UIK.vbox(2)
	bank.add_child(bv)
	var brow := UIK.hbox(6)
	bv.add_child(brow)
	brow.add_child(UIK.icon("ui_xp", 1))
	bank_lbl = UIK.label("0", 28, UIK.LOOT, "head", 4)
	brow.add_child(bank_lbl)
	brow.add_child(UIK.label("XP", 15, UIK.INK_DIM, "bold"))
	bank_bar = HpBar.new(150, 7)
	bank_bar.fixed_color = UIK.LOOT
	bv.add_child(bank_bar)
	levels_lbl = UIK.label("", 13, UIK.INK_DIM)
	bv.add_child(levels_lbl)
	UIK.tip(bank, func(): return UIK.text_tip("XP bank", "Every point the balls score lands here. [b]99 XP[/b] buys one level for any hero (press [b]L[/b] between balls and fights)."))
	var balls := UIK.panel()
	right.add_child(balls)
	var bv2 := UIK.vbox(4)
	balls.add_child(bv2)
	bv2.add_child(UIK.label("BALLS", 13, UIK.INK_DIM, "head"))
	balls_row = UIK.hbox(2)
	bv2.add_child(balls_row)
	var menu := UIK.vbox(4)
	right.add_child(menu)
	menu.add_child(_icon_btn("ui_help", "How to play (H)", func(): open_help()))
	menu.add_child(_icon_btn("ui_settings", "Settings and menu (Esc)", func(): open_settings()))

func _icon_btn(icon_name: String, tip_text: String, cb: Callable) -> Button:
	var b := UIK.button("", cb)
	b.icon = load("res://assets/icons/%s.png" % icon_name)
	b.expand_icon = true
	b.custom_minimum_size = Vector2(40, 38)
	b.add_theme_constant_override("icon_max_width", 22)
	UIK.tip(b, func(): return UIK.label(tip_text, 15))
	return b

func _refresh_top() -> void:
	var G := S.G
	if G.is_empty() or G.heroes.is_empty():
		return
	var st: Dictionary = D.STAGES[G.stage - 1]
	stage_name.text = st.name
	stage_sub.text = "Stage %d of %d  ·  Round %d" % [G.stage, D.STAGES.size(), G.round]
	UIK.clear(pips)
	for i in D.STAGES.size():
		var r := ColorRect.new()
		r.custom_minimum_size = Vector2(14 if i == D.STAGES.size() - 1 else 10, 5)
		r.color = UIK.GOLD if i < G.stage - 1 else (UIK.LOOT.lightened(0.3) if i == G.stage - 1 else Color(0.3, 0.25, 0.2))
		if i == D.STAGES.size() - 1:
			r.color = UIK.BAD if i == G.stage - 1 else Color(0.45, 0.15, 0.12)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pips.add_child(r)
	_refresh_jokers()
	_hud()

func _hud() -> void:
	var G := S.G
	if G.is_empty():
		return
	var lv: int = int(G.bank / D.LEVEL_COST)
	bank_bar.set_hp(G.bank % D.LEVEL_COST, D.LEVEL_COST)
	levels_lbl.text = ("%d level%s ready" % [lv, "s" if lv != 1 else ""]) if lv > 0 else "%d to next level" % (D.LEVEL_COST - G.bank % D.LEVEL_COST)
	levels_lbl.add_theme_color_override("font_color", UIK.GOOD if lv > 0 else UIK.INK_DIM)
	if balls_row.get_child_count() != G.balls:
		UIK.clear(balls_row)
		for i in G.balls:
			var ic := UIK.icon("ui_ball", 1)
			ic.custom_minimum_size = Vector2(24, 24)
			balls_row.add_child(ic)
		if G.balls == 0:
			balls_row.add_child(UIK.label("none left", 14, UIK.INK_DIM))
	_update_ball_panel()

func _refresh_jokers() -> void:
	var G := S.G
	var key := ",".join(G.jokers)
	if key == joker_key:
		return
	joker_key = key
	UIK.clear(joker_row)
	joker_cards.clear()
	for i in D.MAX_JOKERS:
		var holder := Control.new()
		holder.custom_minimum_size = Vector2(74, 92)
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		joker_row.add_child(holder)
		if i < G.jokers.size():
			var id: String = G.jokers[i]
			var card := _joker_card(id, 74)
			holder.add_child(card)
			card.set_meta("i", i)
			joker_cards[id] = card
		else:
			var empty := PanelContainer.new()
			empty.add_theme_stylebox_override("panel", UIK.nine("res://assets/ui/slot.png", 5, 4))
			empty.size = Vector2(74, 92)
			empty.modulate = Color(0.8, 0.75, 0.7, 0.92)
			empty.mouse_filter = Control.MOUSE_FILTER_PASS
			holder.add_child(empty)
			UIK.tip(empty, func(): return UIK.text_tip("Empty joker slot", "Clear a stage and pick a joker to fill it. Up to %d." % D.MAX_JOKERS))
	if Game.new_joker != "" and joker_cards.has(Game.new_joker):
		var c: Control = joker_cards[Game.new_joker]
		c.scale = Vector2(2.2, 2.2)
		c.modulate = Color(3, 3, 3, 0)
		var tw := c.create_tween().set_parallel()
		tw.tween_property(c, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(c, "modulate", Color.WHITE, 0.5)
		Game.new_joker = ""

## A Balatro-style joker card. Also used on the draft screen.
func _joker_card(id: String, w: float) -> PanelContainer:
	var J: Dictionary = D.JOKERS[id]
	var col := Color(D.JOKER_RARITY_COLOR[J.rarity])
	var card := PanelContainer.new()
	var sb := UIK.nine("res://assets/ui/card.png", 6, 4)
	sb.modulate_color = col.lightened(0.15)
	card.add_theme_stylebox_override("panel", sb)
	card.size = Vector2(w, w * 1.25)
	card.custom_minimum_size = card.size
	card.pivot_offset = card.size / 2
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	var v := UIK.vbox(0)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(v)
	var ic := UIK.icon("joker_" + id, 1)
	ic.custom_minimum_size = Vector2(w * 0.62, w * 0.62)
	v.add_child(ic)
	if w < 100:
		var nm := UIK.label(J.name, 12, UIK.INK, "bold", 3)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nm.custom_minimum_size.x = w - 10
		v.add_child(nm)
	else:
		ic.custom_minimum_size = Vector2(w * 0.8, w * 0.8)
	UIK.tip(card, func(): return UIK.text_tip(J.name, "[color=%s]%s joker[/color]\n%s" % [D.JOKER_RARITY_COLOR[J.rarity], String(J.rarity).capitalize(), J.text], col))
	card.mouse_entered.connect(func(): card.set_meta("hover", true))
	card.mouse_exited.connect(func(): card.set_meta("hover", false))
	return card

func _pulse_joker(id: String) -> void:
	var c = joker_cards.get(id)
	if c == null:
		return
	var card: Control = c
	card.set_meta("pulse", 1.0)

func _animate_jokers(dt: float) -> void:
	for id in joker_cards:
		var c: Control = joker_cards[id]
		var i: int = c.get_meta("i", 0)
		var p: float = c.get_meta("pulse", 0.0)
		if p > 0:
			p = maxf(0.0, p - dt * 2.2)
			c.set_meta("pulse", p)
		var hov: bool = c.get_meta("hover", false)
		c.rotation = sin(t * 1.1 + i * 1.7) * 0.035 + (sin(p * 20.0) * 0.12 * p)
		c.position.y = sin(t * 1.4 + i) * 2.0 - (8.0 if hov else 0.0) - p * 10.0
		var s := 1.0 + p * 0.25 + (0.08 if hov else 0.0)
		if c.scale.x <= 1.3:
			c.scale = c.scale.lerp(Vector2(s, s), minf(1.0, dt * 14.0))
		c.modulate = Color(1 + p * 1.5, 1 + p * 1.3, 1 + p * 0.6, c.modulate.a)

# ======================================================================
# Board phase: ball panel beside the board, party/foe sidebar, reveal plate, hint.
# ======================================================================
func _build_board_widgets() -> void:
	ball_panel = UIK.panel()
	ball_panel.custom_minimum_size = Vector2(170, 0)
	hud.add_child(ball_panel)
	var v := UIK.vbox(0)
	ball_panel.add_child(v)
	ball_title = UIK.label("", 14, UIK.INK_DIM, "head")
	v.add_child(ball_title)
	v.add_child(UIK.sep())
	var row := UIK.hbox(8)
	v.add_child(row)
	var cv := UIK.vbox(-4)
	row.add_child(cv)
	cv.add_child(UIK.label("COMBO", 12, UIK.INK_DIM, "head"))
	combo_lbl = UIK.label("0", 34, UIK.INK, "head", 4)
	cv.add_child(combo_lbl)
	row.add_child(UIK.spacer())
	mult_lbl = UIK.label("×1", 40, UIK.LOOT, "title", 6)
	mult_lbl.pivot_offset = Vector2(30, 28)
	row.add_child(mult_lbl)
	pts_lbl = UIK.label("", 16, UIK.GOOD, "bold")
	v.add_child(pts_lbl)
	UIK.tip(ball_panel, func(): return UIK.text_tip("Combo and multiplier", "Each scoring hit adds 1 to the combo. The multiplier is 1 + combo ÷ %d. Points = peg value × stage payout (×%d) × multiplier." % [6 if S.has_joker("comboking") else 8, D.payout(S.G.stage)]))
	hint = UIK.label("", 16, UIK.INK, "bold", 4)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.custom_minimum_size.x = 420
	hud.add_child(hint)
	side_panel = UIK.panel()
	side_panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	side_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	side_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	side_panel.position = Vector2(-14, -40)
	side_panel.custom_minimum_size = Vector2(290, 0)
	hud.add_child(side_panel)
	side_box = UIK.vbox(5)
	side_panel.add_child(side_box)
	# Pocket reveal plate (anchored over the pocket at runtime).
	reveal_plate = Control.new()
	reveal_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reveal_plate.visible = false
	hud.add_child(reveal_plate)

func _refresh_side() -> void:
	var G := S.G
	UIK.clear(side_box)
	side_box.add_child(UIK.header("Party", 18))
	for h in G.heroes:
		side_box.add_child(_mini_row(h, true))
	side_box.add_child(UIK.spacer(0, 4))
	side_box.add_child(UIK.header("Foes", 18))
	for f in G.foes:
		side_box.add_child(_mini_row(f, false))
	var tf = Battle.current_target()
	if tf != null:
		side_box.add_child(UIK.label("Heroes attack: %s" % tf.name, 13, UIK.INK_DIM))

func _mini_row(u: Dictionary, hero: bool) -> Control:
	var row := UIK.hbox(6)
	var kind: String = u.cls if hero else ("landlord" if u.boss else u.type)
	var p := UIK.portrait(kind, 38)
	if u.dead:
		p.modulate = Color(0.35, 0.3, 0.3)
	row.add_child(p)
	var v := UIK.vbox(1)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(v)
	var top := UIK.hbox(4)
	v.add_child(top)
	var mx: int = S.hero_stats(u).maxHp if hero else u.maxHp
	top.add_child(UIK.label(u.name + ("  Lv %d" % u.level if hero else ""), 14, UIK.INK if not u.dead else UIK.INK_DIM, "bold"))
	top.add_child(UIK.spacer())
	top.add_child(UIK.label("%d/%d" % [u.hp, mx] if not u.dead else "down", 13, UIK.INK_DIM))
	var bar := HpBar.new(200, 7)
	bar.set_hp(u.hp, mx, u.get("shield", 0))
	v.add_child(bar)
	if not hero and not u.dead:
		var intent := UIK.label("Next: " + Battle.intent_label(u), 13, Color("#ffb38a"))
		v.add_child(intent)
	if not hero and u.id == S.G.target and not u.dead:
		row.add_child(UIK.icon("ui_attack", 1))
	return row

func _update_ball_panel() -> void:
	var G := S.G
	if G.is_empty() or G.heroes.is_empty():
		return
	var b = Game.board.ball
	var balls_total: int = G.ballNo + G.balls
	if b != null:
		ball_title.text = "Ball %d of %d" % [G.ballNo, balls_total]
		combo_lbl.text = str(b.combo)
		var m := Game.board.mult_for(b.combo)
		mult_lbl.text = "×%d" % m
		if m != last_mult:
			last_mult = m
			mult_lbl.scale = Vector2(1.6, 1.6)
			mult_lbl.create_tween().tween_property(mult_lbl, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pts_lbl.text = "+%d XP this ball" % b.pts
	elif G.phase == "aim":
		ball_title.text = "Ball %d of %d" % [G.ballNo + 1, balls_total]
		combo_lbl.text = "8" if G.hotNext else "0"
		mult_lbl.text = "×2" if G.hotNext else "×1"
		last_mult = 1
		pts_lbl.text = Game.board.split_text() + " pockets"

func _update_board_widgets() -> void:
	var G := S.G
	var cam: Camera3D = main.cam
	var bv = main.board
	var board_phase: bool = G.phase in ["aim", "ball", "sink"]
	ball_panel.visible = board_phase and modal == null
	hint.visible = board_phase and modal == null
	if board_phase:
		var tr: Vector2 = bv.screen_of_board(cam, D.PHYS.W + 40, 40)
		ball_panel.position = Vector2(minf(tr.x, _vp().x - 480), maxf(96.0, tr.y))
		var bc: Vector2 = bv.screen_of_board(cam, D.PHYS.W / 2.0, D.PHYS.H + 34)
		hint.position = Vector2(bc.x - hint.size.x / 2, minf(bc.y, _vp().y - 34))
		match G.phase:
			"aim": hint.text = "Move to aim  ·  click to drop  ·  hidden pockets: " + Game.board.split_text()
			"ball": hint.text = "Hold the line... every hit pays XP"
			"sink": hint.text = "Click to continue"
	_update_reveal(cam, bv)

func _update_reveal(cam: Camera3D, bv) -> void:
	var R = Game.board.reveal
	if R == null or not R.flipped:
		if reveal_plate.visible:
			reveal_plate.visible = false
			reveal_key = ""
		return
	var key := "%d:%s:%d" % [R.slot, R.type, Game.G.ballNo]
	if key != reveal_key:
		reveal_key = key
		_build_reveal(R.type)
	reveal_plate.visible = true
	var sw: float = D.PHYS.W / D.PHYS.pocketCount
	var at: Vector2 = bv.screen_of_board(cam, (R.slot + 0.5) * sw, D.PHYS.H - 46)
	var w := reveal_inner.size.x
	var hgt := reveal_inner.size.y
	reveal_plate.position = Vector2(clampf(at.x - w / 2, 8, _vp().x - w - 8), clampf(at.y - hgt, 100, _vp().y - hgt - 8))
	var hold: float = D.REVEAL_HOLD
	reveal_bar.set_hp(maxf(0.0, hold - R.t), hold)

func _build_reveal(type: String) -> void:
	UIK.clear(reveal_plate)
	var P: Dictionary = D.POCKETS[type]
	var good: bool = P.kind == "perk"
	var col := UIK.GOOD if good else UIK.BAD
	reveal_inner = UIK.panel(true)
	var sb := UIK.nine("res://assets/ui/panel_light.png", 7, 14)
	sb.modulate_color = Color(0.75, 1.0, 0.8) if good else Color(1.0, 0.7, 0.65)
	reveal_inner.add_theme_stylebox_override("panel", sb)
	reveal_inner.custom_minimum_size = Vector2(300, 0)
	reveal_plate.add_child(reveal_inner)
	var v := UIK.vbox(4)
	reveal_inner.add_child(v)
	var tag := UIK.label("PERK POCKET" if good else "BAD POCKET", 13, col, "head")
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(tag)
	var row := UIK.hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	row.add_child(UIK.icon("pocket_" + type, 2))
	row.add_child(UIK.label(P.name, 30, UIK.INK, "head", 5))
	var txt := UIK.label(P.text, 17, UIK.INK)
	txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	txt.custom_minimum_size.x = 270
	v.add_child(txt)
	reveal_bar = HpBar.new(270, 5)
	reveal_bar.fixed_color = col
	v.add_child(reveal_bar)
	var skip := UIK.label("click to continue", 12, UIK.INK_DIM)
	skip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(skip)
	# Flip up like a card.
	reveal_inner.pivot_offset = Vector2(150, 80)
	reveal_inner.scale = Vector2(0.05, 1.0)
	reveal_inner.position.y = 30
	var tw := reveal_inner.create_tween().set_parallel()
	tw.tween_property(reveal_inner, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(reveal_inner, "position:y", 0.0, 0.28).set_ease(Tween.EASE_OUT)

## Called by main on mouse motion with the peg under the cursor (or null).
func hover_peg(p) -> void:
	var G := S.G
	if p == null or G.is_empty() or G.phase != "aim" or modal != null:
		if tip_peg != -1:
			tip_peg = -1
			hide_tip()
		return
	if p.id == tip_peg:
		return
	tip_peg = p.id
	var def: Dictionary = D.PEGS[p.type]
	var v: int = def.pts
	show_tip(UIK.text_tip(def.name + " peg", "Pays [b]%d[/b] × stage payout × multiplier.\n%s" % [v, def.rule], Color(def.color)))

# ======================================================================
# Fight phase: unit plates over the sprites and the command bar.
# ======================================================================
func _build_cmd_bar() -> void:
	cmd_bar = Control.new()
	cmd_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	cmd_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cmd_bar.visible = false
	hud.add_child(cmd_bar)
	var row := UIK.hbox(10)
	row.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	row.grow_horizontal = Control.GROW_DIRECTION_BOTH
	row.grow_vertical = Control.GROW_DIRECTION_BEGIN
	row.position = Vector2(0, -12)
	cmd_bar.add_child(row)
	cmd_heroes = UIK.hbox(10)
	row.add_child(cmd_heroes)
	cmd_side = UIK.vbox(6)
	row.add_child(cmd_side)

func _refresh_cmd() -> void:
	var G := S.G
	UIK.clear(cmd_heroes)
	UIK.clear(cmd_side)
	var fighting: bool = G.phase == "resolve"
	for i in G.heroes.size():
		cmd_heroes.add_child(_hero_card(G.heroes[i], i, fighting))
	var lv: int = int(G.bank / D.LEVEL_COST)
	var row1 := UIK.hbox(6)
	cmd_side.add_child(row1)
	var lb := UIK.button("Level Up" + (" (%d)" % lv if lv > 0 else ""), func(): open_level())
	lb.icon = load("res://assets/icons/ui_levelup.png")
	lb.custom_minimum_size = Vector2(150, 40)
	lb.disabled = fighting
	if lv > 0 and not fighting:
		lb.add_theme_color_override("font_color", UIK.GOOD)
	row1.add_child(lb)
	UIK.tip(lb, func(): return UIK.label("Spend XP on attributes (L)", 15))
	var gb := UIK.button("Gear" + (" (%d)" % G.pack.size() if G.pack.size() else ""), func(): open_gear())
	gb.icon = load("res://assets/icons/ui_pack.png")
	gb.custom_minimum_size = Vector2(120, 40)
	gb.disabled = fighting
	row1.add_child(gb)
	UIK.tip(gb, func(): return UIK.label("Equipment and pack (C)", 15))
	if G.phase == "draft":
		var cb := UIK.button("Choose reward", func(): _show_draft(), true, 22)
		cb.custom_minimum_size = Vector2(276, 56)
		cmd_side.add_child(cb)
		return
	var fb := UIK.button("Fighting..." if fighting else "FIGHT", func(): Game.fight(), true, 26)
	fb.custom_minimum_size = Vector2(276, 56)
	fb.disabled = fighting
	cmd_side.add_child(fb)
	UIK.tip(fb, func(): return UIK.label("Heroes act left to right, then the foes (Space)", 15))

func _hero_card(h: Dictionary, i: int, fighting: bool) -> Control:
	var G := S.G
	var st := S.hero_stats(h)
	var sel: bool = i == G.selHero
	var card := UIK.panel(sel)
	card.custom_minimum_size = Vector2(270, 0)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			G.selHero = i
			Sfx.play("ui")
			Bus.refresh.emit())
	var v := UIK.vbox(4)
	card.add_child(v)
	var top := UIK.hbox(8)
	v.add_child(top)
	var p := UIK.portrait(h.cls, 46)
	if h.dead:
		p.modulate = Color(0.4, 0.35, 0.35)
	top.add_child(p)
	var nv := UIK.vbox(0)
	nv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(nv)
	var nrow := UIK.hbox(6)
	nv.add_child(nrow)
	nrow.add_child(UIK.label(h.name, 18, Color(D.HEROES[h.cls].color), "head"))
	nrow.add_child(UIK.spacer())
	nrow.add_child(UIK.label("Lv %d" % h.level, 15, UIK.GOLD, "bold"))
	var bar := HpBar.new(170, 9)
	bar.set_hp(h.hp, st.maxHp, h.shield)
	nv.add_child(bar)
	var info := UIK.hbox(8)
	nv.add_child(info)
	info.add_child(UIK.label("%d/%d HP" % [h.hp, st.maxHp] if not h.dead else "Fallen", 13, UIK.INK_DIM))
	info.add_child(UIK.spacer())
	info.add_child(UIK.label("AR %d" % st.ar, 13, UIK.INK_DIM))
	if h.dead:
		v.add_child(UIK.label("Revives at the end of the stage", 13, UIK.BAD))
		return card
	var cmds := UIK.hbox(4)
	v.add_child(cmds)
	var sk: Dictionary = D.HEROES[h.cls].skill
	var ready := Battle.skill_ready(h)
	var defs := [["attack", "Attack", "ui_attack", "Basic hit on the target foe for your AR."],
		["skill", sk.name, "ui_fire" if h.cls == "mage" else ("ui_herb" if h.cls == "priest" else "ui_bolt"), "%s (cooldown %d)" % [sk.text, st.cd]],
		["guard", "Guard", "ui_guard", "Take less damage this round and heal 2. A guarding Knight draws attacks."]]
	for d in defs:
		var cmd: String = d[0]
		var txt: String = d[1]
		if cmd == "skill" and not ready:
			txt = "%s (%d)" % [sk.name, h.cd]
		var b := Button.new()
		b.text = txt
		b.icon = load("res://assets/icons/%s.png" % d[2])
		b.add_theme_constant_override("icon_max_width", 18)
		b.add_theme_font_size_override("font_size", 14)
		b.focus_mode = Control.FOCUS_NONE
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.clip_text = true
		b.disabled = fighting or (cmd == "skill" and not ready)
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		if h.cmd == cmd:
			b.add_theme_stylebox_override("normal", UIK.nine("res://assets/ui/button_go.png", 5, 6))
			b.add_theme_stylebox_override("disabled", UIK.nine("res://assets/ui/button_go.png", 5, 6))
			b.add_theme_color_override("font_disabled_color", UIK.INK)
		else:
			for k in ["normal", "hover", "pressed", "disabled"]:
				var sb: StyleBoxTexture = UIK.theme.get_stylebox(k, "Button").duplicate()
				sb.content_margin_left = 6
				sb.content_margin_right = 6
				b.add_theme_stylebox_override(k, sb)
		b.pressed.connect(func():
			Sfx.start()
			Sfx.play("ui")
			h.cmd = cmd
			G.selHero = i
			Bus.refresh.emit())
		var tip_title: String = d[1]
		var tip_body: String = d[3]
		UIK.tip(b, func(): return UIK.text_tip(tip_title, tip_body))
		cmds.add_child(b)
	return card

func _plate_for(side: String, u: Dictionary) -> Control:
	var key := "%s:%d" % [side, u.id]
	if plates.has(key):
		return plates[key]
	var hero := side == "hero"
	var boss: bool = u.get("boss", false)
	var p := VBoxContainer.new()
	p.add_theme_constant_override("separation", 0)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var intent := UIK.label("", 14, Color("#ffb38a"), "bold", 4)
	intent.name = "Intent"
	intent.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intent.visible = not hero
	p.add_child(intent)
	var nm := UIK.label(u.name, 14, UIK.INK, "bold", 4)
	nm.name = "Name"
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.visible = not hero
	p.add_child(nm)
	var bar := HpBar.new(200 if boss else (96 if hero else 112), 8)
	bar.name = "Bar"
	bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	p.add_child(bar)
	var sub := UIK.label("", 12, UIK.INK_DIM, "bold", 3)
	sub.name = "Sub"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(sub)
	plates_layer.add_child(p)
	plates[key] = p
	return p

func _update_plates() -> void:
	var G := S.G
	var show: bool = G.phase in ["alloc", "resolve", "draft"] and not G.is_empty() and modal == null
	plates_layer.visible = show
	if not show:
		return
	var cam: Camera3D = main.cam
	var seen := {}
	var placed := []
	for pair in [["hero", G.heroes], ["foe", G.foes]]:
		var side: String = pair[0]
		for u in pair[1]:
			var unit: Unit = main.fight.unit(side, u.id)
			if unit == null:
				continue
			var p := _plate_for(side, u)
			seen["%s:%d" % [side, u.id]] = true
			var hero := side == "hero"
			var mx: int = S.hero_stats(u).maxHp if hero else u.maxHp
			(p.get_node("Bar") as HpBar).set_hp(u.hp, mx, u.get("shield", 0))
			var intent: Label = p.get_node("Intent")
			var nm: Label = p.get_node("Name")
			var sub: Label = p.get_node("Sub")
			var tags := []
			if hero:
				if u.guarding or (u.cmd == "guard" and G.phase == "alloc"):
					tags.append("Guard")
				if u.hex > 0:
					tags.append("Hexed")
			else:
				var targ: bool = u.id == G.target and not u.dead
				intent.text = "" if u.dead else Battle.intent_label(u)
				intent.visible = not u.dead
				nm.text = ("» %s «" % u.name) if targ else u.name
				nm.add_theme_color_override("font_color", UIK.LOOT if targ else UIK.INK)
				if u.burnTurns > 0:
					tags.append("Burn %d" % u.burn)
				if u.mark:
					tags.append("Marked")
				if u.armor > 0:
					tags.append("Armor %d" % u.armor)
			sub.text = ("%d/%d" % [u.hp, mx] if not u.dead else "down") + ("  ·  " + "  ·  ".join(tags) if not tags.is_empty() else "")
			p.modulate.a = 0.5 if u.dead else 1.0
			p.reset_size()
			var feet := cam.unproject_position(unit.global_position)
			var sp := cam.unproject_position(unit.head_global() + Vector3(0, 0.08, 0))
			p.visible = not cam.is_position_behind(unit.head_global())
			placed.append({"p": p, "x": sp.x - p.size.x / 2, "y": sp.y - p.size.y, "feet": feet.y})
	# Front units keep their plate on the head; plates behind them step up until nothing overlaps.
	placed.sort_custom(func(a, b): return a.feet > b.feet)
	var rects: Array[Rect2] = []
	for e in placed:
		var p: Control = e.p
		var r := Rect2(e.x, e.y, p.size.x, p.size.y)
		var moved := true
		var guard := 0
		while moved and guard < 8:
			moved = false
			guard += 1
			for o in rects:
				if r.grow(1).intersects(o):
					r.position.y = o.position.y - r.size.y - 2
					moved = true
		rects.append(r)
		p.position = p.position.lerp(r.position, 0.35) if p.has_meta("placed") else r.position
		p.set_meta("placed", true)
	for k in plates.keys():
		if not seen.has(k):
			plates[k].queue_free()
			plates.erase(k)

# ======================================================================
# Log, banner and tooltip.
# ======================================================================
func _build_log() -> void:
	log_box = UIK.vbox(2)
	log_box.position = Vector2(16, 112)
	log_box.custom_minimum_size.x = 340
	hud.add_child(log_box)

func _log(text: String, kind: String) -> void:
	var col := UIK.INK
	match kind:
		"good": col = UIK.GOOD
		"bad": col = UIK.BAD
		"loot": col = UIK.LOOT
	var l := UIK.label(text, 15, col, "bold", 4)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 340
	log_box.add_child(l)
	l.modulate.a = 0.0
	l.create_tween().tween_property(l, "modulate:a", 1.0, 0.25)
	while log_box.get_child_count() > 6:
		var c := log_box.get_child(0)
		log_box.remove_child(c)
		c.queue_free()
	var n := log_box.get_child_count()
	for i in n:
		var c2: Control = log_box.get_child(i)
		c2.set_meta("age", float(n - 1 - i))

func _fade_log(dt: float) -> void:
	for c in log_box.get_children():
		var age: float = c.get_meta("age", 0.0)
		var life: float = c.get_meta("life", 0.0) + dt
		c.set_meta("life", life)
		var a := clampf(1.0 - age * 0.14, 0.25, 1.0)
		if life > 9.0:
			a *= clampf(1.0 - (life - 9.0) / 3.0, 0.0, 1.0)
		if c.modulate.a > 0.0 and life > 0.3:
			c.modulate.a = a

func _build_banner() -> void:
	banner = UIK.vbox(0)
	banner.set_anchors_preset(Control.PRESET_CENTER)
	banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	banner.grow_vertical = Control.GROW_DIRECTION_BOTH
	banner.position = Vector2(-400, -190)
	banner.custom_minimum_size = Vector2(800, 0)
	banner.visible = false
	hud.add_child(banner)
	var line1 := TextureRect.new()
	banner_lbl = UIK.label("", 58, UIK.GOLD, "title", 10)
	banner_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_child(banner_lbl)
	var rule := UIK.hbox(8)
	rule.alignment = BoxContainer.ALIGNMENT_CENTER
	var r1 := ColorRect.new()
	r1.color = UIK.GOLD
	r1.custom_minimum_size = Vector2(160, 1)
	r1.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rule.add_child(r1)
	var dm := TextureRect.new()
	dm.texture = load("res://assets/ui/diamond.png")
	rule.add_child(dm)
	rule.add_child(r1.duplicate())
	banner.add_child(rule)
	banner_sub = UIK.label("", 20, UIK.INK, "bold", 5)
	banner_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_child(banner_sub)
	line1.queue_free()

func _banner(text: String, sub := "", col := UIK.GOLD) -> void:
	banner_lbl.text = text
	banner_lbl.add_theme_color_override("font_color", col)
	banner_sub.text = sub
	banner.visible = true
	banner.modulate.a = 0.0
	banner.pivot_offset = Vector2(400, 60)
	banner.scale = Vector2(1.15, 1.15)
	var tw := banner.create_tween()
	tw.set_parallel()
	tw.tween_property(banner, "modulate:a", 1.0, 0.25)
	tw.tween_property(banner, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.chain().tween_interval(1.1)
	tw.chain().tween_property(banner, "modulate:a", 0.0, 0.5)
	tw.chain().tween_callback(func(): banner.visible = false)

func _build_tip() -> void:
	tip_panel = UIK.panel(true)
	tip_panel.visible = false
	tip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip_panel.z_index = 100
	root.add_child(tip_panel)
	tip_holder = MarginContainer.new()
	tip_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip_panel.add_child(tip_holder)

func show_tip(c: Control) -> void:
	UIK.clear(tip_holder)
	if c == null:
		hide_tip()
		return
	_ignore_mouse(c)
	tip_holder.add_child(c)
	tip_panel.reset_size()
	tip_panel.visible = true
	tip_panel.modulate.a = 0.0
	_place_tip()

func hide_tip() -> void:
	tip_panel.visible = false

func _ignore_mouse(c: Node) -> void:
	if c is Control:
		(c as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for k in c.get_children():
		_ignore_mouse(k)

func _place_tip() -> void:
	var m := root.get_local_mouse_position()
	var s := tip_panel.get_combined_minimum_size()
	tip_panel.size = s
	var p := m + Vector2(20, 20)
	var vp := _vp()
	if p.x + s.x > vp.x - 8:
		p.x = m.x - s.x - 14
	if p.y + s.y > vp.y - 8:
		p.y = vp.y - s.y - 8
	tip_panel.position = p.round()
	tip_panel.modulate.a = minf(1.0, tip_panel.modulate.a + 0.25)

# ======================================================================
# Modals.
# ======================================================================
func _open(kind: String, node: Control, dim := true) -> void:
	close_all()
	hide_tip()
	modal_kind = kind
	var host := Control.new()
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.mouse_filter = Control.MOUSE_FILTER_STOP
	modal_host.add_child(host)
	if dim:
		var d := ColorRect.new()
		d.color = Color(0.03, 0.02, 0.02, 0.62)
		d.set_anchors_preset(Control.PRESET_FULL_RECT)
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		host.add_child(d)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(cc)
	cc.add_child(node)
	modal = host
	host.set_meta("screen", node)
	host.modulate.a = 0.0
	host.create_tween().tween_property(host, "modulate:a", 1.0, 0.18)
	_refresh_visibility()

func close_all() -> void:
	for c in modal_host.get_children():
		c.queue_free()
	modal = null
	modal_kind = ""
	hide_tip()
	_refresh_visibility()

func _close_modal() -> void:
	var G := S.G
	if modal_kind == "title" and (G.is_empty() or G.phase == "title"):
		return
	close_all()
	if G.is_empty() or G.phase == "title" or G.heroes.is_empty():
		show_title()
		return
	Bus.refresh.emit()

func show_title() -> void:
	_open("title", Screens.title(self), false)

func open_help() -> void:
	_open("help", Screens.help(self))

func open_settings() -> void:
	_open("settings", Screens.settings(self))

func open_level() -> void:
	if S.G.is_empty() or S.G.heroes.is_empty():
		return
	var s := LevelScreen.new()
	s.ui = self
	_open("level", s)

func open_gear() -> void:
	if S.G.is_empty() or S.G.heroes.is_empty():
		return
	var s := GearScreen.new()
	s.ui = self
	_open("gear", s)

func _show_draft() -> void:
	draft_hidden = false
	_open("draft", Screens.draft(self))

func hide_draft() -> void:
	draft_hidden = true
	close_all()
	Bus.refresh.emit()

func _show_end(win: bool, legs: Array, newly: Array) -> void:
	_open("end", Screens.end_screen(self, win, legs, newly))

# ======================================================================
# Flow.
# ======================================================================
func _on_new_run() -> void:
	draft_hidden = false
	joker_key = "?"
	for k in plates.keys():
		plates[k].queue_free()
	plates.clear()
	var G := S.G
	_banner(D.STAGES[G.stage - 1].name, "Stage %d of %d" % [G.stage, D.STAGES.size()] if G.stage < D.STAGES.size() else "Pay the rent. Or don't.", UIK.GOLD if G.stage < D.STAGES.size() else UIK.BAD)

func _on_phase(p: String) -> void:
	var G := S.G
	if p == "aim" and G.get("ballNo", 0) == 0 and G.get("round", 1) > 1:
		_banner("Round %d" % G.round, "%d balls" % G.balls)
	if p == "resolve":
		_banner("Fight!", "", UIK.BAD)
	if p == "alloc" and modal_kind == "":
		pass
	_refresh_visibility()
	_refresh()

func _refresh_visibility() -> void:
	var G := S.G
	var in_run: bool = not G.is_empty() and G.phase != "title" and not G.heroes.is_empty()
	var blocking: bool = modal != null and modal_kind in ["title", "end", "draft", "level", "gear", "help", "settings"]
	hud.visible = in_run and modal_kind != "title"
	top_bar.visible = in_run and modal_kind != "title"
	var board_phase: bool = in_run and G.phase in ["aim", "ball", "sink"]
	side_panel.visible = board_phase and not blocking
	cmd_bar.visible = in_run and (G.phase == "alloc" or G.phase == "resolve" or (G.phase == "draft" and draft_hidden)) and not blocking
	log_box.visible = in_run and not (blocking and modal_kind in ["level", "gear"])

func _refresh() -> void:
	var G := S.G
	if G.is_empty() or G.heroes.is_empty():
		return
	_refresh_top()
	if side_panel.visible:
		_refresh_side()
	if cmd_bar.visible:
		_refresh_cmd()
	if modal != null:
		var scr: Control = modal.get_meta("screen")
		if scr.has_method("refresh"):
			scr.refresh()

func _process(dt: float) -> void:
	t += dt
	if S.G.is_empty() or main == null:
		return
	_animate_jokers(dt)
	_fade_log(dt)
	if hud.visible:
		_update_board_widgets()
	_update_plates()
	if tip_panel.visible:
		_place_tip()
	var target := float(S.G.get("bank", 0))
	if absf(shown_bank - target) > 0.5:
		shown_bank = lerpf(shown_bank, target, minf(1.0, dt * 10.0))
	else:
		shown_bank = target
	bank_lbl.text = str(roundi(shown_bank))

func _unhandled_input(e: InputEvent) -> void:
	if not (e is InputEventKey and e.pressed and not e.echo):
		return
	var G := S.G
	var k: int = e.keycode
	if k == KEY_ESCAPE:
		if modal != null and modal_kind != "title":
			if modal_kind == "draft":
				hide_draft()
			elif modal_kind == "end":
				pass
			else:
				_close_modal()
		elif modal == null and not G.is_empty() and G.phase != "title":
			open_settings()
		get_viewport().set_input_as_handled()
		return
	if G.is_empty() or G.phase == "title" or G.phase == "over":
		return
	if modal != null and modal_kind in ["title", "end", "draft", "help", "settings"]:
		return
	match k:
		KEY_L:
			if modal_kind == "level":
				_close_modal()
			else:
				open_level()
		KEY_C, KEY_I:
			if modal_kind == "gear":
				_close_modal()
			else:
				open_gear()
		KEY_H, KEY_F1:
			open_help()
		KEY_SPACE, KEY_ENTER, KEY_KP_ENTER:
			if modal != null:
				_close_modal()
			elif G.phase == "aim":
				Sfx.start()
				Game.board.fire()
			elif G.phase == "sink":
				Game.board.skip_reveal()
			elif G.phase == "alloc":
				Game.fight()
			elif G.phase == "draft" and draft_hidden:
				_show_draft()
		KEY_LEFT, KEY_A:
			if G.phase == "aim":
				Game.board.nudge_aim(0.04)
		KEY_RIGHT, KEY_D:
			if G.phase == "aim":
				Game.board.nudge_aim(-0.04)
		KEY_1, KEY_2, KEY_3:
			if G.phase == "alloc" and modal == null:
				var h: Dictionary = G.heroes[G.selHero]
				var cmd: String = ["attack", "skill", "guard"][k - KEY_1]
				if not h.dead and (cmd != "skill" or Battle.skill_ready(h)):
					h.cmd = cmd
					Sfx.play("ui")
					Bus.refresh.emit()
		KEY_TAB:
			G.selHero = (G.selHero + 1) % G.heroes.size()
			Bus.refresh.emit()
		_:
			return
	get_viewport().set_input_as_handled()
