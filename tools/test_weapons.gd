extends "res://tools/test_base.gd"
## Debug helper: headless smoke test of the weapon system. Switches through
## all weapons, fires each once, lets a staff fireball fly, and checks ammo state.
##   Godot_v4.7-stable_win64_console.exe --headless --path . -s tools/test_weapons.gd

var _n := 0
var _fired := false


func _tick(_delta: float) -> bool:
	_n += 1
	if _n < 15:
		return false
	var player: CharacterBody3D = current_scene.get_node(WORLD_PATH + "/Player")
	var cam: Camera3D = player.get_node("Head/Camera3D")
	var wm: Node3D = cam.get_node("WeaponManager")
	if not _fired:
		_fired = true
		for i in 4:
			wm._select(i)
			var w: Node3D = wm.current_weapon()
			var ok: bool = w.try_fire(cam, player)
			_expect_true("%s fired" % w.weapon_label, ok)
			_expect("%s spent one shot" % w.weapon_label, w.ammo, w.max_ammo - 1)
	# Let the staff fireball fly into the wall (8 m at 18 m/s) before quitting.
	if _n > 100:
		# Fired straight ahead into a distant wall, so the splash must not
		# reach back to the shooter.
		_expect("no self-splash from the staff fireball",
				root.get_node(GAME_STATE_PATH).health, 100)
		return _finish()
	return false
