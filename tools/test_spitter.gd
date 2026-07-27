extends "res://tools/test_base.gd"
## Debug helper: headless spitter AI test. Boots level 3 (the magic skeletons'
## debut) and relocates a cavern spitter + the player into the open entry room,
## then verifies it: notices, enters ATTACK (state 3), BACKPEDALS (distance
## grows), spits plasma that damages the player, and dies. The player is kept
## topped up so a long pummel can't end the run and free the spitter mid-test.
##   Godot_v4.7-stable_win64_console.exe --headless --path . -s tools/test_spitter.gd

var _placed := false
var _start_ms := 0
var _dist0 := 0.0
var _max_dist := 0.0
var _took_damage := false
var _killed := false


func _boot_level_index() -> int:
	return 2  # level 3


func _tick(_delta: float) -> bool:
	var world := current_scene.get_node(WORLD_PATH)
	var player: CharacterBody3D = world.get_node_or_null("Player")
	var spitter: CharacterBody3D = world.get_node_or_null("Level03/Enemies/Spitter1")
	var gs: Node = root.get_node(GAME_STATE_PATH)
	if not _placed:
		if player == null or spitter == null:
			return false
		_placed = true
		_start_ms = Time.get_ticks_msec()
		# Open entry room; player just north of the spitter so it backpedals
		# south into the passage rather than into a wall.
		spitter.global_position = Vector3(0, 0.1, 12)
		player.global_position = Vector3(0, 0.1, 15)
		player.velocity = Vector3.ZERO
		_dist0 = spitter.global_position.distance_to(player.global_position)
		print("t=0.0s spitter state=%d dist=%.2f (expect 0 IDLE, ~3.0)" % [spitter.state, _dist0])
		return false
	if is_instance_valid(spitter):
		_max_dist = maxf(_max_dist, spitter.global_position.distance_to(player.global_position))
	# Keep the player alive: note the plasma hit, then top health back up so a
	# freed level can't null the spitter before the kill check.
	if gs.health < 100:
		_took_damage = true
		gs.health = 100
	var t := (Time.get_ticks_msec() - _start_ms) / 1000.0
	if t > 3.0 and spitter and not _killed:
		_report_once("t1", "t=3.0s state=%d max_dist=%.2f (expect 3 ATTACK, max_dist > %.2f = backpedaled)"
				% [spitter.state, _max_dist, _dist0])
	if t > 6.0 and not _killed:
		_killed = true
		print("plasma hit the player: %s (expect true)" % _took_damage)
		spitter.take_damage(50.0)
		print("after 50 dmg: state=%d (expect 4 DEAD)" % spitter.state)
	if t > 8.5:
		print("spitter freed: %s (expect true)" % str(not is_instance_valid(spitter)))
		print("spitter test done")
		return true
	return false
