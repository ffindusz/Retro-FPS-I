extends "res://tools/test_base.gd"
## Debug helper: pickup behavior test in level 1's spawn room.
## - A potion heals a damaged player and disappears
## - A full-health player can NOT collect a potion (it stays)
## - Quarrels refuse collection at full ammo, then top up (capped) after firing
##   Godot_v4.7-stable_win64_console.exe --headless --path . -s tools/test_pickups.gd

## Loose pickups placed in level 1: 4 potions, 1 crystals, 3 quarrels, 1 embers,
## 1 mana, plus 10 gold gems (gold joins the "pickups" group too).
const LEVEL_1_PICKUPS := 20


func _tick(_delta: float) -> bool:
	var world := current_scene.get_node(WORLD_PATH)
	var player: CharacterBody3D = world.get_node_or_null("Player")
	var gs: Node = root.get_node(GAME_STATE_PATH)
	match _step:
		0:
			_expect("pickups in level 1", get_nodes_in_group("pickups").size(),
					LEVEL_1_PICKUPS)
			# Full health: the potion must refuse collection.
			player.global_position = Vector3(-4.5, 0.3, 19)
			player.velocity = Vector3.ZERO
			_next(600)
		1:
			var potion := world.get_node_or_null("Level01/Pickups/HealthA")
			_expect_true("full-hp potion refused (still placed)", potion != null)
			_expect("full-hp potion did not heal", gs.health, 100)
			gs.damage_player(40)
			_next(600)
		2:
			var potion := world.get_node_or_null("Level01/Pickups/HealthA")
			_expect("damaged player healed by the potion", gs.health, 85)
			_expect_true("collected potion despawned", potion == null)
			# Crossbow full: quarrels must refuse collection.
			player.global_position = Vector3(4.7, 0.3, 19.5)
			player.velocity = Vector3.ZERO
			_next(600)
		3:
			var quarrels := world.get_node_or_null("Level01/Pickups/QuarrelsA")
			var wm: Node3D = player.get_node("Head/Camera3D/WeaponManager")
			var crossbow: Node3D = wm._weapons[1]
			_expect_true("full-ammo quarrels refused (still placed)",
					quarrels != null)
			_expect("crossbow still at full ammo", crossbow.ammo,
					crossbow.max_ammo)
			# Step off, spend two quarrels, come back: +8 should cap at max.
			player.global_position = Vector3(0, 0.3, 22)
			crossbow.ammo = 22
			player.global_position = Vector3(4.7, 0.3, 19.5)
			player.velocity = Vector3.ZERO
			_next(600)
		4:
			var quarrels := world.get_node_or_null("Level01/Pickups/QuarrelsA")
			var wm: Node3D = player.get_node("Head/Camera3D/WeaponManager")
			var crossbow: Node3D = wm._weapons[1]
			_expect("quarrels collected and capped at max", crossbow.ammo,
					crossbow.max_ammo)
			_expect_true("collected quarrels despawned", quarrels == null)
			return _finish()
	return false
