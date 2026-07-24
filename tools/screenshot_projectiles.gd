extends SceneTree
## Debug helper: projectile-visual check. Boots the boss arena (level 7),
## parks the invincible player in front of the boss, fires the player's own
## bolt, and saves timed screenshots so boss fireballs and player plasma are
## caught mid-flight. Run WITHOUT --headless:
##   Godot_v4.7-stable_win64_console.exe --path . -s tools/screenshot_projectiles.gd
## Output: tmp_shots/proj_<i>.png in the project root.

const PLAYER_PATH := "ViewportContainer/GameViewport/World/Player"
## Shot moments (seconds after placement): spread across the boss's volley
## rhythm so at least a few frames have fireballs in the air.
const SHOT_TIMES := [2.2, 2.6, 3.0, 3.4, 3.8, 4.2]

var _started := false
var _placed := false
var _start_ms := 0
var _shot := 0


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://tmp_shots")
	change_scene_to_file("res://scenes/main.tscn")


func _process(_delta: float) -> bool:
	if current_scene == null:
		return false
	if not _started:
		_started = true
		current_scene.start_game(6)
		return false
	var player := current_scene.get_node_or_null(PLAYER_PATH)
	if player == null:
		return false
	if not _placed:
		_placed = true
		root.get_node("GameState").health = 100000
		player.global_position = Vector3(0, 0.6, -2)
		player.rotation.y = 0.0
		player.velocity = Vector3.ZERO
		_start_ms = Time.get_ticks_msec()
		return false
	var t := (Time.get_ticks_msec() - _start_ms) / 1000.0
	if _shot < SHOT_TIMES.size() and t >= float(SHOT_TIMES[_shot]):
		# A player bolt in the same frame: TOME is weapon slot 4 (index 3).
		var wm: Node3D = player.get_node("Head/Camera3D/WeaponManager")
		wm._select(3)
		wm.current_weapon().try_fire(player.get_node("Head/Camera3D"), player)
		var img: Image = root.get_texture().get_image()
		img.save_png("res://tmp_shots/proj_%d.png" % _shot)
		_shot += 1
	return _shot >= SHOT_TIMES.size()
