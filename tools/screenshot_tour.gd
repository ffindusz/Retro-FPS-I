extends SceneTree
## Debug helper: loads the main scene, teleports the player through a list
## of waypoints, and saves a screenshot at each stop. Run WITHOUT --headless:
##   Godot_v4.7-stable_win64_console.exe --path . -s tools/screenshot_tour.gd
## Output: tmp_shots/shot_<i>.png in the project root.

const PLAYER_PATH := "ViewportContainer/GameViewport/World/Player"
const FRAMES_PER_STOP := 40

# Per-level waypoint sets: [position, yaw_degrees]. Select the level with
# the TOUR_LEVEL environment variable (0-based, default 0).
const LEVEL_WAYPOINTS := {
	0: [
		[Vector3(0, 0.1, 22), 0.0],      # Room A (spawn), facing exit corridor
		[Vector3(0, 0.1, 4), 0.0],       # Room B from corridor mouth
		[Vector3(1, 0.1, 3), -76.0],     # Room B looking up at the balcony spitter
		[Vector3(19, 0.1, 2), -25.0],    # Room C, facing the ramp
		[Vector3(16, 3.4, 0), 90.0],     # Walkway over corridor 2, facing Room B
		[Vector3(0, 0.1, -15), 0.0],     # Old arena, now the teleporter chamber
	],
	1: [
		[Vector3(0, 0.1, 15), 0.0],      # Arrival room
		[Vector3(0, 0.1, 3), 0.0],       # Pillared hall + teleporter
		[Vector3(16, 0.1, 0), -90.0],    # Bridge over the pit, facing the switch
		[Vector3(22, 0.1, 0), -90.0],    # Mid-bridge
	],
	2: [
		[Vector3(0, 0.1, 16), 0.0],      # Cave entry
		[Vector3(0, 0.5, -1), 0.0],      # Grand cavern: lava lake + bridge
		[Vector3(-9, 0.1, -6), 90.0],    # Gallery, facing the switch
		[Vector3(0, 0.3, -12), 180.0],   # Looking back across the bridge
	],
	3: [
		[Vector3(0, 0.1, 13), 0.0],      # Entry room
		[Vector3(0, 0.6, -2), 0.0],      # Arena, facing the boss
		[Vector3(0, 0.1, -18), 180.0],   # Facing the secret door in the south wall
	],
}

var waypoints: Array = []
var _tour_level := 0

var _frames := 0
var _shot := 0
var _started := false


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://tmp_shots")
	var env := OS.get_environment("TOUR_LEVEL")
	_tour_level = int(env) if env != "" else 0
	waypoints = LEVEL_WAYPOINTS[_tour_level]
	change_scene_to_file("res://scenes/main.tscn")


func _process(_delta: float) -> bool:
	if current_scene == null:
		return false
	if not _started:
		_started = true
		current_scene.start_game(_tour_level)
		return false
	_frames += 1
	var player := current_scene.get_node_or_null(PLAYER_PATH)
	if player == null:
		return false
	var stop := _frames / FRAMES_PER_STOP
	var phase := _frames % FRAMES_PER_STOP
	if stop >= waypoints.size():
		return true
	if phase == 1:
		player.global_position = waypoints[stop][0]
		player.rotation.y = deg_to_rad(waypoints[stop][1])
		player.velocity = Vector3.ZERO
	elif phase == FRAMES_PER_STOP - 3:
		# Cycle weapons and fire so viewmodels/muzzle flash show in shots.
		var wm: Node3D = player.get_node("Head/Camera3D/WeaponManager")
		wm._select(stop % 3)
		wm.current_weapon().try_fire(player.get_node("Head/Camera3D"), player)
	elif phase == FRAMES_PER_STOP - 1:
		var img: Image = root.get_texture().get_image()
		img.save_png("res://tmp_shots/shot_l%d_%d.png" % [_tour_level, _shot])
		_shot += 1
	return false
