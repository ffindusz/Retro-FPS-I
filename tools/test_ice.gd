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
			print("ice level totals: enemies=%d secrets=%d (expect 6 2)"
					% [gs.total_enemies, gs.total_secrets])
			print("at spawn: ice zones=%d (expect 0)" % player._ice_zones)
			gs.health = 100000  # nearby grunts shouldn't end the test
			player.global_position = Vector3(0, 0.3, -3)  # onto the frozen lake
			player.velocity = Vector3.ZERO
			_next(600)
		1:
			print("on lake: ice zones=%d (expect 1)" % player._ice_zones)
			gs.health = 100
			player.global_position = Vector3(5.5, 0.3, -9)  # into the freezing pool
			player.velocity = Vector3.ZERO
			_next(1600)
		2:
			print("after 1.6s in freezing water: health=%d (expect <100)" % gs.health)
			print("ice test done")
			return true
	return false
