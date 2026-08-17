extends "res://tools/test_base.gd"
## Debug helper: game-feel test. Walks forward (checks footsteps fire and
## the bob phase advances), then drops the player from height (checks the
## landing dip kicks in). Also verifies the music player is running.
##   Godot_v4.7-stable_win64_console.exe --headless --path . -s tools/test_feel.gd

var _max_dip := 0.0


func _every_frame(_delta: float) -> void:
	var world := current_scene.get_node(WORLD_PATH)
	var player: CharacterBody3D = world.get_node_or_null("Player")
	if player and player._land_dip > _max_dip:
		_max_dip = player._land_dip


func _tick(_delta: float) -> bool:
	var world := current_scene.get_node(WORLD_PATH)
	var player: CharacterBody3D = world.get_node_or_null("Player")
	match _step:
		0:
			_expect_true("music playing", current_scene.get_node("Music").playing)
			# Strafe within the tall spawn room so the later drop stays indoors.
			Input.action_press("move_left")
			_next(1500)
		1:
			Input.action_release("move_left")
			_expect_greater("footsteps after 1.5s walk", player.step_count, 1)
			_expect_greater("bob phase advanced", player._bob_phase, 0.0)
			player.global_position = Vector3(0, 2.1, 22)
			player.velocity = Vector3.ZERO
			_next(1200)
		2:
			_expect_greater("landing dip after 2m drop", _max_dip, 0.15)
			_expect_true("back on the floor after landing", player.is_on_floor())
			return _finish()
	return false
