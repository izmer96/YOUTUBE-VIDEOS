extends Node
## Sound (autoload "Sfx"): plays the sounds pre-rendered from the original Web Audio synth.
## Music crossfades between the calm tavern jig and the faster fight version.

const MANIFEST := "res://assets/audio/manifest.json"
const PENTATONIC := [0, 3, 5, 7, 10]

var streams := {}
var pitched := {}
var players: Array[AudioStreamPlayer] = []
var next_player := 0
var music_calm: AudioStreamPlayer
var music_fight: AudioStreamPlayer
var fight_mood := false
var settings := {"sfx": 0.7, "music": 0.45, "sfxOn": true, "musicOn": true}
var last_played := {}
var started := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 14:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		players.append(p)
	music_calm = AudioStreamPlayer.new()
	music_fight = AudioStreamPlayer.new()
	add_child(music_calm)
	add_child(music_fight)
	_load_manifest()

func _load_manifest() -> void:
	if not FileAccess.file_exists(MANIFEST):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	if not data is Dictionary:
		return
	for k in data.get("sfx", {}):
		var s = load(data.sfx[k])
		if s:
			streams[k] = s
	var pt: Dictionary = data.get("pitched", {})
	for k in pt:
		var v = pt[k]
		if v is Array:
			pitched[k] = v.map(func(path): return load(path))
		elif v is Dictionary:
			var dd := {}
			for n in v:
				dd[int(n)] = load(v[n])
			pitched[k] = dd
	var mu: Dictionary = data.get("music", {})
	if mu.has("calm"):
		var s1 = load(mu.calm.path if mu.calm is Dictionary else mu.calm)
		if s1:
			s1.loop = true
			music_calm.stream = s1
	if mu.has("fight"):
		var s2 = load(mu.fight.path if mu.fight is Dictionary else mu.fight)
		if s2:
			s2.loop = true
			music_fight.stream = s2

func apply(s: Dictionary) -> void:
	settings.merge(s, true)
	_update_music_volume(0.0)

func _db(v: float) -> float:
	return linear_to_db(maxf(v, 0.0001))

func start() -> void:
	## Browsers only allow audio after a click, so the title screen calls this on the first press.
	if started:
		return
	started = true
	if music_calm.stream:
		music_calm.play()
	if music_fight.stream:
		music_fight.play()
	_update_music_volume(0.0)

func set_mood(is_fight: bool) -> void:
	if is_fight == fight_mood:
		return
	fight_mood = is_fight
	_update_music_volume(1.2)

func _update_music_volume(fade: float) -> void:
	var on: bool = settings.musicOn and settings.music > 0
	var base: float = settings.music if on else 0.0
	var calm_v := base * (0.0 if fight_mood else 1.0)
	var fight_v := base * (1.0 if fight_mood else 0.0)
	if fade <= 0.0:
		music_calm.volume_db = _db(calm_v)
		music_fight.volume_db = _db(fight_v)
		return
	var tw := create_tween().set_parallel(true)
	tw.tween_property(music_calm, "volume_db", _db(calm_v), fade)
	tw.tween_property(music_fight, "volume_db", _db(fight_v), fade)

func _play_stream(s: AudioStream, gain: float = 1.0, key: String = "") -> void:
	if s == null or not settings.sfxOn or settings.sfx <= 0:
		return
	var now := Time.get_ticks_msec()
	if key != "" and now - int(last_played.get(key, -1000)) < 30:
		return  # avoid stacking the same sound many times in one frame (bomb chains)
	last_played[key] = now
	var p := players[next_player]
	next_player = (next_player + 1) % players.size()
	p.stream = s
	p.volume_db = _db(settings.sfx / 0.7 * gain)
	p.play()

func play(sound_name: String) -> void:
	_play_stream(streams.get(sound_name), 1.0, sound_name)

func play_peg(combo: int) -> void:
	var arr: Array = pitched.get("peg", [])
	if arr.is_empty():
		play("peg")
		return
	var idx := mini(int(floor(mini(24, combo) * 0.6)), arr.size() - 1)
	_play_stream(arr[idx], 1.0, "peg%d" % idx)

func play_gold(combo: int) -> void:
	var arr: Array = pitched.get("gold", [])
	if arr.is_empty():
		play("gold")
		return
	_play_stream(arr[mini(24, combo) % arr.size()], 1.0, "gold")

func play_multi(n: int) -> void:
	var dd: Dictionary = pitched.get("multi", {})
	if dd.is_empty():
		play("multi")
		return
	_play_stream(dd.get(clampi(n, 2, 8), dd.values()[0]), 1.0, "multi")
