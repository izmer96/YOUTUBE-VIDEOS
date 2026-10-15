extends Node
## Headless bot: plays full runs with random aim and auto-levelling to check the rules port.

var runs := 0
var results := []

func _ready() -> void:
	Sfx.settings.sfxOn = false
	Bus.show_draft.connect(func(): call_deferred("_draft"))
	Bus.show_end.connect(_end)
	_start()

func _start() -> void:
	Game.new_run("BOT%d" % runs)
	S.G.skipAnim = true

func _draft() -> void:
	Game.pick_reward(0)
	S.G.skipAnim = true

func _end(win: bool, legs: Array, newly: Array) -> void:
	var G = S.G
	results.append("%s stage %d round %d pts %d kills %d lv %s" % ["WIN" if win else "LOSS", G.stage, G.round, G.stats.points, G.stats.kills, str(G.heroes.map(func(h): return h.level))])
	print(results[-1])
	runs += 1
	if runs >= 3:
		print("DONE")
		get_tree().quit()
	else:
		call_deferred("_start")

var busy := false
func _process(_dt: float) -> void:
	var G = S.G
	match G.phase:
		"aim":
			Game.board.aim = randf_range(0.35, PI - 0.35)
			Game.board.fire()
		"ball", "sink":
			for i in 40:
				Game.board.update(1.0 / 60.0)
				if Game.board.reveal != null:
					Game.board.skip_reveal()
				if G.phase != "ball" and G.phase != "sink":
					break
		"alloc":
			Game.auto_level()
			for h in G.heroes:
				h.cmd = "skill" if Battle.skill_ready(h) else "attack"
			Game.fight()
