extends RefCounted
## Title, help, settings, draft and end screens. Each builder returns a Control the UI shows as a modal.

const PEG_ICON := {"brass": "●", "gold": "◆", "crate": "■", "bomb": "●", "bumper": "○", "glass": "◆", "heart": "♥", "star": "★", "bolt": "✦", "portal": "○", "rover": "●", "chest": "■"}

# ---------------------------------------------------------------- Title
static func title(ui) -> Control:
	var G := S.G
	var meta: Dictionary = Game.meta
	var pool: Array = D.DEFAULT_PARTY + meta.unlocked
	var st := {"party": D.DEFAULT_PARTY.duplicate(), "seed": "", "joker": true}
	var box := Control.new()
	box.custom_minimum_size = Vector2(1200, 640)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var build := func(self_ref: Callable) -> void:
		UIK.clear(box)
		var shade := TextureRect.new()
		var g := Gradient.new()
		g.set_color(0, Color(0.02, 0.01, 0.01, 0.78))
		g.set_color(1, Color(0.02, 0.01, 0.01, 0.0))
		var gt := GradientTexture2D.new()
		gt.gradient = g
		gt.fill = GradientTexture2D.FILL_RADIAL
		gt.fill_from = Vector2(0.5, 0.5)
		gt.fill_to = Vector2(1.0, 0.5)
		shade.texture = gt
		shade.position = Vector2(-160, -40)
		shade.size = Vector2(1000, 520)
		shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(shade)
		# Logo.
		var left := UIK.vbox(0)
		left.position = Vector2(0, 40)
		left.size = Vector2(700, 600)
		box.add_child(left)
		var logo := UIK.label("PEGLORD", 116, UIK.GOLD, "title", 14)
		logo.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
		logo.add_theme_constant_override("shadow_offset_y", 6)
		left.add_child(logo)
		left.add_child(UIK.label("A pub bagatelle roguelike", 26, UIK.INK, "head", 6))
		var tag := UIK.label("Drop balls through the pegs, bank XP, level three heroes\nand evict The Landlord before the rent comes due.", 19, UIK.INK_DIM, "bold", 5)
		left.add_child(tag)
		# Menu panel.
		var p := UIK.panel()
		p.position = Vector2(740, 30)
		p.custom_minimum_size = Vector2(440, 0)
		box.add_child(p)
		var v := UIK.vbox(10)
		p.add_child(v)
		var in_run: bool = not G.is_empty() and G.phase != "title" and G.phase != "over" and not G.heroes.is_empty()
		if in_run:
			var rb := UIK.button("Resume", func():
				ui.close_all()
				Bus.refresh.emit(), true, 22)
			rb.custom_minimum_size.y = 52
			v.add_child(rb)
		var nb := UIK.button("New run", func():
			Sfx.start()
			ui.close_all()
			Game.new_run(st.seed, st.party, st.joker and meta.startJoker), not in_run, 22)
		nb.custom_minimum_size.y = 52
		v.add_child(nb)
		var cb := UIK.button("Continue saved run", func():
			Sfx.start()
			ui.close_all()
			Game.resume())
		cb.disabled = not Game.has_save()
		v.add_child(cb)
		v.add_child(UIK.sep())
		v.add_child(UIK.label("PARTY", 15, UIK.GOLD, "head"))
		var prow := UIK.hbox(6)
		v.add_child(prow)
		for i in 3:
			var cls: String = st.party[i]
			var b := Button.new()
			b.focus_mode = Control.FOCUS_NONE
			b.custom_minimum_size = Vector2(136, 92)
			b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			var bv := UIK.vbox(0)
			bv.set_anchors_preset(Control.PRESET_FULL_RECT)
			bv.alignment = BoxContainer.ALIGNMENT_CENTER
			b.add_child(bv)
			var pt := UIK.portrait(cls, 62)
			pt.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			bv.add_child(pt)
			var nl := UIK.label(D.HEROES[cls].name, 15, Color(D.HEROES[cls].color), "bold")
			nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			bv.add_child(nl)
			b.pressed.connect(func():
				Sfx.start()
				Sfx.play("ui")
				if pool.size() <= 3:
					return
				var idx := pool.find(st.party[i])
				for k in pool.size():
					idx = (idx + 1) % pool.size()
					if not st.party.has(pool[idx]):
						break
				st.party[i] = pool[idx]
				self_ref.call(self_ref))
			var def: Dictionary = D.HEROES[cls]
			UIK.tip(b, func(): return UIK.text_tip("%s, %s" % [def.name, def.title], "%s\n[color=#e2bd6a]Skill[/color] %s: %s%s" % [def.passive, def.skill.name, def.skill.text,
				"\n[color=#b9ab8e]Click to swap hero.[/color]" if pool.size() > 3 else "\n[color=#b9ab8e]Clear The Landlord to unlock the Rogue and the Ranger.[/color]"], Color(def.color)))
			prow.add_child(b)
		var srow := UIK.hbox(8)
		v.add_child(srow)
		srow.add_child(UIK.icon("ui_seed", 1))
		srow.add_child(UIK.label("Seed", 16, UIK.INK, "bold"))
		var le := LineEdit.new()
		le.placeholder_text = "random"
		le.max_length = 12
		le.text = st.seed
		le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		le.text_changed.connect(func(x): st.seed = x)
		srow.add_child(le)
		if meta.startJoker:
			var ck := CheckBox.new()
			ck.text = "Start with a random common joker"
			ck.button_pressed = st.joker
			ck.focus_mode = Control.FOCUS_NONE
			ck.toggled.connect(func(x): st.joker = x)
			v.add_child(ck)
		v.add_child(UIK.sep())
		var brow := UIK.hbox(8)
		v.add_child(brow)
		var hb := UIK.button("How to play", func(): ui.open_help())
		hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		brow.add_child(hb)
		var sb := UIK.button("Settings", func(): ui.open_settings())
		sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		brow.add_child(sb)
		var foot := UIK.label("Runs %d  ·  Wins %d  ·  Best %d XP" % [meta.runs, meta.wins, meta.bestPoints], 14, UIK.INK_DIM)
		v.add_child(foot)
	build.call(build)
	return box

