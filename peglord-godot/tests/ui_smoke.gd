extends Node
## UI smoke test: runs the real scene and clicks through every screen while a run plays itself.

var main: Node
var t := 0.0
var steps := 0
var opened := {}

func _ready() -> void:
	Engine.time_scale = 4.0
	Sfx.settings.sfxOn = false
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	main.ui.open_help()
	await get_tree().create_timer(0.2).timeout
	main.ui.open_settings()
	await get_tree().create_timer(0.2).timeout
	main.ui.show_title()
	Game.new_run("SMOKE")
	S.G.speed = 2
	S.G.skipAnim = true
	Bus.show_end.connect(func(w, l, n): print("SMOKE end win=", w, " stage=", S.G.stage); _finish())

func _process(dt: float) -> void:
	t += dt
	if t < 0.4:
		return
	t = 0.0
	var G := S.G
	var ui = main.ui
	steps += 1
	if steps > 3000:
		print("SMOKE timeout at stage ", G.stage)
		_finish()
		return
	match G.phase:
		"aim":
			Game.board.aim = randf_range(0.5, PI - 0.5)
			ui.hover_peg(Game.board.pegs[0] if not Game.board.pegs.is_empty() else null)
			Game.board.fire()
		"sink":
			Game.board.skip_reveal()
		"alloc":
			if not opened.has("level%d" % G.stage):
				opened["level%d" % G.stage] = true
				ui.open_level()
				var lv = ui.modal.get_meta("screen")
				lv._tab(G.heroes[1], 1).pressed.emit()
				Game.buy_level(G.heroes[0], "vig")
				Game.refund_level(G.heroes[0], "vig")
				Game.auto_level()
				ui.open_gear()
				var gs = ui.modal.get_meta("screen")
				if not G.pack.is_empty():
					gs.sel_id = G.pack[0].id
					gs.refresh()
					var it = G.pack[0]
					ui.show_tip(UIK.item_tip(it, G.heroes[0]))
					Game.equip(G.heroes[0], it)
				ui.close_all()
			for h in G.heroes:
				h.cmd = "skill" if Battle.skill_ready(h) else "attack"
			Game.fight()
		"draft":
			if ui.modal_kind != "draft":
				ui._show_draft()
			ui.hide_draft()
			ui._show_draft()
			Game.pick_reward(steps % G.rewards.size(), 0)
			ui.close_all()
			if G.stage > 4:
				print("SMOKE reached stage ", G.stage)
				_finish()

func _finish() -> void:
	print("SMOKE ok steps=", steps)
	get_tree().quit()
