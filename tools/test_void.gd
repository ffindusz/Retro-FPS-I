extends "res://tools/test_base.gd"
## Debug helper: sky citadel void test. Verifies totals, then walks the
## player off a platform edge — the kill zone should end the run.
##   Godot_v4.7-stable_win64_console.exe --headless --path . -s tools/test_void.gd


func _boot_level_index() -> int:
	return 5  # citadel is level 6 now


func _tick(_delta: float) -> bool:
	var world := current_scene.get_node(WORLD_PATH)
	var player: CharacterBody3D = world.get_node_or_null("Player")
	var gs: Node = root.get_node(GAME_STATE_PATH)
	match _step:
		0:
			_expect("citadel enemy total", gs.total_enemies, 8)
			_expect("citadel secret total", gs.total_secrets, 2)
			# Step off the spawn platform into the void.
			player.global_position = Vector3(9, 0.1, 20)
			player.velocity = Vector3.ZERO
			_next(2500)
		1:
			var end := current_scene.get_node("EndScreen")
			_expect_true("end screen shown after void fall", end.visible)
			_expect("end screen result", end.get_node("Layout/ResultLabel").text,
					"YOU DIED")
			return _finish()
	return false
