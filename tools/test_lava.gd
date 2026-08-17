extends "res://tools/test_base.gd"
## Debug helper: lava hazard test in the cavern (level 3). Drops the player
## into the lake and checks the burn ticks.
##   Godot_v4.7-stable_win64_console.exe --headless --path . -s tools/test_lava.gd


func _boot_level_index() -> int:
	return 2


func _tick(_delta: float) -> bool:
	var world := current_scene.get_node(WORLD_PATH)
	var player: CharacterBody3D = world.get_node_or_null("Player")
	var gs: Node = root.get_node(GAME_STATE_PATH)
	match _step:
		0:
			_expect("cavern enemy total", gs.total_enemies, 6)
			_expect("cavern secret total", gs.total_secrets, 3)
			player.global_position = Vector3(2, 0.1, -7)  # over the lava pit
			player.velocity = Vector3.ZERO
			_next(1500)
		1:
			# 8 damage per 0.4s tick: 1.5s in the lake must bite hard.
			_expect_less("health after 1.5s in lava", gs.health, 85)
			return _finish()
	return false
