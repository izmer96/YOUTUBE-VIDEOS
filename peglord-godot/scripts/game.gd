extends Node
## Run flow (autoload "Game"): rounds, pockets, levelling, gear, rewards, save and meta progress. Ported from game.js.

const SAVE_PATH := "user://peglord_save.txt"
const META_PATH := "user://peglord_meta.txt"
const SETTINGS_PATH := "user://peglord_settings.txt"

var settings := {"sfx": 0.7, "music": 0.45, "sfxOn": true, "musicOn": true, "reducedMotion": false}
var meta := {"wins": 0, "runs": 0, "unlocked": [], "startJoker": false, "bestPoints": 0}
var board: BoardSim = BoardSim.new()
var new_joker := ""

var G: Dictionary:
	get: return S.G

func _ready() -> void:
	var s = _load(SETTINGS_PATH)
	if s is Dictionary:
		settings.merge(s, true)
	var m = _load(META_PATH)
	if m is Dictionary:
		meta.merge(m, true)
	S.G = blank_state("")

func _load(path: String):
	if not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var txt := f.get_as_text()
	if txt.is_empty():
		return null
	return str_to_var(txt)

func _store(path: String, v) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string(var_to_str(v))

func _del(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

func blank_state(seed_text: String) -> Dictionary:
	return {
		"seed": seed_text, "stage": 1, "round": 1, "phase": "title", "bank": 0, "heroes": [], "pack": [], "jokers": [], "pegExtras": {},
		"foes": [], "target": -1, "selHero": 0, "pending": [], "mods": {"guard": 0, "curse": 0, "rust": 0, "rally": 0, "whet": 0, "chalkUsed": false},
		"balls": 0, "ballNo": 0, "hotNext": false, "speed": 1, "skipAnim": false, "stageDrops": [], "rewards": [], "acting": "",
		"stats": {"points": 0, "bestCombo": 0, "dmg": 0, "pegs": 0, "gear": 0, "kills": 0, "stages": 0, "rounds": 0},
	}

func set_phase(p: String) -> void:
	G.phase = p
	Bus.phase_changed.emit(p)

func new_run(seed_text: String = "", party: Array = [], start_joker: bool = false) -> void:
	seed_text = seed_text.strip_edges().to_upper()
	if seed_text == "":
		seed_text = Rng.random_seed_string()
	S.rng.set_seed(seed_text)
	S.next_id = 1
	S.G = blank_state(seed_text)
	if party.is_empty():
		party = D.DEFAULT_PARTY
	for cls in party:
		G.heroes.append(S.make_hero(cls))
	if start_joker:
		var commons := D.JOKERS.keys().filter(func(k): return D.JOKERS[k].rarity == "common")
		G.jokers.append(S.rng.pick(commons))
	meta.runs += 1
	_store(META_PATH, meta)
	Battle.setup_stage()
	Bus.new_run.emit()
	start_round()
	Bus.log_msg.emit("Run %s begins in %s." % [seed_text, D.STAGES[0].name], "")

func start_round() -> void:
	G.mods = {"guard": 0, "curse": 0, "rust": 0, "rally": 0, "whet": 0, "chalkUsed": false}
	G.balls = D.BASE_BALLS + (1 if S.has_joker("sparekey") else 0) + (2 if S.has_joker("happyhour") and G.round == 1 else 0)
	if S.has_joker("sparekey"):
		Bus.pulse_joker.emit("sparekey")
	if S.has_joker("happyhour") and G.round == 1:
		Bus.pulse_joker.emit("happyhour")
	G.ballNo = 0
	G.stats.rounds += 1
	if S.has_joker("secondwind"):
		for h in G.heroes:
			Battle.heal(h, 3)
		Bus.pulse_joker.emit("secondwind")
	if S.has_joker("bartab"):
		G.bank += 10
		Bus.pulse_joker.emit("bartab")
	for h in G.heroes:
		if not h.dead and h.cmd == "skill" and not Battle.skill_ready(h):
			h.cmd = "attack"
	board.build()
	set_phase("aim")
	Bus.refresh.emit()

func apply_pocket(type: String, ball: Dictionary) -> void:
	var P: Dictionary = D.POCKETS[type]
	Bus.log_msg.emit("Pocket %s: %s." % [P.name, P.text], "good" if P.kind == "perk" else "bad")
	if P.kind == "bad":
		if S.has_joker("debt"):
			G.bank += 6
			G.stats.points += 6
			Bus.pulse_joker.emit("debt")
			Bus.log_msg.emit("Debt Collector pays 6.", "good")
		if S.has_joker("chalk") and not G.mods.chalkUsed:
			G.mods.chalkUsed = true
			Bus.pulse_joker.emit("chalk")
			Sfx.play("ui")
			Bus.log_msg.emit("Chalk Dust cancels it.", "good")
			Bus.refresh.emit()
			return
		Sfx.play("bad")
	else:
		Sfx.play("perk")
		if S.has_joker("tipjar"):
			G.bank += 3
			G.stats.points += 3
			Bus.pulse_joker.emit("tipjar")
	match type:
		"jackpot":
			var v: int = 6 + 2 * G.stage
			if S.has_joker("fever"):
				v *= 2
				Bus.pulse_joker.emit("fever")
			G.bank += v
			G.stats.points += v
		"double":
			G.bank += ball.pts
			G.stats.points += ball.pts
		"freeball": G.balls += 1
		"patch": Battle.heal_weakest(5, "Patch Up")
		"guard": G.mods.guard = 1
		"treasure":
			var it := S.drop_item()
			Bus.log_msg.emit("Treasure: %s." % it.name, "loot")
		"rally": G.mods.rally += 2
		"hotball": G.hotNext = true
		"taxman": G.bank = maxi(0, G.bank - 6)
		"leaky": G.bank = maxi(0, G.bank - int(floor(ball.pts / 2.0)))
		"curse": G.mods.curse = 1
		"rust": G.mods.rust += 1
		"plague":
			for h in G.heroes:
				if not h.dead:
					h.hp = maxi(1, h.hp - 2)
					Bus.unit_fx.emit("hero", h.id, "2", "dmg")
		"jam": G.balls = maxi(0, G.balls - 1)
	Bus.refresh.emit()

func after_ball() -> void:
	if G.balls > 0:
		set_phase("aim")
	else:
		G.pending = []
		set_phase("alloc")
		Bus.log_msg.emit("Bank %d XP. Level up, set commands, then Fight." % G.bank, "")
	Bus.refresh.emit()

# ---------- Levelling ----------
func can_manage() -> bool:
	return not G.is_empty() and (G.phase == "alloc" or G.phase == "draft")

func buy_level(h: Dictionary, attr: String, n: int = 1) -> bool:
	if not can_manage():
		return false
	var bought := 0
	for i in n:
		if G.bank < D.LEVEL_COST or h.level >= D.LEVEL_CAP:
			break
		var before: int = S.hero_stats(h).maxHp
		G.bank -= D.LEVEL_COST
		h.bought[attr] += 1
		h.level += 1
		G.pending.append({"hid": h.id, "attr": attr})
		var after: int = S.hero_stats(h).maxHp
		if not h.dead:
			h.hp += maxi(0, after - before)
		if S.legend(h, "rentboots") and not h.dead:
			h.hp = mini(after, h.hp + 5)
		bought += 1
	Sfx.play("levelup" if bought else "deny")
	Bus.refresh.emit()
	return bought > 0

func refund_level(h: Dictionary, attr: String) -> void:
	if not can_manage():
		return
	var idx := -1
	for i in G.pending.size():
		if G.pending[i].hid == h.id and G.pending[i].attr == attr:
			idx = i
	if idx < 0:
		Sfx.play("deny")
		return
	G.pending.remove_at(idx)
	G.bank += D.LEVEL_COST
	h.bought[attr] -= 1
	h.level -= 1
	h.hp = mini(h.hp, S.hero_stats(h).maxHp)
	Sfx.play("ui")
	Bus.refresh.emit()

func pending_for(h: Dictionary, attr: String) -> int:
	var n := 0
	for p in G.pending:
		if p.hid == h.id and p.attr == attr:
			n += 1
	return n

func confirm_levels() -> void:
	G.pending = []
	Bus.refresh.emit()

func auto_level() -> void:
	if not can_manage():
		return
	var n := 0
	while G.bank >= D.LEVEL_COST:
		var cands: Array = G.heroes.filter(func(x): return x.level < D.LEVEL_CAP)
		if cands.is_empty():
			break
		var h = cands[0]
		for c in cands:
			if c.level < h.level:
				h = c
		if not buy_level(h, D.auto_attr(h), 1):
			break
		n += 1
	Bus.log_msg.emit(("Auto-level bought %d level%s." % [n, "s" if n > 1 else ""]) if n else "Not enough XP for a level.", "")
	Bus.refresh.emit()

# ---------- Gear ----------
func equip(h: Dictionary, it: Dictionary) -> void:
	if not can_manage():
		return
	var idx: int = G.pack.find(it)
	if idx < 0:
		return
	var before: int = S.hero_stats(h).maxHp
	G.pack.remove_at(idx)
	if h.gear[it.slot] != null:
		G.pack.append(h.gear[it.slot])
	h.gear[it.slot] = it
	var after: int = S.hero_stats(h).maxHp
	if not h.dead:
		h.hp = clampi(h.hp + maxi(0, after - before), 1, after)
	Sfx.play("equip")
	Bus.refresh.emit()

func unequip(h: Dictionary, slot: String) -> void:
	if not can_manage() or h.gear[slot] == null:
		return
	G.pack.append(h.gear[slot])
	h.gear[slot] = null
	h.hp = mini(h.hp, S.hero_stats(h).maxHp)
	Sfx.play("equip")
	Bus.refresh.emit()

func salvage_value(it: Dictionary) -> int:
	var xp: int = D.RARITIES[it.rarity].salvage
	for h in G.heroes:
		if S.legend(h, "pawnshark"):
			return xp * 2
	return xp

func salvage(it: Dictionary) -> void:
	if not can_manage() or it.locked:
		return
	var idx: int = G.pack.find(it)
	if idx < 0:
		return
	G.pack.remove_at(idx)
	var xp := salvage_value(it)
	G.bank += xp
	Bus.log_msg.emit("Salvaged %s for %d XP." % [it.name, xp], "loot")
	Sfx.play("crateBreak")
	Bus.refresh.emit()

# ---------- Fight ----------
func fight() -> void:
	if G.phase != "alloc":
		return
	confirm_levels()
	Sfx.play("ui")
	Battle.resolve()

func next_round() -> void:
	G.round += 1
	start_round()

func stage_cleared() -> void:
	G.stats.stages += 1
	for h in G.heroes:
		var mx: int = S.hero_stats(h).maxHp
		if h.dead:
			h.dead = false
			h.hp = ceili(mx * D.STAGE_HEAL)
		else:
			h.hp = mini(mx, h.hp + ceili(mx * D.STAGE_HEAL))
		h.used = {"laststand": false, "overcast": false, "resurrect": false}
		h.cd = 0
		h.hex = 0
		h.shield = 0
	if D.STAGES[G.stage - 1].get("boss", false):
		victory()
		return
	Sfx.play("win")
	Bus.log_msg.emit("%s cleared! Party heals 30%%." % D.STAGES[G.stage - 1].name, "good")
	G.pending = []
	G.rewards = make_rewards()
	set_phase("draft")
	Bus.refresh.emit()
	Bus.show_draft.emit()

func roll_joker(exclude: Array = []) -> String:
	var pool := D.JOKERS.keys().filter(func(k): return not G.jokers.has(k) and not exclude.has(k))
	if pool.is_empty():
		return ""
	var w := pool.map(func(k): return D.JOKER_RARITY_WEIGHT[D.JOKERS[k].rarity])
	return pool[S.rng.weighted(w)]

func make_rewards() -> Array:
	var free: bool = G.jokers.size() < D.MAX_JOKERS
	var pool := [{"kind": "gear"}, {"kind": "gear"}]
	if free:
		pool.append({"kind": "joker"})
		pool.append({"kind": "joker"})
	var packs := S.rng.shuffle(D.PEG_PACKS.keys())
	pool.append({"kind": "pack", "id": packs[0]})
	pool.append({"kind": "pack", "id": packs[1]})
	pool.append({"kind": "whetstone"})
	pool.append({"kind": "bed"})
	if S.rng.chance(D.TANKARD_CHANCE):
		pool.append({"kind": "tankard"})
	var picks := [pool.pop_front()]
	if free:
		for i in pool.size():
			if pool[i].kind == "joker":
				picks.append(pool[i])
				pool.remove_at(i)
				break
	S.rng.shuffle(pool)
	while picks.size() < 3 and not pool.is_empty():
		picks.append(pool.pop_front())
	var used := []
	for p in picks:
		if p.kind == "gear":
			p.item = S.gen_item(G.stage, S.roll_rarity(G.stage))
		if p.kind == "joker":
			var j := roll_joker(used)
			if j == "":
				p.kind = "bed"
			else:
				used.append(j)
				p.id = j
	return picks

func pick_reward(i: int, hero_idx: int = -1) -> void:
	if G.phase != "draft" or G.rewards.is_empty():
		return
	var r: Dictionary = G.rewards[i]
	var h: Dictionary = G.heroes[hero_idx if hero_idx >= 0 else G.selHero]
	match r.kind:
		"gear":
			G.pack.append(r.item)
			G.stats.gear += 1
			Bus.log_msg.emit("Took %s." % r.item.name, "loot")
		"joker":
			G.jokers.append(r.id)
			Sfx.play("joker")
			Bus.log_msg.emit("Joker gained: %s." % D.JOKERS[r.id].name, "good")
			new_joker = r.id
		"pack":
			var add: Dictionary = D.PEG_PACKS[r.id].add
			for k in add:
				G.pegExtras[k] = G.pegExtras.get(k, 0) + add[k]
			Bus.log_msg.emit("Peg pack: %s." % D.PEG_PACKS[r.id].name, "good")
		"whetstone":
			var w = h.gear.weapon
			if w == null or w.upg >= 10:
				Sfx.play("deny")
				return
			w.upg += 1
			Bus.log_msg.emit("%s is now +%d." % [w.name, w.upg], "good")
			Sfx.play("equip")
		"tankard":
			var n := 0
			for a in D.ATTRS:
				n += h.bought[a]
				h.bought[a] = 0
			h.level = 1
			G.bank += n * D.LEVEL_COST
			h.hp = mini(h.hp, S.hero_stats(h).maxHp)
			Bus.log_msg.emit("Golden Tankard: %s respecs, %d XP returned." % [h.name, n * D.LEVEL_COST], "good")
		"bed":
			for x in G.heroes:
				if not x.dead:
					Battle.heal(x, ceili(S.hero_stats(x).maxHp * D.WARM_BED_HEAL))
			Bus.log_msg.emit("Warm Bed: party heals 40%.", "good")
	if r.kind != "joker":
		Sfx.play("perk")
	G.rewards = []
	G.stage += 1
	G.round = 1
	G.pending = []
	save()
	Battle.setup_stage()
	Bus.log_msg.emit("Stage %d: %s." % [G.stage, D.STAGES[G.stage - 1].name], "")
	Bus.new_run.emit()
	start_round()

func defeat() -> void:
	set_phase("over")
	_del(SAVE_PATH)
	meta.bestPoints = maxi(meta.bestPoints, G.stats.points)
	_store(META_PATH, meta)
	Sfx.play("lose")
	Bus.show_end.emit(false, [], [])

func victory() -> void:
	set_phase("over")
	_del(SAVE_PATH)
	meta.wins += 1
	var newly := []
	for k in ["rogue", "ranger"]:
		if not meta.unlocked.has(k):
			meta.unlocked.append(k)
			newly.append(D.HEROES[k].name)
	if not meta.startJoker:
		meta.startJoker = true
		newly.append("a starting joker")
	meta.bestPoints = maxi(meta.bestPoints, G.stats.points)
	_store(META_PATH, meta)
	var legs := []
	var ls := S.rng.shuffle(D.LEGENDARIES.duplicate())
	for i in 3:
		legs.append(S.gen_item(G.stage, 4, ls[i].slot, {"legend": ls[i].id}))
	Sfx.play("win")
	Bus.show_end.emit(true, legs, newly)

# ---------- Save and resume ----------
func save() -> void:
	_store(SAVE_PATH, {"v": 1, "seed": G.seed, "rng": S.rng.s, "nextId": S.next_id, "stage": G.stage, "round": G.round, "bank": G.bank,
		"heroes": G.heroes, "pack": G.pack, "jokers": G.jokers, "pegExtras": G.pegExtras, "stats": G.stats, "speed": G.speed, "skipAnim": G.skipAnim})

func has_save() -> bool:
	return _load(SAVE_PATH) is Dictionary

func resume() -> bool:
	var d = _load(SAVE_PATH)
	if not d is Dictionary:
		return false
	S.G = blank_state(d.seed)
	for k in ["stage", "round", "bank", "heroes", "pack", "jokers", "pegExtras", "stats", "speed", "skipAnim"]:
		G[k] = d[k]
	S.rng.s = d.rng
	S.next_id = d.nextId
	Battle.setup_stage()
	Bus.new_run.emit()
	start_round()
	Bus.log_msg.emit("Resumed run %s at %s." % [G.seed, D.STAGES[G.stage - 1].name], "")
	return true

func set_settings(p: Dictionary) -> void:
	settings.merge(p, true)
	_store(SETTINGS_PATH, settings)
	Sfx.apply(settings)
