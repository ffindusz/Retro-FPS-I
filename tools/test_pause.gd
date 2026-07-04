extends SceneTree
## Debug helper: pause screen test.
## Esc pauses (overlay visible, tree paused, health preserved), Esc resumes,
## R restarts the current level (health reset), Q quits to the title.
##   Godot_v4.7-stable_win64_console.exe --headless --path . -s tools/test_pause.gd

var _started := false
var _step := 0
var _wait_until := 0


func _initialize() -> void:
	change_scene_to_file("res://scenes/main.tscn")


func _key(code: Key) -> void:
	var press := InputEventKey.new()
	press.keycode = code
	press.physical_keycode = code
	press.pressed = true
	Input.parse_input_event(press)
	var release := InputEventKey.new()
	release.keycode = code
	release.physical_keycode = code
	release.pressed = false
	Input.parse_input_event(release)


func _process(_delta: float) -> bool:
	if current_scene == null:
		return false
	if not _started:
		_started = true
		current_scene.start_game()
		return false
	if Time.get_ticks_msec() < _wait_until:
		return false
	var pause_screen := current_scene.get_node("PauseScreen")
	var gs: Node = root.get_node("GameState")
	match _step:
		0:
			gs.damage_player(30)
			_key(KEY_ESCAPE)
			_next(400)
		1:
			print("after ESC: paused=%s overlay=%s (expect true true)"
					% [paused, pause_screen.visible])
			_key(KEY_ESCAPE)
			_next(400)
		2:
			print("after ESC again: paused=%s overlay=%s health=%d (expect false false 70)"
					% [paused, pause_screen.visible, gs.health])
			_key(KEY_ESCAPE)
			_next(400)
		3:
			_key(KEY_R)
			_next(500)
		4:
			print("after R in pause: paused=%s hud=%s health=%d (expect false true 100)"
					% [paused, current_scene.get_node("Hud").visible, gs.health])
			_key(KEY_ESCAPE)
			_next(400)
		5:
			_key(KEY_Q)
			_next(500)
		6:
			print("after Q in pause: paused=%s start screen=%s (expect false true)"
					% [paused, current_scene.get_node("StartScreen").visible])
			print("pause test done")
			return true
	return false


func _next(wait_ms: int) -> void:
	_step += 1
	_wait_until = Time.get_ticks_msec() + wait_ms
