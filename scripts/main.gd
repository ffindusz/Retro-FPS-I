extends Control
## Entry point. Phase 0: verifies the low-res PS1 render pipeline by
## spinning a test cube inside the 320x240 SubViewport. Later phases
## replace the test scene with the real game and add screen routing.

@onready var _test_cube: MeshInstance3D = %TestCube


func _process(delta: float) -> void:
	if is_instance_valid(_test_cube):
		_test_cube.rotate_y(delta * 0.8)
		_test_cube.rotate_x(delta * 0.35)
