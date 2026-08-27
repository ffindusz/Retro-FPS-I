extends "res://tools/test_base.gd"
## Debug helper: full campaign progression test.
## L1: shoot switch -> teleporter activates -> step on pad -> L2 loads with
## ammo persisted. Same through L2-L6 (cavern, ice, dungeon, citadel).
## L7: kill boss -> secret door slides open -> touch the gold -> the two
## endgame portals power up -> take the monument one -> win screen.
##   Godot_v4.7-stable_win64_console.exe --headless --path . -s tools/test_progression.gd

var _ammo_before := -1
var _door_y0 := 0.0


## Clears the level, shoots its switch, and parks the player on the pad. Shared
## by L2-L6, whose progression beats are identical.
func _clear_and_teleport(level: String) -> void:
	var world := current_scene.get_node(WORLD_PATH)
	var player: CharacterBody3D = world.get_node_or_null("Player")
	var sw: Node = world.get_node("%s/Switch" % level)
	var tp: Node = world.get_node("%s/Teleporter" % level)
	sw.take_damage(5.0)
	_expect_true("%s cleared + switch shot opens the portal" % level, tp._active)
	player.global_position = tp.global_position + Vector3(0, 0.3, 0)
	player.velocity = Vector3.ZERO


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
			_expect_false("L1 locked switch leaves the portal shut", tp._active)
			_expect_greater("L1 still has live enemies",
					get_nodes_in_group("enemies").size(), 0)
			for e in get_nodes_in_group("enemies"):
				e.take_damage(99999.0)
			_step = 10
			_wait_until = Time.get_ticks_msec() + 700
		10:
			var sw: Node = world.get_node("Level01/Switch")
			var tp: Node = world.get_node("Level01/Teleporter")
			# ShootableSwitch.State.ARMED
			_expect("L1 switch arms once the level is clear", sw._state, 1)
			sw.take_damage(5.0)
			_expect_true("L1 armed switch opens the portal", tp._active)
			player.global_position = tp.global_position + Vector3(0, 0.3, 0)
			player.velocity = Vector3.ZERO
			# Departure swell (0.45s) + intermission click grace (0.5s).
			_step = 20
			_wait_until = Time.get_ticks_msec() + 1400
		20:
			var inter := current_scene.get_node("Intermission")
			_expect_true("intermission shown after the pad", inter.visible)
			_expect_true("intermission pauses the tree", paused)
			_expect("intermission stats line",
					inter.get_node("Layout/StatsLabel").text,
					"KILLS 8/8   ·   SECRETS 0/3   ·   GOLD 0/12   ·   TIME 0:01")
			_key(KEY_SPACE)
			_step = 1
			_wait_until = Time.get_ticks_msec() + 800
		1:
			var wm: Node3D = player.get_node("Head/Camera3D/WeaponManager")
			_expect_true("Level02 loaded", world.get_node_or_null("Level02") != null)
			_expect("wand ammo carried across the teleport",
					wm.current_weapon().ammo, _ammo_before)
			for e in get_nodes_in_group("enemies"):
				e.take_damage(99999.0)
			_step = 11
			_wait_until = Time.get_ticks_msec() + 700
		11:
			_clear_and_teleport("Level02")
			_step = 21
			_wait_until = Time.get_ticks_msec() + 1400
		21:
			_key(KEY_SPACE)
			_step = 30
			_wait_until = Time.get_ticks_msec() + 800
		30:
			_expect_true("Level03 (cavern) loaded",
					world.get_node_or_null("Level03") != null)
			for e in get_nodes_in_group("enemies"):
				e.take_damage(99999.0)
			_step = 31
			_wait_until = Time.get_ticks_msec() + 700
		31:
			_clear_and_teleport("Level03")
			_step = 32
			_wait_until = Time.get_ticks_msec() + 1400
		32:
			_key(KEY_SPACE)
			_step = 50
			_wait_until = Time.get_ticks_msec() + 800
		50:
			_expect_true("Level04 (ice) loaded",
					world.get_node_or_null("Level04") != null)
			for e in get_nodes_in_group("enemies"):
				e.take_damage(99999.0)
			_step = 51
			_wait_until = Time.get_ticks_msec() + 700
		51:
			_clear_and_teleport("Level04")
			_step = 52
			_wait_until = Time.get_ticks_msec() + 1400
		52:
			_key(KEY_SPACE)
			_step = 40
			_wait_until = Time.get_ticks_msec() + 800
		40:
			_expect_true("Level05 (dungeon) loaded",
					world.get_node_or_null("Level05") != null)
			_expect_true("dungeon rogue placed",
					world.get_node_or_null("Level05/Enemies/Rogue1") != null)
			for e in get_nodes_in_group("enemies"):
				e.take_damage(99999.0)
			_step = 41
			_wait_until = Time.get_ticks_msec() + 700
		41:
			_clear_and_teleport("Level05")
			_step = 42
			_wait_until = Time.get_ticks_msec() + 1400
		42:
			_key(KEY_SPACE)
			_step = 60
			_wait_until = Time.get_ticks_msec() + 800
		60:
			_expect_true("Level06 (citadel) loaded",
					world.get_node_or_null("Level06") != null)
			for e in get_nodes_in_group("enemies"):
				e.take_damage(99999.0)
			_step = 61
			_wait_until = Time.get_ticks_msec() + 700
		61:
			_clear_and_teleport("Level06")
			_step = 62
			_wait_until = Time.get_ticks_msec() + 1400
		62:
			_key(KEY_SPACE)
			_step = 2
			_wait_until = Time.get_ticks_msec() + 800
		2:
			var boss: Node = world.get_node_or_null("Level07/Enemies/Boss")
			var door: Node3D = world.get_node("Level07/SecretDoor")
			_door_y0 = door.position.y
			_expect_true("Level07 loaded", world.get_node_or_null("Level07") != null)
			_expect_true("boss placed", boss != null)
			boss.take_damage(9999.0)
			_step = 3
			_wait_until = Time.get_ticks_msec() + 3000
		3:
			var door: Node3D = world.get_node("Level07/SecretDoor")
			# SecretDoor.slide_distance is 4.0; allow slack for the tween easing.
			_expect_near("boss death slid the secret door open",
					door.position.y, _door_y0 - 4.0, 0.2)
			player.global_position = Vector3(0, 0.3, -26.8)
			player.velocity = Vector3.ZERO
			# Chest-open beat. Claiming the treasure powers the two endgame
			# portals rather than ending the run; see tools/test_loop.gd for
			# the descend half.
			_step = 5
			_wait_until = Time.get_ticks_msec() + 1400
		5:
			var end := current_scene.get_node("EndScreen")
			_expect_false("the chest alone does not end the run", end.visible)
			_expect_true("the treasure powered both portals",
					world.get_node("Level07/PadLoop")._active
					and world.get_node("Level07/PadMonument")._active)
			# Take the monument portal to finish the campaign.
			player.global_position = Vector3(2.8, 0.3, -32.4)
			player.velocity = Vector3.ZERO
			_step = 6
			_wait_until = Time.get_ticks_msec() + 2200
		6:
			_expect_true("monument portal led to the monument",
					world.get_node_or_null("LevelMonument") != null)
			_expect_false("the monument holds the end screen back",
					current_scene.get_node("EndScreen").visible)
			_key(KEY_SPACE)
			_step = 4
			_wait_until = Time.get_ticks_msec() + 400
		4:
			var end := current_scene.get_node("EndScreen")
			_expect_true("end screen shown after the monument", end.visible)
			_expect("end screen result",
					end.get_node("Layout/ResultLabel").text, "YOU WIN")
			_expect_true("credits shown",
					end.get_node("Layout/CreditsLabel").visible)
			return _finish()
	return false
