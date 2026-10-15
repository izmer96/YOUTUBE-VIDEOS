extends Node
## Turn-based combat (autoload "Battle"). Ported from battle.js; visuals go out through Bus.

var G: Dictionary:
	get: return S.G

func _sleep(sec: float) -> void:
	await get_tree().create_timer(sec).timeout

func _wait() -> void:
	var t := 0.09 if G.skipAnim else D.ANIM_STEP / (1.6 if G.speed > 1 else 1.0)
	await _sleep(t)

func living(arr: Array) -> Array:
	return arr.filter(func(u): return not u.dead)

# ---------- Foes ----------
func make_foe(type: String, stage: int, fname: String = "") -> Dictionary:
	var E: Dictionary = D.ENEMIES[type]
	return {
		"id": S.uid(), "type": type, "name": fname if fname != "" else E.name,
		"maxHp": roundi(E.hp * (1 + D.ENEMY_HP_SCALE * (stage - 1))),
		"atk": roundi(E.atk * (1 + D.ENEMY_ATK_SCALE * (stage - 1))),
		"armor": E.armor, "moves": E.moves.duplicate(), "moveIdx": S.rng.randi_n(E.moves.size()), "dead": false,
		"burn": 0, "burnTurns": 0, "mark": false, "pin": 0, "minion": false, "boss": false, "phase2": false, "hp": 0,
	}

func setup_stage() -> void:
	var st: Dictionary = D.STAGES[G.stage - 1]
	var foes := []
	if st.get("boss", false):
		var boss := {"id": S.uid(), "type": "boss", "name": D.BOSS.name, "maxHp": D.BOSS.hp, "atk": D.BOSS.atk, "armor": D.BOSS.armor,
			"moves": D.BOSS.moves.duplicate(), "moveIdx": 0, "dead": false, "burn": 0, "burnTurns": 0, "mark": false, "pin": 0,
			"boss": true, "phase2": false, "minion": false, "hp": 0}
		for m in D.BOSS.minions:
			var f := make_foe(m.type, m.stage, m.name)
			f.minion = true
			foes.append(f)
		foes.insert(1, boss)
	else:
		var theme: Array = S.rng.pick(st.themes)
		var types := []
		if theme.size() > 3:
			while true:
				types = [S.rng.pick(theme), S.rng.pick(theme), S.rng.pick(theme)]
				if not types.all(func(t): return t == "shaman"):
					break
		else:
			types = S.rng.shuffle(theme.duplicate())
		for t in types:
			foes.append(make_foe(t, G.stage))
		var seen := {}
		for f in foes:
			seen[f.name] = seen.get(f.name, 0) + 1
		var count := {}
		for f in foes:
			if seen[f.name] > 1:
				count[f.name] = count.get(f.name, 0) + 1
				if count[f.name] > 1:
					f.name += " " + "ABC"[count[f.name] - 1]
	for f in foes:
		f.hp = f.maxHp
	G.foes = foes
	G.target = living(foes)[0].id

func foe_attack(f: Dictionary) -> int:
	var a: float = f.atk + D.RENT_HIKE_PER_ROUND * (G.round - 1)
	if G.mods.get("curse", 0):
		a += D.CURSE_ATK
	if S.has_joker("glasscannon"):
		a *= D.GLASS_CANNON_FOE
	a -= f.pin
	if G.mods.get("guard", 0):
		a -= D.GUARD_POCKET
	return maxi(1, roundi(a))

func intent_of(f: Dictionary) -> Dictionary:
	return D.MOVES[f.moves[f.moveIdx % f.moves.size()]]

func intent_value(f: Dictionary) -> int:
	var m := intent_of(f)
	var atk := foe_attack(f)
	if m.name == "Mend":
		return roundi(1.5 * atk + 3)
	return maxi(1, roundi(atk * m.mult))

func intent_label(f: Dictionary) -> String:
	var m := intent_of(f)
	var v := intent_value(f)
	var tgt: String = {"one": "", "lowest": " (weakest)", "all": " (all)", "ally": " (heal)"}[m.target]
	return "%s %d%s%s" % [m.name, v, ("×%d" % m.hits) if m.has("hits") else "", tgt]

# ---------- Heroes ----------
func priest_blessing() -> int:
	for h in G.heroes:
		if h.cls == "priest" and not h.dead:
			return S.hero_stats(h).blessing
	return 0

