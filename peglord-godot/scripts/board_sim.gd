class_name BoardSim
extends RefCounted
## The pin board's rules and physics in flat 480x640 board units (ported from board.js).
## The 3D view reads `pegs`, `ball`, `reveal` each frame and listens to the signals for one-shot effects.

signal fx_burst(pos: Vector2, color: Color, n: int)
signal fx_ring(pos: Vector2, radius: float, color: Color)
signal fx_arc(a: Vector2, b: Vector2)
signal fx_float(pos: Vector2, text: String, color: Color, size: int)
signal fx_big(text: String)
signal fx_shake(amount: float)
signal peg_broken(peg: Dictionary)
signal built
signal launched
signal sunk(slot: int, type: String)

var P := D.PHYS
var pegs: Array = []
var ball = null          # Dictionary while a ball is live
var pockets: Array = []  # pocket types for the current ball (hidden until it lands)
var glint := -1
var reveal = null
var aim := PI / 2
var t := 0.0
var slot_w: float = D.PHYS.W / D.PHYS.pocketCount

var G: Dictionary:
	get: return S.G

func build() -> void:
	pegs = []
	ball = null
	reveal = null
	pockets = []
	var spots := []
	for r in P.rows:
		var odd: bool = r % 2 == 1
		var n: int = P.cols - 1 if odd else P.cols
		var x0: float = (P.W - (P.cols - 1) * P.dx) / 2.0 + (P.dx / 2.0 if odd else 0.0)
		for c in n:
			spots.append(Vector2(x0 + c * P.dx + S.rng.range_f(-P.jitterX, P.jitterX), P.top + r * P.dy + S.rng.range_f(-P.jitterY, P.jitterY)))
	S.rng.shuffle(spots)
	var extra := 0
	for k in G.pegExtras:
		extra += G.pegExtras[k]
	var keep: float = minf(P.keepMax, P.keep + P.keepPerExtra * extra)
	var kept := spots.slice(0, roundi(spots.size() * keep))
	var mix := []
	for k in D.BASE_PEG_MIX:
		for i in D.BASE_PEG_MIX[k]:
			mix.append(k)
	for i in D.RANDOM_SPECIAL_COUNT:
		mix.append(S.rng.pick(D.RANDOM_SPECIALS))
	for k in G.pegExtras:
		for i in G.pegExtras[k]:
			mix.append(k)
	if mix.count("portal") % 2 == 1:
		mix.erase("portal")
	var last_portal = null
	for i in kept.size():
		var s: Vector2 = kept[i]
		var type: String = mix[i] if i < mix.size() else "brass"
		var p := {"id": S.uid(), "type": type, "x": s.x, "y": s.y, "bx": s.x, "r": P.pegR, "lit": false, "hits": 0, "dead": false,
			"phase": S.rng.range_f(0, 6.28), "cool": 0.0, "glow": 0.0, "twin": -1}
		if type == "rover":
			p.bx = clampf(s.x, P.roverAmp + 16, P.W - P.roverAmp - 16)
		if type == "bumper":
			p.r = 10.0
		if type == "portal":
			if last_portal != null:
				p.twin = last_portal.id
				last_portal.twin = p.id
				last_portal = null
			else:
				last_portal = p
		pegs.append(p)
	for i in range(1, P.pocketCount):
		pegs.append({"id": S.uid(), "type": "post", "x": i * slot_w, "y": P.pocketTop, "bx": i * slot_w, "r": 5.0, "lit": true, "dead": false, "hits": 0, "cool": 0.0, "glow": 0.0, "twin": -1, "phase": 0.0})
	built.emit()

func peg_by_id(id: int):
	for p in pegs:
		if p.id == id:
			return p
	return null

