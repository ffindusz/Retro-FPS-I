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
			print("music playing: %s (expect true)" % current_scene.get_node("Music").playing)
			# Strafe within the tall spawn room so the later drop stays indoors.
			Input.action_press("move_left")
			_next(1500)
		1:
			Input.action_release("move_left")
			print("after 1.5s walk: steps=%d (expect >=2) bob_phase=%.2f (expect >0)"
					% [player.step_count, player._bob_phase])
			player.global_position = Vector3(0, 2.1, 22)
			player.velocity = Vector3.ZERO
			_next(1200)
		2:
			print("after 4m drop: max land dip=%.3f (expect >=0.15), on floor=%s"
					% [_max_dip, player.is_on_floor()])
			print("feel test done")
			return true
	return false