func weakest_hero(include_dead: bool = false):
	var best = null
	var best_r := 99.0
	for h in G.heroes:
		if not include_dead and h.dead:
			continue
		var r: float = float(h.hp) / S.hero_stats(h).maxHp
		if best == null or r < best_r:
			best = h
			best_r = r
	return best

func heal(h, amt: int, src: String = "") -> int:
	if h == null or h.dead:
		return 0
	var st := S.hero_stats(h)
	var before: int = h.hp
	h.hp = mini(st.maxHp, h.hp + amt)
	var over: int = amt - (h.hp - before)
	var pr = null
	for x in G.heroes:
		if x.cls == "priest" and not x.dead and S.has_perk(x, 24):
			pr = x
	if over > 0 and pr != null and src == "mend":
		h.shield = maxi(h.shield, over)
	var got: int = h.hp - before
	if got > 0:
		Bus.unit_fx.emit("hero", h.id, "+%d" % got, "heal")
		Bus.effect.emit("hero", h.id, "heal")
	return got

func heal_weakest(amt: int, src: String) -> void:
	var h = weakest_hero(false)
	if h == null:
		return
	var got := heal(h, amt, src)
	Bus.log_msg.emit(("%s: %s heals %d." % [src, h.name, got]) if got else ("%s: everyone is already at full HP." % src), "good")
	Bus.refresh.emit()

func hero_is_taunting(h: Dictionary) -> bool:
	return not h.dead and (h.guarding or (h.cls == "knight" and S.has_perk(h, 24)))

func current_target():
	for f in G.foes:
		if f.id == G.target and not f.dead:
			return f
	var alive := living(G.foes)
	if alive.is_empty():
		return null
	G.target = alive[0].id
	return alive[0]

func _top_hp_foe():
	var top = null
	for f in living(G.foes):
		if top == null or f.hp > top.hp:
			top = f
	return top

func hit_foe(h: Dictionary, foe, mult: float, opts: Dictionary = {}) -> int:
	if foe == null or foe.dead:
		return 0
	var st := S.hero_stats(h)
	var type: String = opts.get("type", st.dmgType)
	var ar: float = st.ar * mult
	if type == "magic" and opts.get("type", "") == "magic" and st.dmgType != "magic" and h.cls == "mage":
		ar *= 1.15
	var crit := S.rng.chance(st.crit / 100.0)
	var k := (2.5 if S.legend(h, "nightcap") else 2.0) if crit else 1.0
	var raw: int = int(floor((ar + priest_blessing()) * k)) + G.mods.rally + G.mods.whet - G.mods.rust
	if st.bounty and _top_hp_foe() == foe:
		raw = int(floor(raw * (1 + st.bounty / 100.0)))
	if h.cls == "ranger" and S.has_perk(h, 24) and _top_hp_foe() == foe:
		raw = int(floor(raw * 1.25))
	if h.cls == "rogue" and S.has_perk(h, 36) and foe.hp < foe.maxHp * 0.3:
		raw *= 2
	if foe.mark:
		raw = int(floor(raw * 1.2))
	var armor: int = foe.armor if type == "phys" else int(floor(foe.armor / 2.0))
	if h.cls == "ranger":
		armor = maxi(0, armor - 2)
	var dmg := maxi(1, raw - armor)
	foe.hp = maxi(0, foe.hp - dmg)
	G.stats.dmg += dmg
	Bus.unit_fx.emit("foe", foe.id, ("CRIT %d" % dmg) if crit else str(dmg), "crit" if crit else "dmg")
	Sfx.play("crit" if crit else ("zap" if type == "magic" else "slash"))
	if not opts.get("firebolt", false):
		Bus.effect.emit("foe", foe.id, "slash" if type == "phys" else ("zap" if type == "magic" else "holy"))
	Bus.unit_anim.emit("foe", foe.id, "hit")
	if crit and h.cls == "mage" and opts.get("firebolt", false) and S.has_perk(h, 16):
		foe.burn = 3
		foe.burnTurns = 3
		Bus.log_msg.emit("%s is burning." % foe.name, "")
	if crit and h.cls == "rogue" and S.has_perk(h, 8):
		foe.burn = 3
		foe.burnTurns = 3
		Bus.log_msg.emit("%s is bleeding." % foe.name, "")
	if st.leech:
		heal(h, st.leech)
	if S.legend(h, "tapmaster"):
		var w = weakest_hero(false)
		if w != null:
			heal(w, maxi(1, int(floor(dmg * 0.1))))
	after_foe_damage(foe, h)
	if S.legend(h, "gavel") and not opts.get("splash", false):
		for o in living(G.foes):
			if o != foe:
				o.hp = maxi(0, o.hp - 3)
				G.stats.dmg += 3
				Bus.unit_fx.emit("foe", o.id, "3", "dmg")
				after_foe_damage(o, h)
	return dmg

