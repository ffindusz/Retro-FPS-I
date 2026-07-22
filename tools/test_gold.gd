extends "res://tools/test_base.gd"
## Debug helper: treasure/score check in level 5 (gold nook, shootable chest,
## and the lever -> secret vault).
## - the level's gold total counts loose gems, the chest, and the vault gems
## - stepping onto a gem collects it; shooting the chest banks a lump reward
## - shooting the arrival lever opens its linked secret door (it slides down),
##   revealing the vault gems
##   Godot_v4.7-stable_win64_console.exe --headless --path . -s tools/test_gold.gd

const GEM1 := Vector3(-27.3, 0.3, 3.2)       # GoldNook1
const GEM2 := Vector3(-27.6, 0.3, 4.6)       # GoldNook2
const VAULT_GEM := Vector3(-1.8, 0.3, 25.0)  # GoldVault1

var _door_y0 := 0.0


func _boot_level_index() -> int:
	return 4  # level_05


func _tick(_delta: float) -> bool:
	var world := current_scene.get_node(WORLD_PATH)
	var player: CharacterBody3D = world.get_node_or_null("Player")
	var gs: Node = root.get_node(GAME_STATE_PATH)
	match _step:
		0:
			print("level 5 gold total: total_gold=%d score=%d (expect 10 0)"
					% [gs.total_gold, gs.score])
			player.global_position = GEM1
			player.velocity = Vector3.ZERO
			_next(400)
		1:
			print("after 1 gem: score=%d gold_found=%d (expect 100 1)"
					% [gs.score, gs.gold_found])
			player.global_position = GEM2
			player.velocity = Vector3.ZERO
			_next(400)
		2:
			print("after 2 gems: score=%d gold_found=%d/%d (expect 200 2/10)"
					% [gs.score, gs.gold_found, gs.total_gold])
			world.get_node("Level05/Props/ChestTreasury").take_damage(999.0)
			_next(400)
		3:
			print("after chest: score=%d gold_found=%d (expect 500 3)"
					% [gs.score, gs.gold_found])
			# Shoot the arrival lever; its linked secret door should open.
			var door: Node3D = world.get_node("Level05/Props/SecretDoorVault")
			_door_y0 = door.position.y
			world.get_node("Level05/Props/SecretLeverArrival").take_damage(999.0)
			_next(1400)
		4:
			var door: Node3D = world.get_node("Level05/Props/SecretDoorVault")
			print("secret door opened: y %.2f -> %.2f (expect lower)"
					% [_door_y0, door.position.y])
			player.global_position = VAULT_GEM
			player.velocity = Vector3.ZERO
			_next(400)
		5:
			print("after vault gem: score=%d gold_found=%d/%d (expect 600 4/10)"
					% [gs.score, gs.gold_found, gs.total_gold])
			print("stats_line: %s" % gs.stats_line())
			print("gold test done")
			return true
	return false
