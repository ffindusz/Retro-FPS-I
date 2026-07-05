extends SceneTree
## Debug helper: level-select cheat test. Presses 3 on the title screen
## (expect level 3 loads), then warps with F5 and F1 during play.
##   Godot_v4.7-stable_win64_console.exe --headless --path . -s tools/test_cheat.gd

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


func _level_name() -> String:
	var world := current_scene.get_node("ViewportContainer/GameViewport/World")
	for child in world.get_children():
		if String(child.name).begins_with("Level") and not String(child.name).ends_with("_dying"):
			return String(child.name)
	return "(none)"


func _process(_delta: float) -> bool:
	if current_scene == null:
		return false
	if Time.get_ticks_msec() < _wait_until:
		return false
	match _step:
		0:
			_key(KEY_3)  # on the title screen
			_step = 1
			_wait_until = Time.get_ticks_msec() + 500
		1:
			print("after pressing 3 on title: %s (expect Level03)" % _level_name())
			_key(KEY_F5)
			_step = 2
			_wait_until = Time.get_ticks_msec() + 500
		2:
			print("after F5 in game: %s (expect Level05)" % _level_name())
			_key(KEY_F1)
			_step = 3
			_wait_until = Time.get_ticks_msec() + 500
		3:
			print("after F1 in game: %s (expect Level01)" % _level_name())
			print("cheat test done")
			return true
	return false