func after_foe_damage(foe: Dictionary, h) -> void:
	if foe.boss and not foe.phase2 and foe.hp > 0 and foe.hp <= foe.maxHp / 2.0:
		foe.phase2 = true
		foe.moves = D.BOSS.phase2Moves.duplicate()
		foe.moveIdx = 0
		foe.armor += D.BOSS.phase2Armor
		foe.atk += D.BOSS.phase2Atk
		Bus.log_msg.emit("The Landlord tears up the lease! Phase two: Foreclosure.", "bad")
		Bus.boss_phase2.emit()
		Sfx.play("bad")
	if foe.hp <= 0 and not foe.dead:
		foe.dead = true
		Sfx.play("kill")
		Bus.log_msg.emit("%s is down." % foe.name, "good")
		G.stats.kills += 1
		if not foe.boss:
			var ch: float = (D.MINION_DROP if foe.minion else D.DROP_CHANCE) + S.party_luck()
			if S.rng.chance(ch):
				var it := S.drop_item()
				G.stageDrops.append(it)
				Bus.log_msg.emit("%s dropped %s." % [foe.name, it.name], "loot")
		if h != null and S.legend(h, "lastcall") and G.acting == "firebolt":
			h.cd = 0
			Bus.log_msg.emit("Last Call: Firebolt is ready again.", "good")
	Bus.refresh.emit()

func skill_ready(h: Dictionary) -> bool:
	if h.cd <= 0:
		return true
	return h.cls == "mage" and S.has_perk(h, 24) and not h.used.overcast

func hero_act(h: Dictionary) -> void:
	var st := S.hero_stats(h)
	var cmd: String = h.cmd
	var casting: bool = cmd == "skill" and (h.cls == "mage" or h.cls == "priest")
	if cmd == "guard":
		Bus.effect.emit("hero", h.id, "block")
	elif casting:
		Bus.cast.emit("hero", h.id)
	else:
		Bus.unit_anim.emit("hero", h.id, "lunge")
		if not G.skipAnim:
			await _sleep(0.22)
	if cmd == "guard":
		h.guarding = true
		Sfx.play("clank")
		heal(h, 2 + (4 if S.set_count(h, "bouncer") >= 4 else 0))
		Bus.log_msg.emit("%s guards." % h.name, "")
		return
	if cmd == "skill" and skill_ready(h):
		if h.cd > 0 and h.cls == "mage":
			h.used.overcast = true
		h.cd = st.cd
		G.acting = "skill"
		var tgt = current_target()
		match h.cls:
			"knight":
				Sfx.play("slash")
				for f in living(G.foes):
					hit_foe(h, f, 0.7)
				Bus.log_msg.emit("%s cleaves every foe." % h.name, "")
			"mage":
				G.acting = "firebolt"
				Sfx.play("fire")
				if tgt != null:
					Bus.projectile.emit("hero", h.id, "foe", tgt.id, "fire")
					await _sleep(0.06 if G.skipAnim else 0.38)
				var d := hit_foe(h, tgt, 2.2, {"type": "magic", "firebolt": true})
				if S.has_perk(h, 36):
					for f in living(G.foes):
						if f != tgt:
							hit_foe(h, f, 1.1, {"type": "magic", "splash": true})
				Bus.log_msg.emit("%s casts Firebolt for %d." % [h.name, d], "")
			"priest":
				var dead_h = null
				for x in G.heroes:
					if x.dead:
						dead_h = x
						break
				if dead_h != null and S.has_perk(h, 36) and not h.used.resurrect:
					h.used.resurrect = true
					dead_h.dead = false
					dead_h.hp = ceili(S.hero_stats(dead_h).maxHp * 0.4)
					Sfx.play("heal")
					Bus.effect.emit("hero", dead_h.id, "heal")
					Bus.log_msg.emit("%s resurrects %s!" % [h.name, dead_h.name], "good")
				else:
					var w = weakest_hero(false)
					if S.has_perk(h, 8) and w != null:
						w.hex = 0
					var got := heal(w, st.mendAmount, "mend")
					if S.set_count(h, "choir") >= 4 and w != null:
						w.defBuff = 3
					Sfx.play("heal")
					Bus.log_msg.emit("%s mends %s for %d." % [h.name, w.name, got], "good")
			"rogue":
				hit_foe(h, tgt, 1.1)
				if tgt != null and not tgt.dead:
					await _sleep(0.05 if G.skipAnim else 0.2)
					hit_foe(h, tgt, 1.1)
				Bus.log_msg.emit("%s twin-stabs %s." % [h.name, tgt.name], "")
			"ranger":
				var n := 2 if S.has_perk(h, 36) else 1
				for i in n:
					for f in living(G.foes):
						hit_foe(h, f, 0.6)
				Bus.log_msg.emit("%s looses a volley." % h.name, "")
		G.acting = ""
		return
	G.acting = "attack"
	var t2 = current_target()
	if t2 == null:
		return
	var d2 := hit_foe(h, t2, 1.0)
	Bus.log_msg.emit("%s hits %s for %d." % [h.name, t2.name, d2], "")
	if h.cls == "mage" and S.has_perk(h, 8):
		for o in living(G.foes):
			if o != t2:
				hit_foe(h, o, 0.4, {"splash": true})
				break
	if h.cls == "priest" and S.has_perk(h, 16) and not t2.dead:
		t2.mark = true
	if h.cls == "ranger" and S.has_perk(h, 8) and not t2.dead:
		t2.pin = 1
	G.acting = ""

