extends Node
## Global run state, hero math and gear generation (autoload "S"). Ported from rules.js.

var G: Dictionary = {}
var rng := Rng.new()
var next_id := 1

func uid() -> int:
	next_id += 1
	return next_id - 1

func has_joker(id: String) -> bool:
	return not G.is_empty() and G.jokers.has(id)

# ---------- Hero math ----------
func soft_cap(a: float) -> float:
	if a <= D.SOFT_CAP_1:
		return a
	if a <= D.SOFT_CAP_2:
		return D.SOFT_CAP_1 + (a - D.SOFT_CAP_1) / 2.0
	return D.SOFT_CAP_1 + (D.SOFT_CAP_2 - D.SOFT_CAP_1) / 2.0 + (a - D.SOFT_CAP_2) / 4.0

func scale_curve(a: float) -> float:
	return a / 20.0 if a <= 20 else minf(2.0, 1.0 + (a - 20) / 40.0)

func make_hero(cls: String) -> Dictionary:
	var def: Dictionary = D.HEROES[cls]
	var h := {
		"id": uid(), "cls": cls, "name": def.name, "bought": {"vig": 0, "str": 0, "dex": 0, "int": 0, "fai": 0, "arc": 0},
		"level": 1, "hp": 1, "shield": 0, "gear": {}, "cmd": "attack", "cd": 0, "guarding": false, "dead": false,
		"hex": 0, "defBuff": 0, "dodged": false, "used": {"laststand": false, "overcast": false, "resurrect": false},
	}
	for s in D.SLOTS:
		h.gear[s] = null
	for fam in def.start:
		var it: Dictionary = gen_item(1, 0, "offhand", {"offType": "shield"}) if fam == "shield" else gen_item(1, 0, "weapon", {"family": fam})
		h.gear[it.slot] = it
	h.hp = hero_stats(h).maxHp
	return h

func has_perk(h: Dictionary, lvl: int) -> bool:
	return h.level >= lvl

func legend(h: Dictionary, id: String) -> bool:
	for s in D.SLOTS:
		var it = h.gear[s]
		if it != null and it.get("legend", "") == id:
			return true
	return false

func set_count(h: Dictionary, set_id: String) -> int:
	var n := 0
	for s in D.SET_SLOTS:
		var it = h.gear[s]
		if it != null and it.get("set", "") == set_id:
			n += 1
	return n

func main_stat(h: Dictionary) -> String:
	var w = h.gear.weapon
	if w == null:
		return "str"
	var best := ""
	for k in w.grades:
		if best == "" or D.GRADES[w.grades[k]] > D.GRADES[w.grades[best]]:
			best = k
	return best if best != "" else "str"

func total_attrs(h: Dictionary) -> Dictionary:
	var def: Dictionary = D.HEROES[h.cls]
	var a := {}
	for k in D.ATTRS:
		a[k] = def.attrs[k] + h.bought[k]
	for s in D.SLOTS:
		var it = h.gear[s]
		if it != null:
			for x in it.affixes:
				if x.type == "attr":
					a[x.attr] += x.value
	if has_joker("glasscannon"):
		a[main_stat(h)] += 1
	if has_joker("overclock"):
		var best := "vig"
		for k in D.ATTRS:
			if a[k] > a[best]:
				best = k
		a[best] += 2
	return a

func affix_sum(h: Dictionary, type: String) -> int:
	var v := 0
	for s in D.SLOTS:
		var it = h.gear[s]
		if it != null:
			for x in it.affixes:
				if x.type == type:
					v += x.value
	return v

