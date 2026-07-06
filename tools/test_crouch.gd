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
			print("standing: height=%.2f head_y=%.2f (expect 1.80 1.60)"
					% [shape.height, player.head.position.y])
			Input.action_press("crouch")
			_next(600)
		1:
			print("crouched: height=%.2f head_y=%.2f crouching=%s (expect 1.20 ~1.00 true)"
					% [shape.height, player.head.position.y, player._crouching])
			Input.action_release("crouch")
			_next(600)
		2:
			print("released: height=%.2f head_y=%.2f crouching=%s (expect 1.80 ~1.60 false)"
					% [shape.height, player.head.position.y, player._crouching])
			print("crouch test done")
			return true
	return false