func damage_hero(h: Dictionary, atk: int, magic: bool, foe) -> int:
	if h.dead:
		return 0
	var st := S.hero_stats(h)
	if h.cls == "rogue" and S.has_perk(h, 24) and h.guarding and not h.dodged:
		h.dodged = true
		Bus.unit_fx.emit("hero", h.id, "Dodge", "block")
		return 0
	var DD: int = st.res if magic else st.def
	var kg := 0.5 if h.guarding else 1.0
	if h.guarding and h.gear.offhand != null and h.gear.offhand.get("offType", "") == "shield":
		kg *= 1.0 - D.SHIELD_BLOCK
	var dmg := maxi(1, int(floor(atk * 40.0 / (40 + DD) * kg)))
	var unguarded := maxi(1, int(floor(atk * 40.0 / (40 + DD))))
	if h.shield > 0:
		var a := mini(h.shield, dmg)
		h.shield -= a
		dmg -= a
		if a:
			Bus.unit_fx.emit("hero", h.id, "Shield %d" % a, "block")
	h.hp -= dmg
	if h.hp <= 0 and h.cls == "knight" and S.has_perk(h, 36) and not h.used.laststand:
		h.used.laststand = true
		h.hp = 1
		Bus.log_msg.emit("%s: Last Stand!" % h.name, "good")
	Bus.unit_fx.emit("hero", h.id, str(dmg), "block" if h.guarding else "dmg")
	Bus.unit_anim.emit("hero", h.id, "hit")
	if h.guarding:
		Bus.effect.emit("hero", h.id, "block")
	Sfx.play("clank" if h.guarding else "hurt")
	if foe != null and not foe.dead:
		var back: int = st.thorns
		if h.guarding and ((h.cls == "knight" and S.has_perk(h, 8)) or S.set_count(h, "bouncer") >= 4):
			back += int(floor(st.ar * 0.5))
		if h.guarding and S.legend(h, "bastion"):
			back += unguarded - dmg
		if back > 0:
			foe.hp = maxi(0, foe.hp - back)
			G.stats.dmg += back
			Bus.unit_fx.emit("foe", foe.id, str(back), "dmg")
			after_foe_damage(foe, h)
	if h.hp <= 0:
		h.hp = 0
		h.dead = true
		h.guarding = false
		Bus.log_msg.emit("%s falls!" % h.name, "bad")
		Sfx.play("lose")
	return dmg

