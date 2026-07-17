extends "res://tools/test_base.gd"
## Debug helper: level-select cheat test. Presses 3 on the title screen
## (expect level 3 loads), warps with F5 and F1 during play, then quits to
## the title and presses 0 (expect the model test stage).
##   Godot_v4.7-stable_win64_console.exe --headless --path . -s tools/test_cheat.gd


func _skip_auto_start() -> bool:
	return true


func _level_name() -> String:
	var world := current_scene.get_node(WORLD_PATH)
	for child in world.get_children():
		if String(child.name).begins_with("Level") and not String(child.name).ends_with("_dying"):
			return String(child.name)
	return "(none)"


func _tick(_delta: float) -> bool:
	match _step:
		0:
			_key(KEY_3)  # on the title screen
			_next(500)
		1:
			print("after pressing 3 on title: %s (expect Level03)" % _level_name())
			_key(KEY_F5)
			_next(500)
		2:
			print("after F5 in game: %s (expect Level05)" % _level_name())
			_key(KEY_F1)
			_next(500)
		3:
			print("after F1 in game: %s (expect Level01)" % _level_name())
			_key(KEY_ESCAPE)  # pause...
			_next(400)
		4:
			_key(KEY_Q)  # ...quit to the title
			_next(500)
		5:
			_key(KEY_0)  # test stage from the title
			_next(500)
		6:
			print("after pressing 0 on title: %s (expect LevelTest)" % _level_name())
			print("cheat test done")
			return true
	return false
