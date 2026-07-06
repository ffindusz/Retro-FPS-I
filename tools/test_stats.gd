extends "res://tools/test_base.gd"
## Debug helper: stats, secrets, and barrel test in level 1.
## - kill/total tallies update (barrels don't count as enemies)
## - secret area triggers once
## - a shot barrel explodes after its fuse and splashes the nearby player
##   Godot_v4.7-stable_win64_console.exe --headless --path . -s tools/test_stats.gd


func _tick(_delta: float) -> bool:
	var world := current_scene.get_node(WORLD_PATH)
	var player: CharacterBody3D = world.get_node_or_null("Player")
	var gs: Node = root.get_node(GAME_STATE_PATH)
	match _step:
		0:
			print("level 1 totals: enemies=%d secrets=%d (expect 8 2)"
					% [gs.total_enemies, gs.total_secrets])
			world.get_node("Level01/Enemies/Grunt3").take_damage(999.0)
			world.get_node("Level01/Enemies/Spitter2").take_damage(999.0)
			_next(300)
		1:
			print("after 2 kills: kills=%d/%d (expect 2/8)" % [gs.kills, gs.total_enemies])
			# Stand in the under-landing secret nook.
			player.global_position = Vector3(17.4, 0.3, -3)
			player.velocity = Vector3.ZERO
			_next(500)
		2:
			print("secret entered: found=%d/%d (expect 1/2)"
					% [gs.secrets_found, gs.total_secrets])
			# Stand near a barrel, then shoot it: fuse -> boom -> splash.
			gs.health = 100
			player.global_position = Vector3(5, 0.3, -2)
			player.velocity = Vector3.ZERO
			world.get_node("Level01/Barrels/Barrel1").take_damage(12.0)
			_next(700)
		3:
			var barrel := world.get_node_or_null("Level01/Barrels/Barrel1")
			print("barrel shot: gone=%s player health=%d (expect true, <100 from splash)"
					% [barrel == null, gs.health])
			print("stats test done")
			return true
	return false
