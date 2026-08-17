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
			_expect("level 5 gold total", gs.total_gold, 10)
			_expect("score starts at zero", gs.score, 0)
			player.global_position = GEM1
			player.velocity = Vector3.ZERO
			_next(400)
		1:
			_expect("score after 1 gem", gs.score, 100)
			_expect("gold_found after 1 gem", gs.gold_found, 1)
			player.global_position = GEM2
			player.velocity = Vector3.ZERO
			_next(400)
		2:
			_expect("score after 2 gems", gs.score, 200)
			_expect("gold_found after 2 gems", gs.gold_found, 2)
			# Shoot the chest from the +z (room) side; a gem pops toward there.
			var chest: Node3D = world.get_node("Level05/Props/ChestTreasury")
			chest.take_damage(999.0, chest.global_position + Vector3(0, 1, 2))
			# Stand where the gem lands so walking over it banks the reward.
			var land := chest.global_position + Vector3(0, 0.3, 1)
			player.global_position = land
			player.velocity = Vector3.ZERO
			_next(900)
		3:
			_expect("score after the chest gem", gs.score, 500)
			_expect("gold_found after the chest gem", gs.gold_found, 3)
			# Shoot the arrival lever; its linked secret door should open.
			var door: Node3D = world.get_node("Level05/Props/SecretDoorVault")
			_door_y0 = door.position.y
			world.get_node("Level05/Props/SecretLeverArrival").take_damage(999.0)
			_next(1400)
		4:
			var door: Node3D = world.get_node("Level05/Props/SecretDoorVault")
			_expect_less("lever slid the secret door down", door.position.y,
					_door_y0)
			player.global_position = VAULT_GEM
			player.velocity = Vector3.ZERO
			_next(400)
		5:
			_expect("score after the vault gem", gs.score, 600)
			_expect("gold_found after the vault gem", gs.gold_found, 4)
			print("stats_line: %s" % gs.stats_line())
			return _finish()
	return false