# ---------- Pockets ----------
func roll_pockets(is_last: bool) -> void:
	var split: Dictionary = D.POCKET_SPLIT[0] if G.stage <= D.POCKET_SPLIT[0].upTo else D.POCKET_SPLIT[1]
	var perks := D.POCKETS.keys().filter(func(k): return D.POCKETS[k].kind == "perk")
	var bads := D.POCKETS.keys().filter(func(k): return D.POCKETS[k].kind == "bad" and not (is_last and k == "jam"))
	var roll: Array = S.rng.shuffle(perks).slice(0, split.perks) + S.rng.shuffle(bads).slice(0, P.pocketCount - split.perks)
	S.rng.shuffle(roll)
	pockets = roll
	glint = -1
	if S.has_joker("peephole"):
		var idx := []
		for i in roll.size():
			if D.POCKETS[roll[i]].kind == "perk":
				idx.append(i)
		glint = S.rng.pick(idx)
		Bus.pulse_joker.emit("peephole")

func split_text() -> String:
	var split: Dictionary = D.POCKET_SPLIT[0] if G.stage <= D.POCKET_SPLIT[0].upTo else D.POCKET_SPLIT[1]
	return "%d good, %d bad" % [split.perks, P.pocketCount - split.perks]

# ---------- Launch ----------
func fire() -> void:
	if G.phase != "aim" or G.balls <= 0:
		return
	var is_last: bool = G.balls == 1
	roll_pockets(is_last)
	G.balls -= 1
	G.ballNo += 1
	var b := {"x": P.launcherX, "y": P.launcherY, "vx": cos(aim) * P.launchSpeed, "vy": sin(aim) * P.launchSpeed,
		"life": 0.0, "slow": 0.0, "combo": 0, "pts": 0, "hits": 0, "firstHit": true, "ghost": false, "isLast": is_last, "first": G.ballNo == 1}
	if G.hotNext:
		b.combo = 8
		G.hotNext = false
	if is_last:
		for h in G.heroes:
			if S.legend(h, "lastorder"):
				b.combo = maxi(b.combo, 8)
	ball = b
	for p in pegs:
		if D.REARM.has(p.type):
			p.lit = false
	Game.set_phase("ball")
	Sfx.play("launch")
	launched.emit()
	Bus.hud.emit()

# ---------- Scoring ----------
func mult_for(combo: int) -> int:
	return 1 + int(combo / (6 if S.has_joker("comboking") else 8))

func score(p: Dictionary, base: int) -> void:
	var b = ball
	if b == null:
		return
	var before := mult_for(b.combo)
	b.combo += 1
	b.hits += 1
	var mult := mult_for(b.combo)
	var pts: float = base * D.payout(G.stage) * mult
	if b.firstHit and S.has_joker("penny"):
		pts *= 3
		Bus.pulse_joker.emit("penny")
	b.firstHit = false
	if S.has_joker("echo") and b.hits % 4 == 0:
		pts *= 2
		Bus.pulse_joker.emit("echo")
	if S.has_joker("luckyseven") and b.hits % 7 == 0:
		pts += 7
		Bus.pulse_joker.emit("luckyseven")
	if b.first:
		for h in G.heroes:
			if S.legend(h, "horseshoe"):
				pts *= 2
				break
	if b.isLast and S.has_joker("lastorders"):
		pts *= 2
		Bus.pulse_joker.emit("lastorders")
	var ipts := roundi(pts * (1.0 + S.party_xp_bonus()))
	b.pts += ipts
	G.bank += ipts
	G.stats.points += ipts
	G.stats.bestCombo = maxi(G.stats.bestCombo, b.combo)
	fx_float.emit(Vector2(p.x, p.y - 10), "+%d" % ipts, Color("#fff3c4"), 13)
	if mult > before:
		fx_big.emit("×%d!" % mult)
		Sfx.play_multi(mult)
	Bus.hud.emit()

func peg_value(p: Dictionary) -> int:
	var v: int = D.PEGS[p.type].pts
	if p.type == "gold":
		if S.has_joker("goldtooth"):
			v += 2
			Bus.pulse_joker.emit("goldtooth")
		for h in G.heroes:
			if S.legend(h, "pinthelm"):
				v += 1
	if p.type == "brass" and S.has_joker("pintglass"):
		v += 1
		Bus.pulse_joker.emit("pintglass")
	if p.type == "bomb" and S.has_joker("bombsquad"):
		v += 4
		Bus.pulse_joker.emit("bombsquad")
	return v

