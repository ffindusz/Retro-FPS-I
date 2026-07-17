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
			print("boot: start screen visible=%s hud=%s (expect true false)"
					% [main.get_node("StartScreen").visible, main.get_node("Hud").visible])
			# Start with a real mouse click so the full input pipeline is
			# exercised (regression: the SubViewportContainer used to consume
			# clicks before they reached the start screen). The button stays
			# held into the next step to prove the confirming click cannot
			# double as a fire input (fire is polled, not event-driven).
			_mouse_button(true)
			_next(300)
		1:
			var player := main.get_node_or_null(WORLD_PATH + "/Player")
			print("started by click: hud=%s player=%s health=%d (expect true true 100)"
					% [main.get_node("Hud").visible, player != null, gs.health])
			print("fire action while click still held: %s (expect false)"
					% Input.is_action_pressed("fire"))
			_mouse_button(false)
			gs.damage_player(150)
			_next(300)
		2:
			var end := main.get_node("EndScreen")
			print("after death: end visible=%s text=%s (expect true YOU DIED)"
					% [end.visible, end.get_node("Layout/ResultLabel").text])
			main.start_game()
			_next(300)
		3:
			var player := main.get_node_or_null(WORLD_PATH + "/Player")
			print("restarted: hud=%s player=%s health=%d (expect true true 100)"
					% [main.get_node("Hud").visible, player != null, gs.health])
			gs.win_game()
			_next(1600)
		4:
			var end := main.get_node("EndScreen")
			print("after win: end visible=%s text=%s (expect true YOU WIN)"
					% [end.visible, end.get_node("Layout/ResultLabel").text])
			print("flow test done")
			return true
	return false
