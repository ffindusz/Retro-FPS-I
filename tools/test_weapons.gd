extends SceneTree
## Debug helper: headless smoke test of the weapon system. Switches through
## all weapons, fires each once, lets a rocket fly, and reports ammo state.
##   Godot_v4.7-stable_win64_console.exe --headless --path . -s tools/test_weapons.gd

var _n := 0
var _fired := false
var _started := false


func _initialize() -> void:
	change_scene_to_file("res://scenes/main.tscn")


func _process(_delta: float) -> bool:
	if current_scene == null:
		return false
	if not _started:
		_started = true
		current_scene.start_game()
		return false
	_n += 1
	if _n < 15:
		return false
	var player: CharacterBody3D = current_scene.get_node("ViewportContainer/GameViewport/World/Player")
	var cam: Camera3D = player.get_node("Head/Camera3D")
	var wm: Node3D = cam.get_node("WeaponManager")
	if not _fired:
		_fired = true
		for i in 4:
			wm._select(i)
			var w: Node3D = wm.current_weapon()
			var ok: bool = w.try_fire(cam, player)
			print("%s fired=%s ammo=%d/%d" % [w.weapon_label, ok, w.ammo, w.max_ammo])
	# Let the rocket fly into the wall (8 m at 18 m/s) before quitting.
	if _n > 100:
		print("player health after self-splash check: %d" % root.get_node("GameState").health)
		print("weapon smoke test done")
		return true
	return false