func _combo() -> int:
	return ball.combo if ball != null else 0

func hit_peg(p: Dictionary, direct: bool) -> void:
	if p.dead or p.type == "post":
		return
	var def: Dictionary = D.PEGS[p.type]
	p.glow = 1.0
	if p.type == "crate" or p.type == "chest":
		p.hits += 1
		p.lit = true
		score(p, peg_value(p))
		var need: int = (2 if S.has_joker("crowbar") else def.hits) if p.type == "crate" else def.hits
		if p.type == "crate" and S.has_joker("crowbar") and p.hits == need:
			Bus.pulse_joker.emit("crowbar")
		if p.hits >= need:
			p.dead = true
			G.stats.pegs += 1
			Sfx.play("crateBreak")
			fx_burst.emit(Vector2(p.x, p.y), Color(def.color), 14)
			fx_shake.emit(3.0)
			peg_broken.emit(p)
			if p.type == "crate":
				crate_loot(p)
			else:
				var it := S.drop_item()
				Bus.log_msg.emit("Chest broke: %s." % it.name, "loot")
				fx_float.emit(Vector2(p.x, p.y - 24), it.name, Color(D.RARITIES[it.rarity].color), 12)
		else:
			Sfx.play("crate")
		return
	if p.lit:
		if direct:
			Sfx.play_peg(_combo())
		return
	p.lit = true
	score(p, peg_value(p))
	if not D.REARM.has(p.type):
		G.stats.pegs += 1
	match p.type:
		"gold": Sfx.play_gold(_combo())
		"glass":
			p.dead = true
			Sfx.play("glass")
			fx_burst.emit(Vector2(p.x, p.y), Color(def.color), 10)
			peg_broken.emit(p)
		"bomb": explode(p)
		"heart":
			Sfx.play("heart")
			Battle.heal_weakest(3, "Heart peg")
		"star":
			if ball != null:
				ball.combo += 3
			Sfx.play("star")
			fx_burst.emit(Vector2(p.x, p.y), Color(def.color), 8)
		"bolt": bolt(p)
		"bumper": Sfx.play("bumper")
		"portal": Sfx.play("portal")
		_: Sfx.play_peg(_combo())

func crate_loot(p: Dictionary) -> void:
	var loot: String = S.rng.pick(D.CRATE_LOOT)
	var at := Vector2(p.x, p.y - 24)
	match loot:
		"bomb":
			fx_float.emit(at, "Bomb!", Color("#ff8a65"), 12)
			explode(p)
		"ball":
			G.balls += 1
			fx_float.emit(at, "+1 ball", Color.WHITE, 12)
			Bus.log_msg.emit("Crate: free ball.", "good")
		"potion":
			fx_float.emit(at, "Potion", Color("#4dd0c1"), 12)
			Battle.heal_weakest(6, "Potion")
		"whetstone":
			G.mods.whet += 2
			fx_float.emit(at, "Whetstone +2", Color("#cfd8dc"), 12)
			Bus.log_msg.emit("Crate: whetstone, +2 damage this round.", "good")
		"coins":
			G.bank += 6
			G.stats.points += 6
			fx_float.emit(at, "+6 coins", Color("#ffd23f"), 12)
	Bus.hud.emit()

