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

## Playing

| Input | Action |
| --- | --- |
| WASD | Move (Quake-style acceleration) |
| Mouse | Look |
| Space | Jump |
| Left mouse | Fire |
| 1 / 2 / 3 / 4, mouse wheel | Switch weapon (pistol / shotgun / rockets / plasma rifle) |
| Esc | Toggle mouse capture |

Five levels: in each of the first four, clear all enemies, then find and
**shoot the switch** to power the **teleporter** to the next level (health
and ammo carry over). The themes shift as you go — brick complex, metal
installation, a **volcanic cavern** whose lava burns anything that touches
it (enemies included; mind the bridge), and a **sky citadel** of floating
stone platforms where one wrong step off a bridge is the end. Level 5 is
the **boss** — it enrages at half health. Killing it opens a secret room;
claim the **pile of gold** inside to win. Dying restarts the level you died
on. Rockets splash — including on you.

**Pickups** are scattered through every level: medkits (+25 HP), bullets
(+24), shells (+8), rockets (+4), and plasma cells (+20). They refuse
collection while you're already full, so they stay put for when you need
them.

**Red barrels** explode when shot (and chain-react) — lure enemies close or
clear clusters, but mind the splash. Each level also hides **secret areas**
with bonus stashes; an intermission screen after every level tallies your
kills, secrets, and time.

## Project layout

- `scenes/` — main scene + levels, player, weapons, enemies, UI screens, and
  `level_objects/` (switch, teleporter, secret door, gold pile)
- `scripts/` — gameplay code (`autoload/game_state.gd` is the flow singleton)
- `shaders/` — `ps1_vertex_snap.gdshader` (world materials) and
  `ps1_post.gdshader` (dither/quantize post pass)
- `assets/` — generated placeholder textures, SFX, and shared materials
- `tools/` — headless dev scripts (`-s` runnable): texture/SFX generators,
  smoke tests (`test_flow`, `test_weapons`, `test_enemy`, `test_boss`),
  screenshot helpers

Example headless test run:

```
godot --headless --path . -s tools/test_flow.gd
```

All textures and SFX are generated deterministically by `tools/gen_textures.gd`
and `tools/gen_audio.gd`; the outputs are committed, so a clean clone runs
without any extra steps.
