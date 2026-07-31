extends SceneTree
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
const WORLD_PATH := "ViewportContainer/GameViewport/World"

var _t0 := 0


func _initialize() -> void:
	change_scene_to_file(LEVEL_PATH)
	_t0 = Time.get_ticks_msec()


func _process(_delta: float) -> bool:
	# One wait covers the level's own _ready, the deferred scene change and
	# main.gd's boot.
	if Time.get_ticks_msec() - _t0 < 2500:
		return false

	var scene := current_scene
	print("current scene: %s (expect Main)" % (scene.name if scene else "<null>"))
	if scene == null:
		print("SOLO LEVEL TEST: FAIL")
		return true

	var world := scene.get_node_or_null(WORLD_PATH)
	var level: Node = null
	if world:
		for child in world.get_children():
			if child.scene_file_path != "":
				level = child
				break
	var loaded := level.scene_file_path if level else "<none>"
	print("level loaded: %s (expect %s)" % [loaded, LEVEL_PATH])

	var player := get_first_node_in_group("player")
	var hud := scene.get_node_or_null("Hud")
	var hud_visible: bool = hud != null and hud.visible
	print("player: %s  hud visible: %s (expect true true)"
			% [player != null, hud_visible])

	var ok: bool = scene.name == "Main" and loaded == LEVEL_PATH \
			and player != null and hud_visible
	print("SOLO LEVEL TEST: %s" % ["PASS" if ok else "FAIL"])
	return true
