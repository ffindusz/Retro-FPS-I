extends SceneTree
## Debug helper: loads the main scene, teleports the player through a list
## of waypoints, and saves a screenshot at each stop. Run WITHOUT --headless:
##   Godot_v4.7-stable_win64_console.exe --path . -s tools/screenshot_tour.gd
## Output: tmp_shots/shot_<i>.png in the project root.

const PLAYER_PATH := "ViewportContainer/GameViewport/World/Player"
const FRAMES_PER_STOP := 40

# [position, yaw_degrees]
var waypoints := [
	[Vector3(0, 0.1, 22), 0.0],      # Room A (spawn), facing exit corridor
	[Vector3(0, 0.1, 4), 0.0],       # Room B from corridor mouth
	[Vector3(19, 0.1, 2), -25.0],    # Room C, facing the ramp
	[Vector3(16, 3.4, 0), 90.0],     # Walkway over corridor 2, facing Room B
	[Vector3(0, 0.1, -15), 0.0],     # Boss arena entrance
]

var _frames := 0
var _shot := 0


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://tmp_shots")
	change_scene_to_file("res://scenes/main.tscn")


func _process(_delta: float) -> bool:
	_frames += 1
	var player := current_scene.get_node_or_null(PLAYER_PATH) if current_scene else null
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
		img.save_png("res://tmp_shots/shot_%d.png" % _shot)
		_shot += 1
	return false