func weapon_ar(h: Dictionary, w, attrs: Dictionary) -> Dictionary:
	var eff := {}
	for k in D.ATTRS:
		eff[k] = soft_cap(attrs[k])
	if w == null:
		var ar0 := 3.0 * (1.0 + D.GRADES.D * scale_curve(eff.str))
		return {"ar": maxi(1, roundi(ar0)), "type": "phys", "parts": [{"attr": "str", "grade": "D", "bonus": 0.0}], "short": [], "base": 3.0, "fav": 0.0}
	var sum := 0.0
	var parts := []
	for k in w.grades:
		var g: float = D.GRADES[w.grades[k]] * scale_curve(eff[k])
		sum += g
		parts.append({"attr": k, "grade": w.grades[k], "bonus": w.base * g})
	var fav := D.FAVOURED_AFFINITY if D.HEROES[h.cls].favoured.has(w.family) else 0.0
	var ar: float = w.base * (1.0 + sum) * (1.0 + D.UPGRADE_STEP * w.upg) * (1.0 + fav)
	var short := []
	for k in w.req:
		if attrs[k] < w.req[k]:
			short.append({"attr": k, "need": w.req[k], "have": attrs[k]})
	if not short.is_empty():
		ar *= 1.0 - D.REQ_PENALTY
	var mult := 1.0 + affix_sum(h, "atk") / 100.0
	if w.type == "magic":
		if h.cls == "mage":
			mult *= 1.15
		if h.gear.offhand != null and h.gear.offhand.get("offType", "") == "orb":
			mult *= 1.0 + D.ORB_BONUS
		if set_count(h, "spiller") >= 2:
			mult *= 1.10
	ar *= mult
	return {"ar": maxi(1, roundi(ar)), "type": w.type, "parts": parts, "short": short, "fav": fav, "base": w.base}

func armor_value(it, attrs: Dictionary) -> Dictionary:
	if it == null or not it.has("def"):
		return {"def": 0, "res": 0, "ok": true}
	var ok := true
	if it.get("reqAttr", "") == "str":
		ok = attrs.str >= it.reqVal
	elif it.get("reqAttr", "") == "intfai":
		ok = maxi(attrs.int, attrs.fai) >= it.reqVal
	var f := 1.0 if ok else 0.5
	return {"def": int(floor(it.def * f)), "res": int(floor(it.res * f)), "ok": ok}

func hero_stats(h: Dictionary) -> Dictionary:
	var attrs := total_attrs(h)
	var eff := {}
	for k in D.ATTRS:
		eff[k] = soft_cap(attrs[k])
	var max_hp := int(floor(10 + 2.5 * eff.vig)) + affix_sum(h, "hp")
	var def := int(floor(eff.vig / (4.0 if h.cls == "knight" else 6.0)))
	var res := int(floor(eff.vig / 6.0))
	for s in D.SLOTS:
		var it = h.gear[s]
		if it == null:
			continue
		var v := armor_value(it, attrs)
		def += v.def
		res += v.res
		if it.has("hp"):
			max_hp += it.hp
	if legend(h, "pinthelm"):
		max_hp += 5
	def += affix_sum(h, "def")
	res += affix_sum(h, "res")
	if h.cls == "knight" and has_perk(h, 24):
		def += 3
	if set_count(h, "bouncer") >= 2:
		def += 6
	def += h.get("defBuff", 0)
	var crit: float = D.CRIT_BASE + attrs.dex + 0.5 * attrs.arc + affix_sum(h, "crit") + (10 if h.cls == "rogue" else 0)
	crit = mini(D.CRIT_CAP, roundi(crit))
	var wa := weapon_ar(h, h.gear.weapon, attrs)
	var heal := 1.0 + affix_sum(h, "heal") / 100.0
	if h.gear.offhand != null and h.gear.offhand.get("offType", "") == "seal":
		heal += D.SEAL_BONUS
	if set_count(h, "choir") >= 2:
		heal += 0.20
	var cd: int = D.HEROES[h.cls].skill.cd
	if (h.cls == "knight" or h.cls == "rogue" or h.cls == "ranger") and has_perk(h, 16):
		cd -= 1
	if affix_sum(h, "quick") > 0:
		cd -= 1
	if set_count(h, "spiller") >= 4:
		cd -= 1
	cd = maxi(1, cd)
	return {
		"attrs": attrs, "eff": eff, "maxHp": max_hp, "def": def, "res": res, "crit": crit, "ar": wa.ar, "dmgType": wa.type,
		"weapon": wa, "heal": heal, "cd": cd, "leech": affix_sum(h, "leech"), "thorns": affix_sum(h, "thorns"),
		"bounty": affix_sum(h, "bounty"), "mendAmount": roundi((6 + 1.5 * eff.fai) * heal), "blessing": int(floor(attrs.fai / 5.0)),
	}