# ---------------------------------------------------------------- Help
static func help(ui) -> Control:
	var p := UIK.panel()
	p.custom_minimum_size = Vector2(980, 0)
	var v := UIK.vbox(10)
	p.add_child(v)
	v.add_child(UIK.header("How to play", 28))
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(960, 520)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var c := UIK.vbox(10)
	c.custom_minimum_size.x = 930
	sc.add_child(c)
	var para := func(bb: String) -> void:
		var r := UIK.rich(bb, 16)
		r.custom_minimum_size.x = 920
		c.add_child(r)
	para.call("[b]Each round[/b]: drop your balls through the pegs and bank XP. Then spend 99 XP per level on any hero (L), change gear (C), set each hero to Attack, Skill or Guard, and Fight. Foes always show what they will do next.")
	c.add_child(UIK.label("Hidden pockets", 20, UIK.GOLD, "head"))
	para.call("All six pockets look the same. A fresh set is rolled at every launch and revealed only when the ball lands. Stages 1 to 3 roll 4 perks and 2 bad; from stage 4 it is 3 and 3. Jam never rolls on the last ball.")
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 4)
	c.add_child(grid)
	for k in D.POCKETS:
		var P: Dictionary = D.POCKETS[k]
		var row := UIK.hbox(8)
		row.custom_minimum_size.x = 450
		var ic := UIK.icon("pocket_" + k, 1)
		row.add_child(ic)
		var nm := UIK.label(P.name, 16, UIK.GOOD if P.kind == "perk" else UIK.BAD, "bold")
		nm.custom_minimum_size.x = 90
		row.add_child(nm)
		var tx := UIK.label(P.text, 15, UIK.INK)
		tx.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(tx)
		grid.add_child(row)
	c.add_child(UIK.label("Pegs", 20, UIK.GOLD, "head"))
	var pg := GridContainer.new()
	pg.columns = 2
	pg.add_theme_constant_override("h_separation", 20)
	c.add_child(pg)
	for k in D.PEGS:
		var Pd: Dictionary = D.PEGS[k]
		var r2 := UIK.rich("[color=%s]%s[/color] [b]%s[/b] (%d)  %s" % [Pd.color, PEG_ICON.get(k, "●"), Pd.name, Pd.pts, Pd.rule], 15)
		r2.custom_minimum_size.x = 450
		pg.add_child(r2)
	c.add_child(UIK.label("Scoring", 20, UIK.GOLD, "head"))
	para.call("A peg pays on its first hit (crates and chests pay every hit). Points = peg value × stage payout (×3 at the start, +1 every three stages) × multiplier, where multiplier = 1 + combo ÷ 8, rounded down. Every point is XP.")
	c.add_child(UIK.label("Controls", 20, UIK.GOLD, "head"))
	para.call("Mouse: move to aim, click to drop. Touch: drag to aim, release to drop. Click a foe to make it the target. Keys: ←/→ aim, Space drops a ball or starts the fight, 1/2/3 set Attack/Skill/Guard, Tab picks the next hero, L levels up, C opens equipment, Esc closes panels.")
	c.add_child(UIK.label("Credits", 20, UIK.GOLD, "head"))
	para.call("Made with Godot and Blender. Icons: Twemoji by Twitter, Inc. and contributors, CC-BY 4.0. Fonts: Cinzel and Alegreya Sans (SIL Open Font License), DejaVu (free licence).")
	var close := UIK.button("Close", func(): ui._close_modal(), true)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.custom_minimum_size.x = 180
	v.add_child(close)
	return p

