extends "res://tools/test_base.gd"
## Verifies the player walks up a small step but is still stopped by a full
## wall. Builds a bare floor with a low deep platform in one lane and a tall
## wall in another, drives the player forward into each, and checks the result.
## Run headless (physics runs; wall-clock waits):
##   Godot_v4.7-stable_win64_console.exe --headless --path . -s tools/test_step.gd

const STEP_Y := 0.3        ## Low platform -- should be climbed onto.
const WALL_Y := 1.2        ## Tall wall -- should still block.

var _world: Node3D
var _player: CharacterBody3D
var _phase := 0
var _t0 := 0


func _initialize() -> void:
	_world = Node3D.new()
	root.add_child(_world)
	_add_box(Vector3(10, -0.5, -10), Vector3(80, 1, 80))            # floor, top y=0
	# Lane A (x~0): a deep low platform the player should climb and stay on.
	_add_box(Vector3(0, STEP_Y * 0.5, -20), Vector3(8, STEP_Y, 40)) # z in [-40, 0]
	# Lane B (x~20): a tall wall the player should not climb.
	_add_box(Vector3(20, WALL_Y * 0.5, -5), Vector3(8, WALL_Y, 4))  # z in [-7, -3]
	_player = load("res://scenes/player/player.tscn").instantiate()
	_world.add_child(_player)
	_reset_player(Vector3(0, 1.0, 2))


## Uses local position, not global: during _initialize() even SceneTree.root
## is not inside the tree yet, so get_global_transform() errors out and
## returns identity. _world never moves, so local == global here anyway.
func _reset_player(pos: Vector3) -> void:
	_player.position = pos
	_player.rotation.y = 0.0  # faces -Z (forward)
	_player.velocity = Vector3.ZERO


func _add_box(pos: Vector3, box_size: Vector3) -> void:
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box_size
	col.shape = shape
	body.add_child(col)
	_world.add_child(body)
	body.position = pos  # local, see _reset_player


func _process(_delta: float) -> bool:
	var t := Time.get_ticks_msec() - _t0
	match _phase:
		0:  # let the player settle onto the floor
			if _t0 == 0:
				_t0 = Time.get_ticks_msec()
			elif t > 400:
				Input.action_press("move_forward")
				_phase = 1
				_t0 = Time.get_ticks_msec()
		1:  # walk onto the low platform for ~1.2 s, ending on top of it
			if t > 1200:
				Input.action_release("move_forward")
				var p := _player.global_position
				_expect_greater("low step climbed (y)", p.y, 0.2)
				_expect_less("low step walked onto (z)", p.z, -1.0)
				_reset_player(Vector3(20, 1.0, 2))
				Input.action_press("move_forward")
				_phase = 2
				_t0 = Time.get_ticks_msec()
		2:  # walk into the tall wall for ~1.5 s -- must be stopped in front of it
			if t > 1500:
				Input.action_release("move_forward")
				var p := _player.global_position
				_expect_less("tall wall not climbed (y)", p.y, 0.5)
				_expect_greater("tall wall blocked the advance (z)", p.z, -3.6)
				return _finish()
	return false
