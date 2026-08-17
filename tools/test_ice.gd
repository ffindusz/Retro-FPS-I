extends "res://tools/test_base.gd"
## Debug helper: ice level test. Verifies totals, that standing on the
## frozen lake enables slide physics (ice zone counter), and that the
## freezing pool damages the player.
##   Godot_v4.7-stable_win64_console.exe --headless --path . -s tools/test_ice.gd


func _boot_level_index() -> int:
	return 3


func _tick(_delta: float) -> bool:
	var world := current_scene.get_node(WORLD_PATH)
	var player: CharacterBody3D = world.get_node_or_null("Player")
	var gs: Node = root.get_node(GAME_STATE_PATH)
	match _step:
		0:
			_expect("ice level enemy total", gs.total_enemies, 6)
			_expect("ice level secret total", gs.total_secrets, 2)
			_expect("no ice zone at spawn", player._ice_zones, 0)
			gs.health = 100000  # nearby grunts shouldn't end the test
			player.global_position = Vector3(0, 0.3, -3)  # onto the frozen lake
			player.velocity = Vector3.ZERO
			_next(600)
		1:
			_expect("ice zone entered on the lake", player._ice_zones, 1)
			gs.health = 100
			player.global_position = Vector3(5.5, 0.3, -9)  # into the freezing pool
			player.velocity = Vector3.ZERO
			_next(1600)
		2:
			_expect_less("health after 1.6s in freezing water", gs.health, 100)
			return _finish()
	return false
