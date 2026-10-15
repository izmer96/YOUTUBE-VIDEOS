# Peglord (Godot, HD-2D)

The 2.5D version of Peglord: Blender-rendered pixel heroes standing in a lit 3D pub, with tilt-shift blur, bloom and lamplight. Same rules and balance as the browser version in `../peglord`.

## Run it

1. Install Godot 4.3 (standard build, no .NET needed).
2. Open `project.godot`, press F5.

Controls: move to aim, click to drop. Click a foe to target it. L level up, C equipment, Space drops a ball or starts the fight, 1/2/3 set Attack/Skill/Guard, Esc menu.

## Web export

Project > Export > Web (the preset is in `export_presets.cfg`, single-threaded so it runs without special server headers). Or headless:

```
godot --headless --path . --export-release "Web" build/web/index.html
```

## Layout

- `scripts/data.gd`: every rule table and balance number.
- `scripts/state.gd`, `game.gd`, `battle.gd`, `board_sim.gd`: run state, round flow, combat and pin-board physics. They talk to the visuals only through `bus.gd` signals.
- `scripts/world/`: the pub diorama, pin cabinet, fight stage and sprite units.
- `scripts/ui/`: HUD (jokers on top, Balatro style), Level Up (Elden Ring style), Equipment (Diablo style), draft, title and menus.
- `shaders/`: sprite billboard, tilt-shift post, flames and spell glyphs.
- `tests/`: `bot.tscn` plays full runs headless to check the rules; `ui_smoke.tscn` clicks through every screen.

## Regenerating art

- Characters: `blender -b --python tools/blender/characters.py -- /tmp/renders` then `python3 tools/pixelate.py /tmp/renders assets/sprites 80`.
- Textures and UI frames: `python3 tools/textures.py`, `python3 tools/ui_art.py`.
- Icons are Twemoji (CC-BY 4.0, see `assets/icons/CREDITS.txt`).
