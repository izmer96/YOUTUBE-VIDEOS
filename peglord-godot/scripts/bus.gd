extends Node
## Event bus (autoload "Bus"): game logic talks to the 3D world and the UI only through these signals.

signal log_msg(text: String, kind: String)
signal refresh                                   # state changed; redraw HUD/panels
signal hud                                       # bank/ball counters changed (cheap)
signal unit_fx(side: String, id: int, text: String, kind: String)   # floating number over a unit
signal unit_anim(side: String, id: int, anim: String)               # lunge / hit
signal effect(side: String, id: int, kind: String)                  # slash/zap/holy/boom/heal/block
signal projectile(from_side: String, from_id: int, to_side: String, to_id: int, kind: String)
signal cast(side: String, id: int)
signal pulse_joker(id: String)
signal show_draft
signal show_end(win: bool, legs: Array, newly: Array)
signal phase_changed(phase: String)
signal new_run
signal boss_phase2
