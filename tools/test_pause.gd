extends "res://tools/test_base.gd"
## Debug helper: pause screen test.
## Esc pauses (overlay visible, tree paused, health preserved), Esc resumes,
## R restarts the current level (health reset), Q quits to the title.
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
