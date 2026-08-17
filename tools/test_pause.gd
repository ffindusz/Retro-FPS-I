extends "res://tools/test_base.gd"
## Debug helper: pause screen test.
## Esc pauses (overlay visible, tree paused, health preserved), Esc or a
## mouse click resumes, R restarts the current level (health reset), Q quits
## to the title.
##   Godot_v4.7-stable_win64_console.exe --headless --path . -s tools/test_pause.gd


func _tick(_delta: float) -> bool:
	var pause_screen := current_scene.get_node("PauseScreen")
	var gs: Node = root.get_node(GAME_STATE_PATH)
	match _step:
		0:
			gs.damage_player(30)
			_key(KEY_ESCAPE)
			_next(400)
		1:
			_expect_true("ESC pauses the tree", paused)
			_expect_true("ESC shows the pause overlay", pause_screen.visible)
			_key(KEY_ESCAPE)
			_next(400)
		2:
			_expect_false("ESC again unpauses", paused)
			_expect_false("ESC again hides the overlay", pause_screen.visible)
			_expect("health survives the pause", gs.health, 70)
			_key(KEY_ESCAPE)
			_next(400)
		3:
			_click()
			_next(400)
		4:
			_expect_false("click in pause unpauses", paused)
			_expect_false("click in pause hides the overlay", pause_screen.visible)
			_key(KEY_ESCAPE)
			_next(400)
		5:
			_key(KEY_R)
			_next(500)
		6:
			_expect_false("R in pause unpauses", paused)
			_expect_true("R in pause returns to the hud",
					current_scene.get_node("Hud").visible)
			_expect("R in pause resets health", gs.health, 100)
			_key(KEY_ESCAPE)
			_next(400)
		7:
			_key(KEY_Q)
			_next(500)
		8:
			_expect_false("Q in pause unpauses", paused)
			_expect_true("Q in pause returns to the title",
					current_scene.get_node("StartScreen").visible)
			return _finish()
	return false
