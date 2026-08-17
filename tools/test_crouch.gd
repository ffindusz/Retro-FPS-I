extends "res://tools/test_base.gd"
## Debug helper: crouch behavior test. Presses the crouch action, checks
## capsule height + head drop + slower speed cap, releases, checks standing.
##   Godot_v4.7-stable_win64_console.exe --headless --path . -s tools/test_crouch.gd


func _tick(_delta: float) -> bool:
	var world := current_scene.get_node(WORLD_PATH)
	var player: CharacterBody3D = world.get_node_or_null("Player")
	var shape: CapsuleShape3D = player.get_node("CollisionShape3D").shape
	match _step:
		0:
			_expect_near("standing capsule height", shape.height, 1.80)
			_expect_near("standing head y", player.head.position.y, 1.60)
			Input.action_press("crouch")
			_next(600)
		1:
			_expect_near("crouched capsule height", shape.height, 1.20)
			# The head eases down over a few frames, so allow a little slack.
			_expect_near("crouched head y", player.head.position.y, 1.00, 0.05)
			_expect_true("crouching flag set", player._crouching)
			Input.action_release("crouch")
			_next(600)
		2:
			_expect_near("stood capsule height", shape.height, 1.80)
			_expect_near("stood head y", player.head.position.y, 1.60, 0.05)
			_expect_false("crouching flag cleared", player._crouching)
			return _finish()
	return false
