extends SceneTree
## Debug helper: headless boss fight test. Teleports the player into the
## arena, verifies the boss notices/attacks with fireballs (player health
## drops from range), triggers the 50% phase change, kills the boss, and
## confirms the GameState.boss_died signal fires.
##   Godot_v4.7-stable_win64_console.exe --headless --path . -s tools/test_boss.gd

var _placed := false
var _start_ms := 0
var _phase2_done := false
var _killed := false
var _win_signaled := false
var _reported := {}


func _initialize() -> void:
	change_scene_to_file("res://scenes/main.tscn")


func _report_once(key: String, msg: String) -> void:
	if not _reported.has(key):
		_reported[key] = true
		print(msg)


var _started := false


func _process(_delta: float) -> bool:
	if current_scene == null:
		return false
	if not _started:
		_started = true
		current_scene.start_game(2)  # boss lives in level 3 now
		return false
	var world := current_scene.get_node("ViewportContainer/GameViewport/World")
	var player: CharacterBody3D = world.get_node_or_null("Player")
	var boss: CharacterBody3D = world.get_node_or_null("Level03/Enemies/Boss")
	var gs: Node = root.get_node("GameState")
	if not _placed:
		if player == null:
			return false
		_placed = true
		_start_ms = Time.get_ticks_msec()
		gs.boss_died.connect(func() -> void: _win_signaled = true)
		player.global_position = Vector3(0, 0.1, -4)
		player.velocity = Vector3.ZERO
		print("t=0.0s boss state=%d health=%.0f" % [boss.state, boss.health])
		return false
	var t := (Time.get_ticks_msec() - _start_ms) / 1000.0
	if t > 2.0 and boss and player and not _killed:
		_report_once("t1", "t=2.0s boss state=%d (expect 2-3) dist=%.1f" % [boss.state,
				boss.global_position.distance_to(player.global_position)])
	if t > 6.0 and boss and not _phase2_done:
		_phase2_done = true
		print("t=6.0s boss state=%d player health=%d (expect <100 from fireballs)"
				% [boss.state, gs.health])
		# Heal so the stationary test player can't die before the boss does.
		gs.health = 100
		boss.take_damage(210.0)
		print("after 210 dmg: health=%.0f enraged=%s (expect true)" % [boss.health, boss._enraged])
	if t > 8.0 and not _killed:
		_killed = true
		boss.take_damage(500.0)
		print("after kill: state=%d (expect 4 DEAD)" % boss.state)
	if t > 10.5:
		print("boss freed: %s, win signal fired: %s (expect true true)"
				% [str(not is_instance_valid(boss)), str(_win_signaled)])
		print("boss test done")
		return true
	return false