# ---------------------------------------------------------------- Settings
static func settings(ui) -> Control:
	var G := S.G
	var p := UIK.panel()
	p.custom_minimum_size = Vector2(520, 0)
	var v := UIK.vbox(12)
	p.add_child(v)
	v.add_child(UIK.header("Settings", 28))
	var s: Dictionary = Game.settings
	var slider := func(label: String, key: String, onkey: String) -> void:
		var row := UIK.hbox(10)
		v.add_child(row)
		var ck := CheckBox.new()
		ck.text = label
		ck.button_pressed = s[onkey]
		ck.focus_mode = Control.FOCUS_NONE
		ck.custom_minimum_size.x = 150
		ck.toggled.connect(func(x): Game.set_settings({onkey: x}))
		row.add_child(ck)
		var sl := HSlider.new()
		sl.min_value = 0
		sl.max_value = 1
		sl.step = 0.05
		sl.value = s[key]
		sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		sl.focus_mode = Control.FOCUS_NONE
		sl.value_changed.connect(func(x): Game.set_settings({key: x}))
		row.add_child(sl)
	slider.call("Sound", "sfx", "sfxOn")
	slider.call("Music", "music", "musicOn")
	var rm := CheckBox.new()
	rm.text = "Reduced motion (no camera shake or drift)"
	rm.button_pressed = s.reducedMotion
	rm.focus_mode = Control.FOCUS_NONE
	rm.toggled.connect(func(x): Game.set_settings({"reducedMotion": x}))
	v.add_child(rm)
	if not G.is_empty() and not G.heroes.is_empty():
		var fast := CheckBox.new()
		fast.text = "Fast ball (2× speed)"
		fast.button_pressed = G.speed > 1
		fast.focus_mode = Control.FOCUS_NONE
		fast.toggled.connect(func(x): G.speed = 2 if x else 1)
		v.add_child(fast)
		var skip := CheckBox.new()
		skip.text = "Skip fight animations"
		skip.button_pressed = G.skipAnim
		skip.focus_mode = Control.FOCUS_NONE
		skip.toggled.connect(func(x): G.skipAnim = x)
		v.add_child(skip)
	v.add_child(UIK.sep())
	var row2 := UIK.hbox(10)
	v.add_child(row2)
	var in_run: bool = not G.is_empty() and G.phase != "title" and not G.heroes.is_empty()
	if in_run:
		var q := UIK.button("Main menu", func():
			ui.close_all()
			ui.show_title())
		q.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row2.add_child(q)
		UIK.tip(q, func(): return UIK.label("The run saves at the start of each stage.", 15))
	var close := UIK.button("Close", func():
		if ui.modal_kind == "settings" and not in_run:
			ui.show_title()
		else:
			ui._close_modal(), true)
	close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row2.add_child(close)
	return p

