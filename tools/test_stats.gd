extends "res://tools/test_base.gd"
## Debug helper: stats, secrets, and decorative-barrel check in level 1.
## - kill/total tallies update (barrels don't count as enemies)
## - a death wakes the dormant roommate (wake-on-death alert)
## - secret area triggers once
## - a decorative barrel is inert: still placed, not damageable, no splash
##   Godot_v4.7-stable_win64_console.exe --headless --path . -s tools/test_stats.gd


func _tick(_delta: float) -> bool:
	var world := current_scene.get_node(WORLD_PATH)
	var player: CharacterBody3D = world.get_node_or_null("Player")
	var gs: Node = root.get_node(GAME_STATE_PATH)
	match _step:
		0:
			print("level 1 totals: enemies=%d secrets=%d (expect 8 2)"
					% [gs.total_enemies, gs.total_secrets])
			# Kill the room C grunt only; its dormant roommate (Spitter2,
			# ~4m away, no line of sight to the player) should wake.
			world.get_node("Level01/Enemies/Grunt3").take_damage(999.0)
			_next(300)
		1:
			# Untyped on purpose: naming EnemyBase here would compile the
			# enemy scripts before autoloads exist (-s quirk) and break them.
			var spitter: CharacterBody3D = world.get_node("Level01/Enemies/Spitter2")
			print("wake on death: Spitter2 state=%d (expect 1 NOTICE)" % spitter.state)
			spitter.take_damage(999.0)
			_next(300)
		2:
			print("after 2 kills: kills=%d/%d (expect 2/8)" % [gs.kills, gs.total_enemies])
			# Stand in the under-landing secret nook.
			player.global_position = Vector3(17.4, 0.3, -3)
			player.velocity = Vector3.ZERO
			_next(500)
		3:
			print("secret entered: found=%d/%d (expect 1/2)"
					% [gs.secrets_found, gs.total_secrets])
			# Decorative barrel: still placed and solid, but inert.
			gs.health = 100
			_next(300)
		4:
			var barrel: StaticBody3D = world.get_node_or_null("Level01/Barrels/Barrel1")
			print("barrel inert: exists=%s damageable=%s player health=%d (expect true, false, 100)"
					% [barrel != null,
					barrel != null and barrel.has_method("take_damage"), gs.health])
			print("stats test done")
			return true
	return false