func party_xp_bonus() -> float:
	var v := 0
	for h in G.heroes:
		v += affix_sum(h, "xp")
	return mini(D.XP_GAIN_CAP, v) / 100.0

func party_luck() -> float:
	var v := 0
	var arc := 0
	for h in G.heroes:
		v += affix_sum(h, "luck")
		arc = maxi(arc, total_attrs(h).arc)
	return (v + arc) / 100.0

# ---------- Gear ----------
func roll_rarity(stage: int) -> int:
	var row = D.RARITY_WEIGHTS[D.RARITY_WEIGHTS.size() - 1]
	for r in D.RARITY_WEIGHTS:
		if stage <= r.upTo:
			row = r
			break
	return rng.weighted(row.w)

func gen_affixes(slot: String, rarity_idx: int, count: int) -> Array:
	var out := []
	var size_idx := clampi(rarity_idx - 1, 0, 2)
	var pool := []
	for k in D.AFFIXES:
		var a: Dictionary = D.AFFIXES[k]
		if a.get("epicOnly", false) and rarity_idx < 3:
			continue
		if typeof(a.slots) == TYPE_STRING or a.slots.has(slot):
			pool.append(k)
	for i in count:
		if pool.is_empty():
			break
		var k: String = rng.pick(pool)
		var x := {"type": k, "value": D.AFFIXES[k].size[size_idx]}
		if k == "attr":
			x.attr = rng.pick(D.ATTRS)
		else:
			pool.erase(k)
		out.append(x)
	return out