func foe_act(f: Dictionary) -> void:
	var m := intent_of(f)
	var atk := foe_attack(f)
	var is_mend: bool = m.name == "Mend"
	if is_mend:
		Bus.cast.emit("foe", f.id)
	else:
		Bus.unit_anim.emit("foe", f.id, "lunge")
		if not G.skipAnim:
			await _sleep(0.22)
	if is_mend:
		var w = null
		for x in living(G.foes):
			if w == null or float(x.hp) / x.maxHp < float(w.hp) / w.maxHp:
				w = x
		var amt := roundi(1.5 * atk + 3)
		w.hp = mini(w.maxHp, w.hp + amt)
		Bus.unit_fx.emit("foe", w.id, "+%d" % amt, "heal")
		Bus.effect.emit("foe", w.id, "heal")
		Sfx.play("heal")
		Bus.log_msg.emit("%s mends %s for %d." % [f.name, w.name, amt], "bad")
	else:
		if m.get("rentHike", false):
			f.atk += 2
			Bus.log_msg.emit("Rent Hike: The Landlord gains +2 attack.", "bad")
		var alive := living(G.heroes)
		if alive.is_empty():
			return
		var targets := []
		if m.target == "all":
			targets = alive
		elif m.target == "lowest":
			var lo = alive[0]
			for x in alive:
				if x.hp < lo.hp:
					lo = x
			targets = [lo]
		else:
			var tt := alive.filter(hero_is_taunting)
			targets = [S.rng.pick(tt if not tt.is_empty() else alive)]
		if m.get("magic", false) and m.target == "all":
			Bus.effect.emit("hero", -1, "zap")
		var hits: int = m.get("hits", 1)
		for i in hits:
			if i > 0 and not G.skipAnim:
				await _sleep(0.2)
			for h in targets:
				if h.dead:
					continue
				if m.has("miss") and S.rng.chance(m.miss):
					Bus.unit_fx.emit("hero", h.id, "Miss", "block")
					Bus.log_msg.emit("%s swings wildly and misses." % f.name, "")
					continue
				var dd := damage_hero(h, maxi(1, roundi(atk * m.mult)), m.get("magic", false), f)
				if m.get("drain", false) and not f.dead:
					f.hp = mini(f.maxHp, f.hp + dd)
					Bus.unit_fx.emit("foe", f.id, "+%d" % dd, "heal")
				if m.get("hex", false) and not h.dead:
					h.hex = 2
				Bus.log_msg.emit("%s %ss %s for %d." % [f.name, m.name.to_lower(), h.name, dd], "bad")
	f.moveIdx += 1
	Bus.refresh.emit()

func resolve() -> void:
	G.phase = "resolve"
	Bus.phase_changed.emit("resolve")
	Bus.refresh.emit()
	await _sleep(0.05 if G.skipAnim else 0.7)  # let the camera settle on the fight
	for h in G.heroes:
		h.guarding = false
		h.dodged = false
		if not h.dead and h.cmd == "guard":
			h.guarding = true
	for h in G.heroes:
		if h.dead or living(G.foes).is_empty():
			continue
		if h.cmd == "skill" and not skill_ready(h):
			h.cmd = "attack"
		await hero_act(h)
		Bus.refresh.emit()
		await _wait()
	if not living(G.foes).is_empty():
		for f in G.foes:
			if f.dead or living(G.heroes).is_empty():
				continue
			await foe_act(f)
			await _wait()
	for f in G.foes:
		if not f.dead and f.burnTurns > 0:
			f.hp = maxi(0, f.hp - f.burn)
			f.burnTurns -= 1
			Bus.unit_fx.emit("foe", f.id, str(f.burn), "dmg")
			Bus.effect.emit("foe", f.id, "burn")
			G.stats.dmg += f.burn
			after_foe_damage(f, null)
		f.mark = false
		f.pin = 0
	for h in G.heroes:
		if not h.dead and h.hex > 0:
			h.hp = maxi(1, h.hp - 2)
			h.hex -= 1
			Bus.unit_fx.emit("hero", h.id, "2", "dmg")
		h.cd = maxi(0, h.cd - 1)
		h.guarding = false
		h.defBuff = 0
		if h.cmd == "skill":
			h.cmd = "attack"
	Bus.refresh.emit()
	await _sleep(0.05 if G.skipAnim else 0.5)
	if living(G.foes).is_empty():
		Game.stage_cleared()
	elif living(G.heroes).is_empty():
		Game.defeat()
	else:
		Game.next_round()
