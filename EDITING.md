# Editing Retro FPS in the Godot editor

This project was originally authored by hand-editing `.tscn` text. It is now
set up so the same work can be done in the editor GUI, and so both routes
produce small, reviewable diffs. This file is the working reference for that.

For what the game *is*, see [README.md](README.md).

---

## Play-test one level

Open `scenes/levels/level_0X.tscn` and press **F6**.

A level scene contains no camera, no player, no `WorldEnvironment` and no
`Sun` — those live in `scenes/main.tscn`. So `LevelRoot` (on every level root)
notices it is running standalone, hands off to `main.tscn`, and asks it to boot
that level. You get the real HUD, the 320×240 PS1 viewport, lighting and
working enemies, not an approximation.

**F5** still plays the whole game from the title screen.

Other ways in, unchanged: **F1–F7** warp to a campaign level from anywhere,
**1–7** on the title screen do the same, **0** loads the model test stage, and
**F8** toggles the debug overlay (FPS, draw calls, live player position/yaw).

---

## Build geometry

### A room

Instance `scenes/level_blocks/room_block.tscn` into the level's `LevelCSG`
node, then drag its `room_size` handles in the viewport.

`RoomBlock` generates the three CSG brushes the hand-built levels spell out
individually — a solid Shell, a smaller Cut subtracted to hollow it, and a
Floor slab poking up through the bottom so the floor reads as its own
material. One node, one `wall_material` slot.

| Property | Meaning |
| --- | --- |
| `room_size` | Interior dimensions — the space you can walk around in |
| `wall_thickness` | Solidity of walls, ceiling and underfloor |
| `wall_material` | Walls **and** the inner faces the Cut brush produces |
| `build_floor` | Off for a room that opens onto whatever is below, e.g. a ledge over lava |
| `floor_material` | The slab |
| `floor_thickness` | Slab depth |
| `floor_lip` | How far the slab pokes up past `y=0`; stops it z-fighting the interior floor |

**The origin sits at the centre of the floor**, not the middle of the box, so a
room dropped on a point is standing on it. The interior spans `y ∈ [0,
room_size.y]`.

The generated brushes are deliberately given no `owner`, so they are rebuilt on
load rather than written into the level file. The `.tscn` stores *a room*, not
three boxes.

### Doorways and windows

Add a `CSGBox3D` as a **sibling** of the room block (inside `LevelCSG`, not
inside the block), set `operation` to Subtraction, and push it through the
wall.

A nested combiner is a single operand to its parent, so a later sibling
subtraction still carves through these walls. What nesting *prevents* is an
unrelated Cut elsewhere in the level reaching in and hollowing your room by
accident — a real hazard in one big flat combiner.

> **Give the subtract brush the wall material too.** A subtractive brush
> without one leaves the surface it exposes untextured. That is exactly what
> commits `31a62e6` and `2d181d9` had to fix.

### The existing levels

Levels 1–7 are flat CSG using the `Shell*` / `Cut*` / `Floor*` naming idiom and
are deliberately left that way. `RoomBlock` is for new rooms. Retrofitting the
old ones would be a large, risky rewrite for no gameplay gain — and retexturing
one of them still means editing the Shell, the Cut and the Floor separately.

---

## Place entities

Drag any scene from `scenes/enemies/`, `scenes/level_objects/` or
`scenes/props/` into the level and position it. Nothing else is required.

Groups are added at runtime by the scripts themselves, so anything you drop in
is counted automatically:

- a pickup or chest joins `gold` → counted in the level's treasure total
- an enemy joins `enemies` → counted for the kill tally, and gates the switch
- a secret area joins `secret_areas` → counted for the secrets tally

The intermission stats and the "all enemies down" switch arming both follow
from that with no extra wiring.

Collision layers, if you add something solid of your own: **1 = world,
2 = player, 4 = enemies**. Shootable objects sit on layer 4 so hitscan rays and
splash damage register via `take_damage()`.

---

## Tune entities in the Inspector

Select an instance and edit it. Available knobs include:

