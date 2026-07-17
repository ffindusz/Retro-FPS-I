# Retro FPS

A PS1/N64-style low-poly first-person shooter prototype built with **Godot 4.7**
(GDScript). Real 3D geometry — no raycasting — rendered into a 320×240
SubViewport and nearest-neighbor upscaled, with vertex-snapping, affine texture
mapping, and Bayer-dithered color quantization for the authentic wobble.

## Running

1. Get [Godot 4.7 stable](https://godotengine.org/download) (no C# needed).
2. Open `project.godot` in the editor and press **F5** — the main scene is
   `scenes/main.tscn` — or run from a terminal:

   ```
   godot --path .
   ```

On a fresh clone, `.godot/` (the import cache) doesn't exist yet — it's
gitignored, machine-local derived data. Launching the game binary directly
without it fails with cascading errors (missing audio, `WeaponBase` type not
found, HUD script errors) because nothing has been imported. Build the cache
once first, either by opening the project in the editor (which imports
automatically), or headlessly:

```
godot --headless --editor --import
```

## Playing

| Input | Action |
| --- | --- |
| WASD | Move (Quake-style acceleration) |
| Mouse | Look |
| Space | Jump |
| Left mouse | Fire |
| 1 / 2 / 3 / 4, mouse wheel | Switch weapon (pistol / shotgun / rockets / plasma rifle) |
| Esc | Pause (resume / restart level / quit to title) |
| 1–6 on the title screen, F1–F6 anytime | Level-select cheat |

Six levels: in each of the first five, clear all enemies, then find and
**shoot the switch** to power the **teleporter** to the next level (health
and ammo carry over). The themes shift as you go — brick complex, metal
installation, a **volcanic cavern** whose lava burns anything that touches
it (enemies included; mind the bridge), a **frozen cave** where the ice
lake turns your footing into a skating rink (and the freezing pool bites),
and a **sky citadel** of floating stone platforms where one wrong step off
a bridge is the end. Level 6 is the **boss** — it enrages at half health.
Killing it opens a secret room; claim the **pile of gold** inside to win.
Dying restarts the level you died on. Rockets splash — including on you.

**Pickups** are scattered through every level: medkits (+25 HP), bullets
(+24), shells (+8), rockets (+4), and plasma cells (+20). They refuse
collection while you're already full, so they stay put for when you need
them.

Each level also hides **secret areas** with bonus stashes; an intermission
screen after every level tallies your kills, secrets, and time.

## Project layout

- `scenes/` — main scene + levels, player, weapons, enemies, UI screens, and
  `level_objects/` (switch, teleporter, secret door, gold pile)
- `scripts/` — gameplay code (`autoload/game_state.gd` is the flow singleton)
- `shaders/` — `ps1_vertex_snap.gdshader` (world materials) and
  `ps1_post.gdshader` (dither/quantize post pass)
- `assets/` — generated placeholder textures, SFX, and shared materials
- `tools/` — headless dev scripts (`-s` runnable): `gen_textures.gd`/
  `gen_audio.gd` (deterministic asset generators), `probe_level.gd`
  (CSG collision probe), `screenshot_tour.gd`/`screenshot_ui.gd` (visual
  capture — run without `--headless`), and 15 smoke tests covering level
  flow (`test_flow`, `test_progression`, `test_cheat`, `test_pause`),
  combat/AI (`test_enemy`, `test_spitter`, `test_boss`, `test_weapons`),
  and movement/hazards/stats (`test_crouch`, `test_feel`, `test_ice`,
  `test_lava`, `test_void`, `test_pickups`, `test_stats`) — 14 of which
  share their boot/wait/step boilerplate via `test_base.gd`
- `project.godot` sets `rendering_method="mobile"` for performance headroom
  at this resolution; despite the resulting `Mobile` feature tag,
  `export_presets.cfg` only defines a Windows Desktop export — there's no
  actual mobile export target

Example headless test run:

```
godot --headless --path . -s tools/test_flow.gd
```

All textures and SFX are generated deterministically by `tools/gen_textures.gd`
and `tools/gen_audio.gd`; the outputs are committed, so a clean clone needs no
regeneration — just the one-time import cache build described above.