func gen_item(L: int, rarity_idx: int, slot: String = "", opts: Dictionary = {}) -> Dictionary:
	if slot == "":
		slot = rng.pick(D.SLOTS)
	var r: Dictionary = D.RARITIES[rarity_idx]
	var it := {"id": uid(), "slot": slot, "rarity": rarity_idx, "L": L, "upg": 0, "affixes": [], "locked": false}
	var lines: int = r.lines + (1 if slot == "amulet" or slot == "ring" else 0)
	var leg := {}
	if rarity_idx == 4:
		var pool := []
		for x in D.LEGENDARIES:
			if x.slot == slot:
				pool.append(x)
		if opts.has("legend"):
			leg = D.legendary(opts.legend)
		else:
			leg = rng.pick(pool) if not pool.is_empty() else rng.pick(D.LEGENDARIES)
		slot = leg.slot
		it.slot = slot
		it.legend = leg.id
		lines = r.lines + (1 if slot == "amulet" or slot == "ring" else 0)
	var req_bump := int(floor((L - 1) / 2.0))
	if slot == "weapon":
		var fam: String = leg.get("family", opts.get("family", ""))
		if fam == "":
			fam = rng.pick(D.WEAPONS.keys())
		var W: Dictionary = D.WEAPONS[fam]
		it.family = fam
		it.type = W.type
		it.grades = (leg.grades if leg.has("grades") else W.grades).duplicate()
		it.req = {}
		for k in W.req:
			it.req[k] = W.req[k] + req_bump
		it.base = round((4 + 1.5 * L) * r.mult * 10.0) / 10.0
		it.name = leg.name if leg.has("name") else "%s %s %s" % [r.prefix, rng.pick(D.WEAPON_WORDS), W.name]
	elif slot == "offhand":
		var ot: String = leg.get("family", opts.get("offType", ""))
		if ot == "":
			ot = rng.pick(D.OFFHANDS.keys())
		it.offType = ot
		if ot == "shield":
			var v: float = D.ARMOR_WEIGHT.shield * (0.5 + 0.1 * L) * r.mult
			it.def = maxi(1, roundi(v))
			it.res = maxi(0, roundi(v * 0.5))
			it.reqAttr = "str"
			it.reqVal = 8 + req_bump
		it.name = leg.name if leg.has("name") else "%s %s %s" % [r.prefix, rng.pick(D.WEAPON_WORDS), D.OFFHANDS[ot].name]
	elif D.SET_SLOTS.has(slot):
		var cls: String = leg.get("cls", opts.get("cls", ""))
		if cls == "":
			cls = rng.pick(D.ARMOR_CLASS.keys())
		if leg.is_empty() and rarity_idx >= 2 and rarity_idx < 4 and not G.is_empty() and G.stage >= D.SET_FROM_STAGE and rng.chance(D.SET_CHANCE):
			it.set = rng.pick(D.SETS.keys())
			cls = D.SETS[it.set].cls
		var C: Dictionary = D.ARMOR_CLASS[cls]
		it.cls = cls
		var v2: float = D.ARMOR_WEIGHT[slot] * (0.5 + 0.1 * L) * r.mult
		it.def = maxi(0, roundi(v2 * C.def))
		it.res = maxi(0, roundi(v2 * C.res))
		if slot != "gloves" and slot != "boots":
			it.hp = 2 * D.ARMOR_WEIGHT[slot] * (rarity_idx + 1)
		if C.req != "":
			it.reqAttr = C.req
			it.reqVal = 8 + req_bump
		if leg.has("name"):
			it.name = leg.name
		elif it.has("set"):
			it.name = "%s %s" % [D.SETS[it.set].name.split(" ")[0], C.words[slot]]
		else:
			it.name = "%s %s %s" % [r.prefix, C.name, C.words[slot]]
	else:
		var nm := ["Locket", "Pendant", "Token", "Charm"] if slot == "amulet" else ["Band", "Signet", "Loop", "Coil"]
		it.name = leg.name if leg.has("name") else "%s %s %s" % [r.prefix, rng.pick(D.WEAPON_WORDS), rng.pick(nm)]
	it.name = it.name.strip_edges()
	it.affixes = gen_affixes(slot, rarity_idx, lines)
	return it

func drop_item(rarity_override: int = -1) -> Dictionary:
	var it := gen_item(G.stage, rarity_override if rarity_override >= 0 else roll_rarity(G.stage))
	G.pack.append(it)
	G.stats.gear += 1
	return it

func item_summary(it: Dictionary) -> Array:
	var lines := []
	if it.slot == "weapon":
		var W: Dictionary = D.WEAPONS[it.family]
		lines.append("%s, %s damage, base %s%s" % [W.name, it.type, str(it.base), (", +%d" % it.upg) if it.upg else ""])
		var sc := []
		for k in it.grades:
			sc.append("%s %s" % [D.ATTR_NAMES[k].substr(0, 3), it.grades[k]])
		lines.append("Scaling: " + ", ".join(sc))
		var rq := []
		for k in it.req:
			rq.append("%s %d" % [D.ATTR_NAMES[k].substr(0, 3), it.req[k]])
		lines.append("Needs: " + ", ".join(rq))
	if it.has("offType"):
		lines.append(D.OFFHANDS[it.offType].text)
	if it.has("def"):
		var cls_name: String = (D.ARMOR_CLASS[it.cls].name + " · ") if it.has("cls") else ""
		lines.append("%sDefense %d, Resist %d%s" % [cls_name, it.def, it.res, (", +%d HP" % it.hp) if it.has("hp") else ""])
	if it.has("reqAttr"):
		lines.append("Needs %s %d (half value below)" % ["Str" if it.reqAttr == "str" else "Int or Fai", it.reqVal])
	for x in it.affixes:
		lines.append(D.affix_text(x))
	if it.has("set"):
		var st: Dictionary = D.SETS[it.set]
		lines.append("%s: 2 pc %s; 4 pc %s" % [st.name, st.two, st.four])
	if it.has("legend"):
		lines.append("★ " + D.legendary(it.legend).text)
	return lines
