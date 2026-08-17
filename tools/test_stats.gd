extends "res://tools/test_base.gd"
## Debug helper: stats, secrets, and decorative-barrel check in level 1.
## - kill/total tallies update (barrels don't count as enemies)
## - a death wakes the dormant roommate: the EnemyBase alert wakes any idle
##   skeleton in range regardless of type (here grunt wakes grunt)
## - secret area triggers once
## - a decorative barrel is inert: still placed, not damageable, no splash
##   Godot_v4.7-stable_win64_console.exe --headless --path . -s tools/test_stats.gd


func _tick(_delta: float) -> bool:
	var world := current_scene.get_node(WORLD_PATH)
	var player: CharacterBody3D = world.get_node_or_null("Player")
	var gs: Node = root.get_node(GAME_STATE_PATH)
	match _step:
		0:
			_expect("level 1 enemy total", gs.total_enemies, 8)
			_expect("level 1 secret total", gs.total_secrets, 3)
			# Kill one room-C grunt only; its dormant roommate (GruntRoomC,
			# ~4m away, no line of sight to the player) should wake.
			world.get_node("Level01/Enemies/Grunt3").take_damage(999.0)
			_next(300)
		1:
			# Untyped on purpose: naming EnemyBase here would compile the
			# enemy scripts before autoloads exist (-s quirk) and break them.
			var mate: CharacterBody3D = world.get_node("Level01/Enemies/GruntRoomC")
			_expect("wake on death: GruntRoomC noticed", mate.state, STATE_NOTICE)
			mate.take_damage(999.0)
			_next(300)
		2:
			_expect("kills after 2 deaths", gs.kills, 2)
			# Stand in the under-landing secret nook.
			player.global_position = Vector3(17.4, 0.3, -3)
			player.velocity = Vector3.ZERO
			_next(500)
		3:
			_expect("secrets found after entering the nook", gs.secrets_found, 1)
			# Decorative barrel: still placed and solid, but inert.
			gs.health = 100
			_next(300)
		4:
			var barrel: StaticBody3D = world.get_node_or_null("Level01/Barrels/Barrel1")
			_expect_true("decorative barrel still placed", barrel != null)
			_expect_false("decorative barrel not damageable",
					barrel != null and barrel.has_method("take_damage"))
			_expect("barrel did no splash damage", gs.health, 100)
			return _finish()
	return false
