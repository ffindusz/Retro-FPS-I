extends SceneTree
## Debug helper: headless spitter AI test. Places the player close to the
## ramp-room spitter and verifies it: notices, enters ATTACK (state 3),
## BACKPEDALS (distance grows), damages the player with plasma from range,
## and dies.
##   Godot_v4.7-stable_win64_console.exe --headless --path . -s tools/test_spitter.gd

var _started := false
var _placed := false
var _start_ms := 0
var _dist0 := 0.0
var _killed := false
var _reported := {}


func _initialize() -> void:
	change_scene_to_file("res://scenes/main.tscn")


func _report_once(key: String, msg: String) -> void:
	if not _reported.has(key):
		_reported[key] = true
		print(msg)


func _process(_delta: float) -> bool:
	if current_scene == null:
		return false
	if not _started:
		_started = true
		current_scene.start_game()
		return false
	var world := current_scene.get_node("ViewportContainer/GameViewport/World")
	var player: CharacterBody3D = world.get_node_or_null("Player")
	var spitter: CharacterBody3D = world.get_node_or_null("Level01/Enemies/Spitter2")
	var gs: Node = root.get_node("GameState")
	if not _placed:
		if player == null:
			return false
		_placed = true
		_start_ms = Time.get_ticks_msec()
		player.global_position = Vector3(22, 0.1, 3)
		player.velocity = Vector3.ZERO
		_dist0 = spitter.global_position.distance_to(player.global_position)
		print("t=0.0s spitter state=%d dist=%.2f (expect 0 IDLE, ~3.5)" % [spitter.state, _dist0])
		return false
	var t := (Time.get_ticks_msec() - _start_ms) / 1000.0
	if t > 2.5 and spitter and not _killed:
		_report_once("t1", "t=2.5s state=%d dist=%.2f (expect 3 ATTACK, dist > %.2f = backpedaled)"
				% [spitter.state, spitter.global_position.distance_to(player.global_position), _dist0])
	if t > 6.0 and not _killed:
		_killed = true
		print("t=6.0s player health=%d (expect <100 from plasma)" % gs.health)
		gs.health = 100
		spitter.take_damage(50.0)
		print("after 50 dmg: state=%d (expect 4 DEAD)" % spitter.state)
	if t > 8.5:
		print("spitter freed: %s (expect true)" % str(not is_instance_valid(spitter)))
		print("spitter test done")
		return true
	return false
