extends SceneTree
## Debug helper: raycast-probes the level's CSG collision to verify the
## geometry actually built as designed. Headless-safe:
##   Godot_v4.7-stable_win64_console.exe --headless --path . -s tools/probe_level.gd

var _n := 0


func _initialize() -> void:
	var lvl: Node3D = (load("res://scenes/levels/level_01.tscn") as PackedScene).instantiate()
	root.add_child(lvl)
	physics_frame.connect(_probe)


func _probe() -> void:
	_n += 1
	if _n < 5:
		return
	var space := root.get_world_3d().direct_space_state
	var tests := {
		"roomA floor (0,1,20) down": [Vector3(0, 1, 20), Vector3(0, -2, 20)],
		"roomA ceiling (0,2,20) up": [Vector3(0, 2, 20), Vector3(0, 20, 20)],
		"roomB ceiling (0,2,0) up": [Vector3(0, 2, 0), Vector3(0, 20, 0)],
		"corr2 ceiling (12,1.5,0) up": [Vector3(12, 1.5, 0), Vector3(12, 20, 0)],
		"walkway floor (12,4.5,0) down": [Vector3(12, 4.5, 0), Vector3(12, -1, 0)],
		"walkway ceiling (12,4.5,0) up": [Vector3(12, 4.5, 0), Vector3(12, 20, 0)],
		"walkway north wall (12,4.5,0) to +z": [Vector3(12, 4.5, 0), Vector3(12, 4.5, 10)],
		"landing (17.5,4,-2.3) down": [Vector3(17.5, 4, -2.3), Vector3(17.5, 0, -2.3)],
		"balcony (7,4,0) down": [Vector3(7, 4, 0), Vector3(7, 0, 0)],
		"ramp mid (22.4,4,-4.5) down": [Vector3(22.4, 4, -4.5), Vector3(22.4, 0, -4.5)],
		"arena open top (0,5,-24) up": [Vector3(0, 5, -24), Vector3(0, 40, -24)],
		"arena floor (0,5,-24) down": [Vector3(0, 5, -24), Vector3(0, -2, -24)],
	}
	for test_name: String in tests:
		var q := PhysicsRayQueryParameters3D.create(tests[test_name][0], tests[test_name][1])
		var hit := space.intersect_ray(q)
		if hit:
			print("%s -> hit at %.3v" % [test_name, hit.position])
		else:
			print("%s -> NO HIT" % test_name)
	quit()
