extends "res://tools/test_base.gd"
## Debug helper: headless grunt AI test. Teleports the player in front of a
## grunt, watches the FSM advance (0 IDLE, 1 NOTICE, 2 CHASE, 3 ATTACK,
## 4 DEAD), confirms the player takes melee damage, then kills the grunt.
## Waits are wall-clock based because headless runs uncapped.
##   Godot_v4.7-stable_win64_console.exe --headless --path . -s tools/test_enemy.gd

var _placed := false
var _start_ms := 0
var _killed := false


func _tick(_delta: float) -> bool:
	var world := current_scene.get_node(WORLD_PATH)
	var player: CharacterBody3D = world.get_node("Player")
	var grunt: CharacterBody3D = world.get_node_or_null("Level01/Enemies/Grunt3")
	if not _placed:
		_placed = true
		_start_ms = Time.get_ticks_msec()
		player.global_position = Vector3(19, 0.1, 2)
		player.velocity = Vector3.ZERO
		_expect("t=0.0s grunt dormant", grunt.state, STATE_IDLE)
		return false
	var t := (Time.get_ticks_msec() - _start_ms) / 1000.0
	if t > 0.8 and grunt and not _killed and not _reported.has("t1"):
		_reported["t1"] = true
		# Either side of the notice_delay hand-off is fine this early.
		_expect_between("t=0.8s grunt noticed", grunt.state, STATE_NOTICE, STATE_CHASE)
	if t > 5.0 and not _killed:
		_killed = true
		_expect("t=5.0s grunt attacking", grunt.state, STATE_ATTACK)
		_expect_less("player took melee damage",
				root.get_node(GAME_STATE_PATH).health, 100)
		grunt.take_damage(100.0)
		_expect("grunt dead after 100 dmg", grunt.state, STATE_DEAD)
	if t > 7.5:
		_expect_true("grunt freed after death", not is_instance_valid(grunt))
		return _finish()
	return false
