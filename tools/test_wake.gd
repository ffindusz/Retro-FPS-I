extends "res://tools/test_base.gd"
## Debug helper: cross-type wake-on-death in level 3. The death rattle wakes ANY
## idle skeleton in range -- the alert lives in EnemyBase with no type check --
## so a dying grunt wakes a dormant spitter. Sits a grunt and a spitter together
## in the flat entry room with the player parked far off (the grotto) so both
## stay dormant, then kills the grunt.
##   Godot_v4.7-stable_win64_console.exe --headless --path . -s tools/test_wake.gd


func _boot_level_index() -> int:
	return 2  # level 3


func _tick(_delta: float) -> bool:
	var world := current_scene.get_node(WORLD_PATH)
	var player: CharacterBody3D = world.get_node_or_null("Player")
	var grunt: CharacterBody3D = world.get_node_or_null("Level03/Enemies/Grunt1")
	var spitter: CharacterBody3D = world.get_node_or_null("Level03/Enemies/Spitter1")
	match _step:
		0:
			if player == null or grunt == null or spitter == null:
				return false
			# Park the player far off so neither wakes on its own; sit the grunt
			# and spitter ~2 m apart (well within WAKE_RADIUS) in the entry room.
			player.global_position = Vector3(-3, 0.1, -19)
			player.velocity = Vector3.ZERO
			grunt.global_position = Vector3(0, 0.1, 12)
			spitter.global_position = Vector3(2, 0.1, 12)
			grunt.velocity = Vector3.ZERO
			spitter.velocity = Vector3.ZERO
			_next(500)
		1:
			print("both dormant: grunt state=%d spitter state=%d (expect 0 0 IDLE)"
					% [grunt.state, spitter.state])
			grunt.take_damage(999.0)
			_next(300)
		2:
			print("grunt death woke the spitter: state=%d (expect 1 NOTICE)" % spitter.state)
			print("wake test done")
			return true
	return false
