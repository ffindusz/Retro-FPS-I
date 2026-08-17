extends "res://tools/test_base.gd"
## Verifies the standalone-level path (pressing F6 on a level scene in the
## editor). Running a level on its own used to give a black, unplayable scene
## -- no camera, no player, no lighting. LevelRoot now hands off to main.tscn
## and asks it to boot that level, so this checks the handoff lands: the Main
## control is current, the HUD is up, a player exists, and the level under
## %World is the one we asked for -- not level 1.
##
## Run headless (wall-clock waits, the handoff is deferred by a frame):
##   Godot_v4.7-stable_win64_console.exe --headless --path . -s tools/test_solo_level.gd

## Deliberately not level 1: booting the campaign from the title would also
## produce a player and a HUD, so only a mid-campaign level proves the index
## lookup worked.
const LEVEL_PATH := "res://scenes/levels/level_03.tscn"

var _t0 := 0


## Opens the level directly instead of main.tscn -- that handoff is the thing
## under test.
func _initialize() -> void:
	change_scene_to_file(LEVEL_PATH)
	_t0 = Time.get_ticks_msec()


## LevelRoot boots the game itself, so the harness must not call start_game.
func _skip_auto_start() -> bool:
	return true


func _tick(_delta: float) -> bool:
	# One wait covers the level's own _ready, the deferred scene change and
	# main.gd's boot. Gated here rather than through _wait_until because
	# _skip_auto_start() hands us the very first frame.
	if Time.get_ticks_msec() - _t0 < 2500:
		return false

	var scene := current_scene
	_expect("handed off to the main scene", scene.name, "Main")

	var world := scene.get_node_or_null(WORLD_PATH)
	var level: Node = null
	if world:
		for child in world.get_children():
			if child.scene_file_path != "":
				level = child
				break
	_expect("level booted", level.scene_file_path if level else "<none>", LEVEL_PATH)

	var hud := scene.get_node_or_null("Hud")
	_expect_true("player exists", get_first_node_in_group("player") != null)
	_expect_true("HUD is visible", hud != null and hud.visible)
	return _finish()
