extends SceneTree
## Debug helper: captures the start screen, in-game HUD, and lose screen.
## Run WITHOUT --headless:
##   Godot_v4.7-stable_win64_console.exe --path . -s tools/screenshot_ui.gd

var _frames := 0


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://tmp_shots")
	change_scene_to_file("res://scenes/main.tscn")


func _shot(file_name: String) -> void:
	root.get_texture().get_image().save_png("res://tmp_shots/" + file_name)


func _process(_delta: float) -> bool:
	if current_scene == null:
		return false
	_frames += 1
	if _frames == 20:
		_shot("ui_start.png")
		current_scene.start_game()
	elif _frames == 60:
		_shot("ui_hud.png")
		root.get_node("GameState").damage_player(30)
	elif _frames == 70:
		_shot("ui_hud_damage.png")
		root.get_node("GameState").damage_player(150)
	elif _frames == 100:
		_shot("ui_end_lose.png")
		return true
	return false