func explode(p: Dictionary) -> void:
	p.dead = true
	peg_broken.emit(p)
	var rad: float = P.bombSquadRadius if S.has_joker("bombsquad") else P.bombRadius
	Sfx.play("bomb")
	fx_burst.emit(Vector2(p.x, p.y), Color("#ff9a3c"), 22)
	fx_ring.emit(Vector2(p.x, p.y), rad, Color("#ffaa50"))
	fx_shake.emit(9.0)
	if ball != null:
		var d := Vector2(ball.x - p.x, ball.y - p.y)
		var l := d.length()
		if l < rad * 1.2 and l > 0.1:
			ball.vx += d.x / l * 260
			ball.vy += d.y / l * 260 - 60
	for q in pegs:
		if q == p or q.dead or q.type == "post":
			continue
		if Vector2(q.x - p.x, q.y - p.y).length() <= rad:
			hit_peg(q, false)

func bolt(p: Dictionary) -> void:
	Sfx.play("bolt")
	var here := Vector2(p.x, p.y)
	var near := pegs.filter(func(q): return not q.dead and not q.lit and q.id != p.id and q.type != "post" and here.distance_to(Vector2(q.x, q.y)) <= P.boltRange)
	near.sort_custom(func(a, c): return here.distance_to(Vector2(a.x, a.y)) < here.distance_to(Vector2(c.x, c.y)))
	for q in near.slice(0, 3):
		fx_arc.emit(here, Vector2(q.x, q.y))
		hit_peg(q, false)

# ---------- Physics ----------
func step(dt: float) -> void:
	var b = ball
	if b == null:
		return
	b.life += dt
	b.vy += P.gravity * dt
	if S.has_joker("horseshoe"):
		var best = null
		var bd := 140.0
		for p in pegs:
			if p.type == "gold" and not p.lit and not p.dead:
				var dd := Vector2(p.x - b.x, p.y - b.y).length()
				if dd < bd:
					bd = dd
					best = p
		if best != null:
			b.vx += (best.x - b.x) / bd * 320 * dt
			b.vy += (best.y - b.y) / bd * 200 * dt
	if b.life > P.maxBallLife and not b.ghost:
		b.ghost = true
		b.vy = maxf(b.vy, 300)
		Bus.log_msg.emit("Ball pushed down.", "")
	if b.ghost:
		b.vy = maxf(b.vy, 300)
	b.x += b.vx * dt
	b.y += b.vy * dt
	var r: float = P.ballR
	if b.x < r:
		b.x = r
		b.vx = absf(b.vx) * P.wallBounce
		Sfx.play("wall")
	if b.x > P.W - r:
		b.x = P.W - r
		b.vx = -absf(b.vx) * P.wallBounce
		Sfx.play("wall")
	if b.y < r:
		b.y = r
		b.vy = absf(b.vy) * P.ceilBounce
	if not b.ghost:
		for p in pegs:
			if p.dead:
				continue
			var dx: float = b.x - p.x
			var dy: float = b.y - p.y
			var rr: float = r + p.r
			var d2 := dx * dx + dy * dy
			if d2 >= rr * rr:
				continue
			var d := sqrt(d2)
			if d == 0:
				d = 0.01
			var nx := dx / d
			var ny := dy / d
			if p.type == "portal" and p.twin >= 0 and p.cool <= 0:
				var tw = peg_by_id(p.twin)
				if tw != null and not tw.dead:
					p.cool = P.portalCooldown
					tw.cool = P.portalCooldown
					hit_peg(p, true)
					b.x = tw.x + nx * (rr + 2)
					b.y = tw.y + ny * (rr + 2)
					fx_ring.emit(Vector2(tw.x, tw.y), 26.0, Color("#b388ff"))
					break
			b.x = p.x + nx * rr
			b.y = p.y + ny * rr
			var vn: float = b.vx * nx + b.vy * ny
			if vn < 0:
				var e: float = P.bumperBounce if p.type == "bumper" else P.pegBounce
				b.vx -= (1 + e) * vn * nx
				b.vy -= (1 + e) * vn * ny
				if p.type == "bumper":
					b.vx += nx * P.bumperKick
					b.vy += ny * P.bumperKick
				b.vx += S.rng.range_f(-P.nudge, P.nudge)
				if p.type != "post":
					hit_peg(p, true)
			if ball == null:
				return
	if b.y > P.pocketTop:
		for i in range(1, P.pocketCount):
			var x := i * slot_w
			if absf(b.x - x) < r + 2:
				var sgn := signf(b.x - x)
				if sgn == 0:
					sgn = 1
				b.x = x + sgn * (r + 2)
				b.vx = -b.vx * P.wallBounce
	var sp := Vector2(b.vx, b.vy).length()
	if sp > P.speedCap:
		b.vx *= P.speedCap / sp
		b.vy *= P.speedCap / sp
	if sp < P.stallSpeed:
		b.slow += dt
		if b.slow > P.stallTime:
			b.vx += S.rng.range_f(-1, 1) * 140
			b.vy -= 40
			b.slow = 0.0
	else:
		b.slow = 0.0
	if b.y > P.H - 10:
		sink(clampi(int(floor(b.x / slot_w)), 0, P.pocketCount - 1))

