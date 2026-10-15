class_name Rng
extends RefCounted
## Seeded mulberry32 RNG so a seed string replays the same run.

const M32 := 0xFFFFFFFF
var s: int = 1

static func _imul(a: int, b: int) -> int:
	a &= M32
	b &= M32
	var lo := (a * (b & 0xFFFF)) & M32
	var hi := ((a * (b >> 16)) & 0xFFFF) << 16
	return (lo + hi) & M32

static func hash_seed(text: String) -> int:
	var h: int = (1779033703 ^ text.length()) & M32
	for i in text.length():
		h = _imul(h ^ text.unicode_at(i), 3432918353)
		h = ((h << 13) | (h >> 19)) & M32
	h = _imul(h ^ (h >> 16), 2246822507)
	h = _imul(h ^ (h >> 13), 3266489909)
	h ^= h >> 16
	return h & M32

func set_seed(text: String) -> void:
	s = hash_seed(text)
	if s == 0:
		s = 1

func next() -> float:
	s = (s + 0x6D2B79F5) & M32
	var t := s
	t = _imul(t ^ (t >> 15), t | 1)
	t = (t ^ ((t + _imul(t ^ (t >> 7), t | 61)) & M32)) & M32
	return float((t ^ (t >> 14)) & M32) / 4294967296.0

func randi_n(n: int) -> int:
	return int(floor(next() * n))

func range_f(a: float, b: float) -> float:
	return a + next() * (b - a)

func pick(arr: Array):
	return arr[randi_n(arr.size())]

func chance(p: float) -> bool:
	return next() < p

func shuffle(arr: Array) -> Array:
	for i in range(arr.size() - 1, 0, -1):
		var j := randi_n(i + 1)
		var t = arr[i]
		arr[i] = arr[j]
		arr[j] = t
	return arr

func weighted(weights: Array) -> int:
	var tot := 0.0
	for w in weights:
		tot += w
	var r := next() * tot
	for i in weights.size():
		r -= weights[i]
		if r < 0:
			return i
	return weights.size() - 1

static func random_seed_string() -> String:
	var w := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
	var out := ""
	for i in 6:
		out += w[randi() % w.length()]
	return out
