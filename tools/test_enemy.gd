extends SceneTree
## Debug helper: headless grunt AI test. Teleports the player in front of a
## grunt, watches the FSM advance (0 IDLE, 1 NOTICE, 2 CHASE, 3 ATTACK,
## 4 DEAD), confirms the player takes melee damage, then kills the grunt.
## Waits are wall-clock based because headless runs uncapped.
##   Godot_v4.7-stable_win64_console.exe --headless --path . -s tools/test_enemy.gd

var _placed := false
var _start_ms := 0
var _killed := false
var _reported := {}


func _initialize() -> void:
	change_scene_to_file("res://scenes/main.tscn")


func _report_once(key: String, msg: String) -> void:
	if _reported.has(key):
		return
	_reported[key] = true
	print(msg)


func _process(_delta: float) -> bool:
	if current_scene == null:
		return false
	var world := current_scene.get_node("ViewportContainer/GameViewport/World")
	var player: CharacterBody3D = world.get_node("Player")
	var grunt: CharacterBody3D = world.get_node_or_null("Level01/Enemies/Grunt3")
	if not _placed:
		_placed = true
		_start_ms = Time.get_ticks_msec()
		player.global_position = Vector3(19, 0.1, 2)
		player.velocity = Vector3.ZERO
		print("t=0.0s grunt state=%d (expect 0 IDLE)" % grunt.state)
		return false
	var t := (Time.get_ticks_msec() - _start_ms) / 1000.0
	if t > 0.8 and grunt and not _killed:
		_report_once("t1", "t=0.8s grunt state=%d (expect 1-2 NOTICE/CHASE)" % grunt.state)
	if t > 2.5 and grunt and not _killed:
		_report_once("t2", "t=2.5s grunt state=%d dist=%.2f" % [grunt.state,
				grunt.global_position.distance_to(player.global_position)])
	if t > 5.0 and not _killed:
		_killed = true
		print("t=5.0s grunt state=%d (expect 3 ATTACK) player health=%d (expect <100)"
				% [grunt.state, root.get_node("GameState").health])
		grunt.take_damage(100.0)
		print("after 100 dmg: state=%d (expect 4 DEAD)" % grunt.state)
	if t > 7.5:
		print("grunt freed after death: %s (expect true)" % str(not is_instance_valid(grunt)))
		print("enemy test done")
		return true
	return false
