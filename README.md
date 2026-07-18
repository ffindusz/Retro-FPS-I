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
| 1 / 2 / 3 / 4, mouse wheel | Switch weapon (wand / crossbow / fire staff / tome) |
| Esc | Pause (resume / restart level / quit to title) |
| O on the title or pause screen | Options (mouse sensitivity, music/SFX volume, PS1 dither filter) |
| 1–6 on the title screen, F1–F6 anytime | Level-select cheat |
| 0 on the title screen | Model test stage (animated character viewer) |

Six levels: in each of the first five, clear all enemies, then find and
**shoot the switch** to power the **teleporter** to the next level (health
and ammo carry over). The themes shift as you go — brick complex, metal
installation, a **volcanic cavern** whose lava burns anything that touches
it (enemies included; mind the bridge), a **frozen cave** where the ice
lake turns your footing into a skating rink (and the freezing pool bites),
and a **sky citadel** of floating stone platforms where one wrong step off
a bridge is the end. Level 6 is the **boss** — it enrages at half health.
Killing it opens a secret room; claim the **chest of gold** inside to win.
Dying restarts the level you died on. Staff fireballs splash — including on you.

**Pickups** are scattered through every level: potions (+25 HP), bolt boxes
(+24), quarrel cases (+8), powder kegs (+4), and mana flasks (+20). They refuse
collection while you're already full, so they stay put for when you need
them.

Each level also hides **secret areas** with bonus stashes; an intermission
screen after every level tallies your kills, secrets, and time.

The **options menu** (O on the title or pause screen) adjusts mouse
sensitivity, music and SFX volume (separate audio buses), and the PS1
dither/quantize filter; settings persist to `user://settings.cfg`.

## Project layout

- `scenes/` — main scene + levels, player, weapons, enemies, UI screens, and
  `level_objects/` (switch, teleporter, secret door, gold pile)
- `scripts/` — gameplay code (`autoload/game_state.gd` is the flow singleton,
  `autoload/settings.gd` the persistent user settings — sensitivity, volumes,
  dither — saved to `user://settings.cfg`; `default_bus_layout.tres` defines
  the Music/SFX audio buses they control)
- `shaders/` — `ps1_vertex_snap.gdshader` (world materials) and
  `ps1_post.gdshader` (dither/quantize post pass)
- `assets/` — generated placeholder textures, SFX, shared materials, and
  external CC0 models (`models/`, see CREDITS.md); `scenes/props/` wraps the
  models as placeable props (PS1 materials applied by `tools/import_prop.gd`)
- `tools/` — headless dev scripts (`-s` runnable): `gen_textures.gd`/
  `gen_audio.gd` (deterministic asset generators), `probe_level.gd`
  (CSG collision probe), `screenshot_tour.gd`/`screenshot_ui.gd` (visual
  capture — run without `--headless`), and 17 smoke tests covering level
  flow (`test_flow`, `test_progression`, `test_cheat`, `test_pause`,
  `test_settings`),
  combat/AI (`test_enemy`, `test_spitter`, `test_boss`, `test_weapons`),
  movement/hazards/stats (`test_crouch`, `test_feel`, `test_ice`,
  `test_lava`, `test_void`, `test_pickups`, `test_stats`), and the
  external-model props (`test_props`) — all sharing their boot/wait/step
  boilerplate via `test_base.gd`
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

## Credits & licenses

The 3D models under `assets/models/` (skeleton enemies, weapons, props,
pickups, gold chest) are **CC0 (public domain)** assets by
[Kay Lousberg](https://kaylousberg.com) from the *KayKit Dungeon Remastered*,
*Character Pack: Skeletons*, and *Character Pack: Adventurers* packs —
crediting is not required by the license, but happily given. See
[CREDITS.md](CREDITS.md) for the per-file list and source links. Everything
else (code, textures, audio) is made in-repo.