| Node | Exposed |
| --- | --- |
| Enemies | `max_health`, `move_speed`, `notice_range`, `attack_range`, `attack_damage`, `attack_interval`, `notice_delay`, `turn_speed`, `voice_pitch`, `wake_radius` |
| Boss | volley size, enraged volley size, spread |
| Rogue | cloak/decloak range and reveal time |
| Switch | five crystal state colours, `poll_interval` |
| Teleporter | `destination` (next level / new loop / monument), `departure_time`, `vortex_swell`, `halo_swell`, `flare_energy` |
| Pickup | `type`, `amount`, spin/bob, glow size and alpha |
| Chest | `value` |
| Secret door | `slide_distance`, `slide_time`, `open_on_boss_death` |
| Barricade | `max_health`, `dust_color` |
| Player | look, movement, crouch and feel groups |
| Hazards | `damage_per_tick`, `tick_interval` |

Values changed here are stored per instance in the level file, so two grunts in
the same level can differ.

---

## Wire level logic

Two NodePath contracts drive level completion:

- **Switch → Teleporter**: set `teleporter_path` on the crystal switch
- **Lever → Secret door**: set `door_path` on the lever

Both report a **configuration warning** in the scene tree if the path is unset
or no longer resolves, distinguishing the two cases. A path broken by renaming
a node shows up as a yellow triangle instead of as a level you can clear but
never leave.

`LevelRoot` warns the same way when a level has no `Spawns/PlayerSpawn`, and
`RoomBlock` warns when it has no materials or a non-positive size.

---

## Add or reorder a level

1. Build the scene under `scenes/levels/`.
2. Put the `LevelRoot` script on its root node.
3. Give it a `Spawns/PlayerSpawn` (a `Marker3D`) — `main.gd` places the player
   there by exact path.
4. Add a `Switch` wired to a `Teleporter` so the level can be finished.
5. Open `assets/level_catalog.tres` and drop the scene into the `levels` array,
   in play order.

That is the whole job — no script changes.

`extras` is the second array: scenes reachable only by cheat, like the model
test stage. Keeping them out of `levels` is what stops the teleporter walking
into them.

Optional: set `LevelRoot.display_name` to override the "LEVEL 4" arrival
banner with a real name. Empty means the default.

> The warp cheat stops at **F7** however long the campaign gets, because F8 is
> the debug overlay. Title-screen digits go up to 9.

---

## Textures and materials

**Add a texture**: drop a PNG into `assets/textures/`. No generator function
needed — `tools/gen_textures.gd` only ever overwrites its own eleven filenames,
so anything else you put there is left alone. `[importer_defaults]` in
`project.godot` gives new textures the house import settings (lossless, Detect
3D off, mipmaps on), so they will not silently re-import to VRAM compression
the first time they appear in 3D.

Mipmaps are **on for world tiles** and **off for the FX sprite sheets**
(`burst_sheet`, `flame_sheet`, `muzzle_flash`, `swirl`), where they would bleed
neighbouring frames into each other. Keep that split for anything new.

**Make a material**: duplicate `assets/materials/mat_template_ps1.tres` in the
FileSystem dock and point `albedo_texture` at your PNG. It carries the house
values:

```
snap_resolution = 240      # matches the 320x240 SubViewport
affine_strength = 0.0      # the wobble reads more legibly without it
world_uv        = 1.0      # world-space planar UVs
uv_scale        = 0.5      # one 128px tile every 2 m
```

`world_uv = 1` is why level geometry needs no UV work at all: texel density is
uniform however you resize a brush. Prop materials made by
`tools/import_prop.gd` deliberately use `0`, because imported models have real
UVs.

**Regenerating the procedural textures** (`tools/gen_textures.gd`): fixed seeds
do *not* make a generator edit-proof. Each one draws from a single RNG stream,
so inserting a noise layer or reordering draws re-rolls that texture's entire
appearance. Append rather than splice, and re-run a screenshot tour if you do.

**Adding a new model**: each `.glb.import` / `.gltf.import` needs
`import_script/path="res://tools/import_prop.gd"` under `[params]`, which
converts its materials to the PS1 shader. Set it in the Import dock, then
re-import.

---

## Committing editor changes