# ---------------------------------------------------------------- Draft
static func draft(ui) -> Control:
	var G := S.G
	var p := UIK.panel()
	p.custom_minimum_size = Vector2(1060, 0)
	var v := UIK.vbox(12)
	p.add_child(v)
	v.add_child(UIK.header("%s cleared" % D.STAGES[G.stage - 1].name, 30))
	var sub := "The party heals 30%. Pick one reward."
	if not G.stageDrops.is_empty():
		var names := []
		for it in G.stageDrops:
			names.append(it.name)
		sub += "  Foes dropped: " + ", ".join(names) + "."
	var sl := UIK.label(sub, 17, UIK.INK)
	sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sl.custom_minimum_size.x = 1000
	v.add_child(sl)
	var row := UIK.hbox(18)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	for i in G.rewards.size():
		row.add_child(_reward_card(ui, G.rewards[i], i))
	var foot := UIK.hbox(10)
	foot.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(foot)
	foot.add_child(UIK.button("Level up and equip first", func(): ui.hide_draft()))
	return p

static func _reward_card(ui, r: Dictionary, i: int) -> Control:
	var G := S.G
	var card := PanelContainer.new()
	var sb := UIK.nine("res://assets/ui/card.png", 6, 14)
	var tint := UIK.GOLD
	var kind := ""
	var icon := ""
	var name_ := ""
	var body := ""
	match r.kind:
		"gear":
			tint = UIK.rarity_color(r.item.rarity)
			kind = D.SLOT_NAMES[r.item.slot]
		"joker":
			var J: Dictionary = D.JOKERS[r.id]
			tint = Color(D.JOKER_RARITY_COLOR[J.rarity])
			kind = "%s joker" % String(J.rarity).capitalize()
			name_ = J.name
			body = J.text
		"pack":
			kind = "Peg pack"
			icon = "ui_sparkle"
			name_ = D.PEG_PACKS[r.id].name
			body = "%s on every board from now on." % D.PEG_PACKS[r.id].text
		"whetstone":
			kind = "Upgrade"
			icon = "ui_whetstone"
			name_ = "Whetstone"
			body = "+1 upgrade (+8% AR) to one hero's weapon, up to +10. Choose who:"
		"tankard":
			tint = Color("#6cb4ff")
			kind = "Rare"
			icon = "ui_trophy"
			name_ = "Golden Tankard"
			body = "Reset one hero's bought attributes and return the XP. Choose who:"
		"bed":
			kind = "Rest"
			icon = "ui_bed"
			name_ = "Warm Bed"
			body = "Every living hero heals 40% of max HP."
	sb.modulate_color = tint.lightened(0.1)
	card.add_theme_stylebox_override("panel", sb)
	card.custom_minimum_size = Vector2(320, 430)
	var v := UIK.vbox(8)
	card.add_child(v)
	var kl := UIK.label(kind.to_upper(), 14, tint, "head")
	kl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(kl)
	if r.kind == "joker":
		var jc: Control = ui._joker_card(r.id, 120)
		var holder := CenterContainer.new()
		holder.custom_minimum_size.y = 160
		holder.add_child(jc)
		v.add_child(holder)
	elif r.kind == "gear":
		var holder2 := CenterContainer.new()
		holder2.add_child(UIK.item_icon(r.item, 84))
		v.add_child(holder2)
		v.add_child(UIK.item_tip(r.item, G.heroes[G.selHero]))
	else:
		var ic := UIK.icon(icon, 4)
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(ic)
	if name_ != "":
		var nl := UIK.label(name_, 24, UIK.INK, "head", 4)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(nl)
	if body != "":
		var bl := UIK.label(body, 16, UIK.INK)
		bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		bl.custom_minimum_size.x = 290
		v.add_child(bl)
	var push := Control.new()
	push.size_flags_vertical = Control.SIZE_EXPAND_FILL
	push.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(push)
	if r.kind == "whetstone" or r.kind == "tankard":
		var hr := UIK.vbox(4)
		v.add_child(hr)
		for hi in G.heroes.size():
			var h: Dictionary = G.heroes[hi]
			var t: String = h.name
			if r.kind == "whetstone":
				t += ("  (weapon +%d)" % h.gear.weapon.upg) if h.gear.weapon != null else "  (no weapon)"
			else:
				t += "  (Lv %d)" % h.level
			var b := UIK.button(t, func():
				ui.close_all()
				Game.pick_reward(i, hi))
			b.disabled = r.kind == "whetstone" and (h.gear.weapon == null or h.gear.weapon.upg >= 10)
			hr.add_child(b)
	else:
		var take := UIK.button("Take", func():
			ui.close_all()
			Game.pick_reward(i), true, 20)
		take.custom_minimum_size.y = 48
		v.add_child(take)
	return card