func sink(slot: int) -> void:
	var b = ball
	ball = null
	Game.set_phase("sink")
	Sfx.play("sink")
	reveal = {"slot": slot, "type": pockets[slot], "t": 0.0, "applied": false, "flipped": false, "skip": false, "ball": b}
	sunk.emit(slot, pockets[slot])

func update_reveal(dt: float) -> void:
	var R = reveal
	if R == null:
		return
	R.t += dt
	if R.t > 0.15 and not R.flipped:
		R.flipped = true
		Sfx.play("flip")
	if R.t > 0.45 and not R.applied:
		R.applied = true
		Game.apply_pocket(R.type, R.ball)
	if R.t > D.REVEAL_HOLD or (R.skip and R.t > 0.6):
		reveal = null
		for p in pegs:
			if p.lit and not D.REARM.has(p.type) and p.type != "post" and p.type != "crate" and p.type != "chest" and not p.dead:
				p.dead = true
				peg_broken.emit(p)
		pegs = pegs.filter(func(p): return not p.dead)
		pockets = []
		glint = -1
		Game.after_ball()

func skip_reveal() -> void:
	if reveal != null:
		reveal.skip = true

# ---------- Aim ----------
func set_aim_from(px: float, py: float) -> void:
	var a := atan2(py - P.launcherY, px - P.launcherX)
	if a < 0:
		a = PI - P.aimClamp if px < P.launcherX else P.aimClamp
	aim = clampf(a, P.aimClamp, PI - P.aimClamp)

func nudge_aim(d: float) -> void:
	aim = clampf(aim + d, P.aimClamp, PI - P.aimClamp)

func preview_path() -> PackedVector2Array:
	var pts := PackedVector2Array()
	var x: float = P.launcherX
	var y: float = P.launcherY
	var vx: float = cos(aim) * P.launchSpeed
	var vy: float = sin(aim) * P.launchSpeed
	var dt := 1.0 / 120.0
	for i in 240:
		vy += P.gravity * dt
		x += vx * dt
		y += vy * dt
		if x < P.ballR:
			x = P.ballR
			vx = -vx * P.wallBounce
		if x > P.W - P.ballR:
			x = P.W - P.ballR
			vx = -vx * P.wallBounce
		if i % 3 == 0:
			pts.append(Vector2(x, y))
		var hit := false
		for p in pegs:
			if not p.dead and Vector2(p.x - x, p.y - y).length() < p.r + P.ballR:
				hit = true
				break
		if hit or y > P.H:
			break
	return pts

func update(dt: float) -> void:
	t += dt
	for p in pegs:
		if p.type == "rover":
			p.x = p.bx + sin(t * 1.6 + p.phase) * P.roverAmp
		if p.cool > 0:
			p.cool -= dt
		if p.glow > 0:
			p.glow = maxf(0.0, p.glow - dt * 2)
	if G.phase == "ball" and ball != null:
		var steps := roundi(dt * G.speed / P.dt)
		for i in steps:
			if ball == null:
				break
			step(P.dt)
	if G.phase == "sink":
		update_reveal(dt)