Scene files are in Godot's canonical format — every file has its own `uid://`,
references carry uids, and nodes have `unique_id`. A save from the editor
therefore produces a diff of only what you actually changed.

`.gitattributes` pins these text formats to `eol=lf`. **Do not remove it.**
Without it, `core.autocrlf` rewrites `.tscn` to CRLF on checkout, and because a
scene stores a multi-line string property as literal lines, the editor then
parses a label as `"MINION\r\nIdle"` and saves the stray carriage return into
the string value.

> Git-Bash / MSYS `grep`, `sed` and `awk` silently strip `\r`, so they will
> lie to you about line endings. Use `file` or `git ls-files --eol`.

Opening the project in the editor also rewrites `project.godot` (it sorts
sections and drops settings that match their default). That formatting is
already committed, so it should stay quiet.

---

## Checking your work

Godot is not on PATH; run it from the repo root.

```
# One level's worth of geometry, by raycast
./Godot_v4.7-stable_win64_console.exe --headless --path . -s tools/probe_level.gd

# Any single smoke test
./Godot_v4.7-stable_win64_console.exe --headless --path . -s tools/test_flow.gd

# Screenshots — note: NO --headless, writes to tmp_shots/
TOUR_LEVEL=2 ./Godot_v4.7-stable_win64.exe --path . -s tools/screenshot_tour.gd
```

There are 29 headless smoke tests in `tools/`; `test_audio` and `test_sfx_bus`
need a real audio driver and so must run without `--headless`. Worth running
after edits:

| You changed | Run |
| --- | --- |
| A level's layout | `test_progression`, `test_treasure`, `test_spawns`, `probe_level` |
| The catalog | `test_catalog`, `test_cheat`, `test_solo_level` |
| An enemy | `test_enemy`, `test_spitter`, `test_boss`, `test_rogue`, `test_wake` |
| A room block | `test_room_block` |
| Props or models | `test_props`, `test_spawns` |
| Anything in the boot path | `test_flow`, `test_progression` |
| The endgame or difficulty scaling | `test_loop`, `test_progression` |
| Where an enemy stands | `test_spawns` |

`test_spawns` is the one to reach for after moving a solid prop: it walks every
campaign level and checks no enemy is authored inside geometry and none is
walled into a pocket it cannot leave. Both failures have shipped here -- a bed
laid across the mouth of level 5's south cell sealed a grunt in, and level 7's
Rogue1 spawned inside a crate. It carries a short baseline of spawns that were
already overlapping when it was written; clearing one means deleting its line
from `KNOWN_EMBEDDED` / `KNOWN_WALLED`, which the test asks for by failing.

### Maintenance tools

`tools/normalize_scenes.gd` re-canonicalizes scene files. It **must** run with
`--editor`:

```
./Godot_v4.7-stable_win64_console.exe --headless --editor -s tools/normalize_scenes.gd
```

> Do not "simplify" it to `instantiate(GEN_EDIT_STATE_MAIN)` +
> `PackedScene.pack()` + `ResourceSaver.save()`. That looks equivalent and is
> not: it **inlines exported PackedScene references**, so `weapon_launcher`'s
> `projectile_scene` stops pointing at `projectile_rocket.tscn` and becomes a
> private copy. The plain non-editor save writes a third, different format
> again. Only the editor's own save path is correct.

`tools/dump_scenes.gd` writes a structural dump of every node and stored
property of every scene. Diff it before and after any bulk scene change — that
is what caught the inlining above, and it is deterministic where screenshots
are not (torch flicker, particles and AI make those differ run to run).

---

## Known limits

- **Levels 1–7 are still flat CSG.** `RoomBlock` only helps new rooms.
- **Enemy animation clip names are not exported.** They are `_clip_*` bindings
  to specific KayKit clips, assigned per subclass after `super()` — exporting
  them would let `_ready()` silently overwrite Inspector edits, which is the
  bug that had to be fixed for `voice_pitch`.
- **No scene-tree icons yet**, so a 128-node level tree is read by name rather
  than by shape.
- **The PS1 shader has no alpha path**, so cutout or transparent level textures
  need a shader change first.