# ---------------------------------------------------------------- End
static func end_screen(ui, win: bool, legs: Array, newly: Array) -> Control:
	var G := S.G
	var s: Dictionary = G.stats
	var p := UIK.panel()
	p.custom_minimum_size = Vector2(880, 0)
	var v := UIK.vbox(12)
	p.add_child(v)
	var t := UIK.label("Paid in full!" if win else "Evicted", 64, UIK.GOLD if win else UIK.BAD, "title", 10)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var sub := UIK.label("The Landlord falls. The pub is yours." if win else "Your party fell in %s." % D.STAGES[G.stage - 1].name, 20, UIK.INK, "bold")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	v.add_child(grid)
	for e in [["ui_xp", s.points, "XP scored"], ["ui_star", s.bestCombo, "Best combo"], ["ui_attack", s.dmg, "Damage dealt"], ["ui_sparkle", s.pegs, "Pegs broken"],
			["ui_pack", s.gear, "Gear found"], ["ui_crown", s.stages, "Stages cleared"], ["ui_skull", s.kills, "Foes downed"], ["ui_scroll", G.jokers.size(), "Jokers"]]:
		var tile := UIK.panel(true)
		tile.custom_minimum_size = Vector2(200, 0)
		var tv := UIK.hbox(8)
		tile.add_child(tv)
		tv.add_child(UIK.icon(e[0], 1))
		var nv := UIK.vbox(-4)
		tv.add_child(nv)
		nv.add_child(UIK.label(str(e[1]), 26, UIK.LOOT, "head"))
		nv.add_child(UIK.label(e[2], 13, UIK.INK_DIM))
		grid.add_child(tile)
	if not legs.is_empty():
		v.add_child(UIK.label("The Landlord dropped", 18, UIK.GOLD, "head"))
		for it in legs:
			var r := UIK.rich("[color=#ffa04a]%s[/color]  %s" % [it.name, D.legendary(it.legend).text], 16)
			r.custom_minimum_size.x = 840
			v.add_child(r)
	if not newly.is_empty():
		v.add_child(UIK.label("Unlocked: %s." % ", ".join(newly), 18, UIK.GOOD, "bold"))
	var sd := UIK.label("Seed %s. Share it so a friend can race the same boards and rewards." % G.seed, 15, UIK.INK_DIM)
	sd.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sd)
	var row := UIK.hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	var party := []
	for h in G.heroes:
		party.append(h.cls)
	var nb := UIK.button("New run", func():
		ui.close_all()
		Game.set_phase("title")
		ui.show_title(), true, 20)
	nb.custom_minimum_size.x = 200
	row.add_child(nb)
	var seed_: String = G.seed
	row.add_child(UIK.button("Same seed", func():
		ui.close_all()
		Game.new_run(seed_, party)))
	return p
