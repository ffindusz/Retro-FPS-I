extends SceneTree
## Debug helper: lava hazard test in the cavern (level 3). Drops the player
## into the lake and checks the burn ticks.
##   Godot_v4.7-stable_win64_console.exe --headless --path . -s tools/test_lava.gd

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
		current_scene.start_game(2)
		return false
	if Time.get_ticks_msec() < _wait_until:
		return false
	var world := current_scene.get_node("ViewportContainer/GameViewport/World")
	var player: CharacterBody3D = world.get_node_or_null("Player")
	var gs: Node = root.get_node("GameState")
	match _step:
		0:
			print("cavern totals: enemies=%d secrets=%d (expect 6 2)"
					% [gs.total_enemies, gs.total_secrets])
			player.global_position = Vector3(2, 0.1, -7)  # over the lava pit
			player.velocity = Vector3.ZERO
			_step = 1
			_wait_until = Time.get_ticks_msec() + 1500
		1:
			print("after 1.5s in lava: health=%d (expect well below 100), player y=%.2f"
					% [gs.health, player.global_position.y])
			print("lava test done")
			return true
	return false
