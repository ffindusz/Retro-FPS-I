extends "res://tools/test_base.gd"
## Debug helper: headless spitter AI test. Boots level 3 (the magic skeletons'
## debut) and relocates a cavern spitter + the player into the open entry room,
## then verifies it: notices, enters ATTACK (state 3), BACKPEDALS (distance
## grows), spits arcane bolts that damage the player, and dies. The player is kept
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
		_expect("t=0.0s spitter dormant", spitter.state, STATE_IDLE)
		_expect_near("t=0.0s spitter distance", _dist0, 3.0, 0.1)
		return false
	if is_instance_valid(spitter):
		_max_dist = maxf(_max_dist, spitter.global_position.distance_to(player.global_position))
	# Keep the player alive: note the bolt hit, then top health back up so a
	# freed level can't null the spitter before the kill check.
	if gs.health < 100:
		_took_damage = true
		gs.health = 100
	var t := (Time.get_ticks_msec() - _start_ms) / 1000.0
	if t > 3.0 and spitter and not _killed and not _reported.has("t1"):
		_reported["t1"] = true
		_expect("t=3.0s spitter attacking", spitter.state, STATE_ATTACK)
		_expect_greater("spitter backpedaled", _max_dist, _dist0)
	if t > 6.0 and not _killed:
		_killed = true
		_expect_true("spitter bolt hit the player", _took_damage)
		spitter.take_damage(50.0)
		_expect("spitter dead after 50 dmg", spitter.state, STATE_DEAD)
	if t > 8.5:
		_expect_true("spitter freed after death", not is_instance_valid(spitter))
		return _finish()
	return false
