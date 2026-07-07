extends "res://tools/test_base.gd"
## Debug helper: pickup behavior test in level 1's spawn room.
## - Medkit heals a damaged player and disappears
## - A full-health player can NOT collect a medkit (it stays)
## - Shells refuse collection at full ammo, then top up (capped) after firing
##   Godot_v4.7-stable_win64_console.exe --headless --path . -s tools/test_pickups.gd


func _tick(_delta: float) -> bool:
	var world := current_scene.get_node(WORLD_PATH)
	var player: CharacterBody3D = world.get_node_or_null("Player")
	var gs: Node = root.get_node(GAME_STATE_PATH)
	match _step:
		0:
			print("pickups in level 1: %d (expect 10)" % get_nodes_in_group("pickups").size())
			# Full health: medkit must refuse collection.
			player.global_position = Vector3(-4.5, 0.3, 19)
			player.velocity = Vector3.ZERO
			_next(600)
		1:
			var kit := world.get_node_or_null("Level01/Pickups/HealthA")
			print("full-hp medkit refused: still exists=%s health=%d (expect true 100)"
					% [kit != null, gs.health])
			gs.damage_player(40)
			_next(600)
		2:
			var kit := world.get_node_or_null("Level01/Pickups/HealthA")
			print("damaged then healed: health=%d (expect 85), medkit gone=%s (expect true)"
					% [gs.health, kit == null])
			# Shotgun full: shells must refuse collection.
			player.global_position = Vector3(4.7, 0.3, 19.5)
			player.velocity = Vector3.ZERO
			_next(600)
		3:
			var shells := world.get_node_or_null("Level01/Pickups/ShellsA")
			var wm: Node3D = player.get_node("Head/Camera3D/WeaponManager")
			var shotgun: Node3D = wm._weapons[1]
			print("full-ammo shells refused: still exists=%s ammo=%d/%d (expect true 24/24)"
					% [shells != null, shotgun.ammo, shotgun.max_ammo])
			# Step off, fire two shells, come back: +8 should cap at 24.
			player.global_position = Vector3(0, 0.3, 22)
			shotgun.ammo = 22
			player.global_position = Vector3(4.7, 0.3, 19.5)
			player.velocity = Vector3.ZERO
			_next(600)
		4:
			var shells := world.get_node_or_null("Level01/Pickups/ShellsA")
			var wm: Node3D = player.get_node("Head/Camera3D/WeaponManager")
			var shotgun: Node3D = wm._weapons[1]
			print("shells collected: ammo=%d (expect 24 capped), gone=%s (expect true)"
					% [shotgun.ammo, shells == null])
			print("pickup test done")
			return true
	return false
