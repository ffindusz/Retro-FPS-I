extends SceneTree
## Debug helper: sky citadel void test. Verifies totals, then walks the
## player off a platform edge — the kill zone should end the run.
##   Godot_v4.7-stable_win64_console.exe --headless --path . -s tools/test_void.gd

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
			print("citadel totals: enemies=%d secrets=%d (expect 6 2)"
					% [gs.total_enemies, gs.total_secrets])
			# Step off the spawn platform into the void.
			player.global_position = Vector3(9, 0.1, 20)
			player.velocity = Vector3.ZERO
			_step = 1
			_wait_until = Time.get_ticks_msec() + 2500
		1:
			var end := current_scene.get_node("EndScreen")
			print("after void fall: end visible=%s text=%s (expect true YOU DIED)"
					% [end.visible, end.get_node("Layout/ResultLabel").text])
			print("void test done")
			return true
	return false
