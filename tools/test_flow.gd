extends "res://tools/test_base.gd"
## Debug helper: headless test of the full game flow.
## start screen -> mouse click starts the game -> player death -> lose
## screen -> restart -> boss win signal -> win screen.
##   Godot_v4.7-stable_win64_console.exe --headless --path . -s tools/test_flow.gd


func _skip_auto_start() -> bool:
	return true


func _tick(_delta: float) -> bool:
	var main := current_scene
	var gs: Node = root.get_node(GAME_STATE_PATH)
	match _step:
		0:
			_expect_true("boot: start screen visible",
					main.get_node("StartScreen").visible)
			_expect_false("boot: hud hidden", main.get_node("Hud").visible)
			# Start with a real mouse click so the full input pipeline is
			# exercised (regression: the SubViewportContainer used to consume
			# clicks before they reached the start screen). The button stays
			# held into the next step to prove the confirming click cannot
			# double as a fire input (fire is polled, not event-driven).
			_mouse_button(true)
			_next(300)
		1:
			var player := main.get_node_or_null(WORLD_PATH + "/Player")
			_expect_true("started by click: hud shown", main.get_node("Hud").visible)
			_expect_true("started by click: player spawned", player != null)
			_expect("started by click: full health", gs.health, 100)
			_expect_false("confirming click is not a fire input",
					Input.is_action_pressed("fire"))
			_mouse_button(false)
			gs.damage_player(150)
			_next(300)
		2:
			var end := main.get_node("EndScreen")
			_expect_true("after death: end screen shown", end.visible)
			_expect("after death: result text",
					end.get_node("Layout/ResultLabel").text, "YOU DIED")
			main.start_game()
			_next(300)
		3:
			var player := main.get_node_or_null(WORLD_PATH + "/Player")
			_expect_true("restarted: hud shown", main.get_node("Hud").visible)
			_expect_true("restarted: player respawned", player != null)
			_expect("restarted: health reset", gs.health, 100)
			gs.win_game()
			# The win now lingers on the treasure until a confirm; wait out
			# the grace, then check the screen hasn't shown on its own.
			_next(1400)
		4:
			var end := main.get_node("EndScreen")
			_expect_false("savor beat holds the end screen back", end.visible)
			_key(KEY_SPACE)
			_next(400)
		5:
			var end := main.get_node("EndScreen")
			_expect_true("after win confirm: end screen shown", end.visible)
			_expect("after win confirm: result text",
					end.get_node("Layout/ResultLabel").text, "YOU WIN")
			_expect_true("after win confirm: credits shown",
					end.get_node("Layout/CreditsLabel").visible)
			return _finish()
	return false
