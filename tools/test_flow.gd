extends SceneTree
## Debug helper: headless test of the full game flow.
## start screen -> start_game -> player death -> lose screen -> restart ->
## boss win signal -> win screen.
##   Godot_v4.7-stable_win64_console.exe --headless --path . -s tools/test_flow.gd

var _step := 0
var _wait_ms := 0


func _initialize() -> void:
	change_scene_to_file("res://scenes/main.tscn")


func _process(_delta: float) -> bool:
	if current_scene == null:
		return false
	var main := current_scene
	var gs: Node = root.get_node("GameState")
	match _step:
		0:
			print("boot: start screen visible=%s hud=%s (expect true false)"
					% [main.get_node("StartScreen").visible, main.get_node("Hud").visible])
			main.start_game()
			_step = 1
		1:
			var player := main.get_node_or_null("ViewportContainer/GameViewport/World/Player")
			print("started: hud=%s player=%s health=%d (expect true true 100)"
					% [main.get_node("Hud").visible, player != null, gs.health])
			gs.damage_player(150)
			_step = 2
		2:
			var end := main.get_node("EndScreen")
			print("after death: end visible=%s text=%s (expect true YOU DIED)"
					% [end.visible, end.get_node("Layout/ResultLabel").text])
			main.start_game()
			_step = 3
		3:
			var player := main.get_node_or_null("ViewportContainer/GameViewport/World/Player")
			print("restarted: hud=%s player=%s health=%d (expect true true 100)"
					% [main.get_node("Hud").visible, player != null, gs.health])
			gs.boss_defeated()
			_wait_ms = Time.get_ticks_msec() + 1600
			_step = 4
		4:
			if Time.get_ticks_msec() >= _wait_ms:
				var end := main.get_node("EndScreen")
				print("after win: end visible=%s text=%s (expect true YOU WIN)"
						% [end.visible, end.get_node("Layout/ResultLabel").text])
				print("flow test done")
				return true
	return false
