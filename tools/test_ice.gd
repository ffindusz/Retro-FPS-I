extends SceneTree
## Debug helper: ice level test. Verifies totals, that standing on the
## frozen lake enables slide physics (ice zone counter), and that the
## freezing pool damages the player.
##   Godot_v4.7-stable_win64_console.exe --headless --path . -s tools/test_ice.gd

var _started := false
var _step := 0
var _wait_until := 0


func _initialize() -> void:
	change_scene_to_file("res://scenes/main.tscn")


func _process(_delta: float) -> bool:
	if current_scene == null:
		return false
	if not _started:
		_started = true
		current_scene.start_game(3)
		return false
	if Time.get_ticks_msec() < _wait_until:
		return false
	var world := current_scene.get_node("ViewportContainer/GameViewport/World")
	var player: CharacterBody3D = world.get_node_or_null("Player")
	var gs: Node = root.get_node("GameState")
	match _step:
		0:
			print("ice level totals: enemies=%d secrets=%d (expect 6 2)"
					% [gs.total_enemies, gs.total_secrets])
			print("at spawn: ice zones=%d (expect 0)" % player._ice_zones)
			gs.health = 100000  # nearby grunts shouldn't end the test
			player.global_position = Vector3(0, 0.3, -3)  # onto the frozen lake
			player.velocity = Vector3.ZERO
			_step = 1
			_wait_until = Time.get_ticks_msec() + 600
		1:
			print("on lake: ice zones=%d (expect 1)" % player._ice_zones)
			gs.health = 100
			player.global_position = Vector3(5.5, 0.3, -9)  # into the freezing pool
			player.velocity = Vector3.ZERO
			_step = 2
			_wait_until = Time.get_ticks_msec() + 1600
		2:
			print("after 1.6s in freezing water: health=%d (expect <100)" % gs.health)
			print("ice test done")
			return true
	return false
