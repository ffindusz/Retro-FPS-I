extends "res://tools/test_base.gd"
## Debug helper: full campaign progression test.
## L1: shoot switch -> teleporter activates -> step on pad -> L2 loads with
## ammo persisted. L2: same -> L3. L3: kill boss -> secret door slides open
## -> touch the gold -> win screen.
##   Godot_v4.7-stable_win64_console.exe --headless --path . -s tools/test_progression.gd

var _ammo_before := -1
var _door_y0 := 0.0


func _tick(_delta: float) -> bool:
	var world := current_scene.get_node(WORLD_PATH)
	var player: CharacterBody3D = world.get_node_or_null("Player")
	var gs: Node = root.get_node(GAME_STATE_PATH)
	match _step:
		0:
			# Effectively invincible so ambient enemy hits can't derail the test.
			gs.health = 100000
			var cam: Camera3D = player.get_node("Head/Camera3D")
			var wm: Node3D = cam.get_node("WeaponManager")
			wm.current_weapon().try_fire(cam, player)
			_ammo_before = wm.current_weapon().ammo
			# Locked switch must refuse while enemies are alive.
			var sw: Node = world.get_node("Level01/Switch")
			var tp: Node = world.get_node("Level01/Teleporter")
			sw.take_damage(5.0)
			print("L1 locked switch shot: teleporter active=%s (expect false), enemies=%d"
					% [tp._active, get_nodes_in_group("enemies").size()])
			for e in get_nodes_in_group("enemies"):
				e.take_damage(99999.0)
			_step = 10
			_wait_until = Time.get_ticks_msec() + 700
		10:
			var sw: Node = world.get_node("Level01/Switch")
			var tp: Node = world.get_node("Level01/Teleporter")
			print("L1 all enemies dead: switch state=%d (expect 1 ARMED)" % sw._state)
			sw.take_damage(5.0)
			print("L1 armed switch shot: teleporter active=%s (expect true)" % tp._active)
			player.global_position = tp.global_position + Vector3(0, 0.3, 0)
			player.velocity = Vector3.ZERO
			_step = 20
			_wait_until = Time.get_ticks_msec() + 800
		20:
			var inter := current_scene.get_node("Intermission")
			print("intermission: visible=%s paused=%s stats=[%s]"
					% [inter.visible, paused, inter.get_node("Layout/StatsLabel").text])
			_key(KEY_SPACE)
			_step = 1
			_wait_until = Time.get_ticks_msec() + 800
		1:
			var l2 := world.get_node_or_null("Level02")
			var wm: Node3D = player.get_node("Head/Camera3D/WeaponManager")
			print("after pad: Level02 loaded=%s (expect true), pistol ammo=%d (expect %d)"
					% [l2 != null, wm.current_weapon().ammo, _ammo_before])
			for e in get_nodes_in_group("enemies"):
				e.take_damage(99999.0)
			_step = 11
			_wait_until = Time.get_ticks_msec() + 700
		11:
			var sw: Node = world.get_node("Level02/Switch")
			var tp: Node = world.get_node("Level02/Teleporter")
			sw.take_damage(5.0)
			print("L2 cleared + switch shot: teleporter active=%s (expect true)" % tp._active)
			player.global_position = tp.global_position + Vector3(0, 0.3, 0)
			player.velocity = Vector3.ZERO
			_step = 21
			_wait_until = Time.get_ticks_msec() + 800
		21:
			_key(KEY_SPACE)
			_step = 30
			_wait_until = Time.get_ticks_msec() + 800
		30:
			var l3 := world.get_node_or_null("Level03")
			print("after pad2: Level03 (cavern) loaded=%s (expect true)" % (l3 != null))
			for e in get_nodes_in_group("enemies"):
				e.take_damage(99999.0)
			_step = 31
			_wait_until = Time.get_ticks_msec() + 700
		31:
			var sw: Node = world.get_node("Level03/Switch")
			var tp: Node = world.get_node("Level03/Teleporter")
			sw.take_damage(5.0)
			print("L3 cleared + switch shot: teleporter active=%s (expect true)" % tp._active)
			player.global_position = tp.global_position + Vector3(0, 0.3, 0)
			player.velocity = Vector3.ZERO
			_step = 32
			_wait_until = Time.get_ticks_msec() + 800
		32:
			_key(KEY_SPACE)
			_step = 50
			_wait_until = Time.get_ticks_msec() + 800
		50:
			var l4 := world.get_node_or_null("Level04")
			print("after pad3: Level04 (ice) loaded=%s (expect true)" % (l4 != null))
			for e in get_nodes_in_group("enemies"):
				e.take_damage(99999.0)
			_step = 51
			_wait_until = Time.get_ticks_msec() + 700
		51:
			var sw: Node = world.get_node("Level04/Switch")
			var tp: Node = world.get_node("Level04/Teleporter")
			sw.take_damage(5.0)
			print("L4 cleared + switch shot: teleporter active=%s (expect true)" % tp._active)
			player.global_position = tp.global_position + Vector3(0, 0.3, 0)
			player.velocity = Vector3.ZERO
			_step = 52
			_wait_until = Time.get_ticks_msec() + 800
		52:
			_key(KEY_SPACE)
			_step = 40
			_wait_until = Time.get_ticks_msec() + 800
		40:
			var l5 := world.get_node_or_null("Level05")
			print("after pad4: Level05 (citadel) loaded=%s (expect true)" % (l5 != null))
			for e in get_nodes_in_group("enemies"):
				e.take_damage(99999.0)
			_step = 41
			_wait_until = Time.get_ticks_msec() + 700
		41:
			var sw: Node = world.get_node("Level05/Switch")
			var tp: Node = world.get_node("Level05/Teleporter")
			sw.take_damage(5.0)
			print("L5 cleared + switch shot: teleporter active=%s (expect true)" % tp._active)
			player.global_position = tp.global_position + Vector3(0, 0.3, 0)
			player.velocity = Vector3.ZERO
			_step = 42
			_wait_until = Time.get_ticks_msec() + 800
		42:
			_key(KEY_SPACE)
			_step = 2
			_wait_until = Time.get_ticks_msec() + 800
		2:
			var l6 := world.get_node_or_null("Level06")
			var boss: Node = world.get_node_or_null("Level06/Enemies/Boss")
			var door: Node3D = world.get_node("Level06/SecretDoor")
			_door_y0 = door.position.y
			print("after pad5: Level06 loaded=%s boss=%s (expect true true)"
					% [l6 != null, boss != null])
			boss.take_damage(9999.0)
			_step = 3
			_wait_until = Time.get_ticks_msec() + 3000
		3:
			var door: Node3D = world.get_node("Level06/SecretDoor")
			print("door slid open: y %.2f -> %.2f (expect ~4 lower)" % [_door_y0, door.position.y])
			player.global_position = Vector3(0, 0.3, -28)
			player.velocity = Vector3.ZERO
			_step = 4
			_wait_until = Time.get_ticks_msec() + 2200
		4:
			var end := current_scene.get_node("EndScreen")
			print("after gold: end visible=%s text=%s (expect true YOU WIN)"
					% [end.visible, end.get_node("Layout/ResultLabel").text])
			print("progression test done")
			return true
	return false
