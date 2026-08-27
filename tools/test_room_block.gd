extends "res://tools/test_base.gd"
## Verifies scenes/level_blocks/room_block.tscn actually builds a hollow,
## solid room, and rebuilds it when resized.
##
## Raycasts rather than node counts, because the point of the block is the
## geometry it produces: the walls have to be where room_size says, the
## interior has to be empty, and the floor slab has to sit at the lip height
## the hand-built levels use. It is nested inside a CSGCombiner3D with
## use_collision, exactly as it would be inside a level's LevelCSG.
##
## Run headless (physics runs; CSG needs a few frames to build):
##   Godot_v4.7-stable_win64_console.exe --headless --path . -s tools/test_room_block.gd

const ROOM := preload("res://scenes/level_blocks/room_block.tscn")
const SIZE := Vector3(12.0, 6.0, 12.0)
const RESIZED_X := 20.0
const FLOOR_LIP := 0.05
const TOLERANCE := 0.06

var _level: CSGCombiner3D
var _room: Node3D
var _frames := 0
var _phase := 0


## Overrides the harness boot: this test builds its own CSG world rather than
## loading main.tscn, and drives itself off physics_frame because CSG rebuilds
## and their collision shapes land on physics steps, not idle frames.
func _initialize() -> void:
	_snapshot_save()  # this test does not call super(); protect the save anyway
	_level = CSGCombiner3D.new()
	_level.use_collision = true
	root.add_child(_level)
	_room = ROOM.instantiate()
	_level.add_child(_room)
	_room.room_size = SIZE
	# Not named _step: the harness already has a _step counter member, and a
	# method may not share a name with an inherited variable.
	physics_frame.connect(_on_physics_frame)


func _on_physics_frame() -> void:
	_frames += 1
	# CSG rebuilds are deferred, and the collision shape follows a frame later.
	if _frames < 12:
		return
	match _phase:
		0:
			_check_built()
			_phase = 1
			_frames = 0
			# The feature under test: changing a property re-shapes the room.
			_room.room_size = Vector3(RESIZED_X, SIZE.y, SIZE.z)
		1:
			_check_resized()
			_finish()


func _check_built() -> void:
	# Generated brushes must exist at runtime but stay out of the saved scene,
	# which is what having no owner means.
	var owned := 0
	for child in _room.get_children():
		if child.owner != null:
			owned += 1
	_expect("generated children", _room.get_child_count(), 3)
	_expect("children serialized into the scene", owned, 0)

	_hit("floor below centre", Vector3(0, 3, 0), Vector3(0, -5, 0), FLOOR_LIP)
	_hit("ceiling above centre", Vector3(0, 3, 0), Vector3(0, 20, 0), SIZE.y)
	_hit("east wall", Vector3(0, 3, 0), Vector3(20, 3, 0), SIZE.x * 0.5)
	_hit("west wall", Vector3(0, 3, 0), Vector3(-20, 3, 0), -SIZE.x * 0.5)
	_hit("north wall", Vector3(0, 3, 0), Vector3(0, 3, -20), -SIZE.z * 0.5)

	# Hollow, not solid: a ray crossing the interior must not hit anything
	# before it reaches the far wall.
	var space := root.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(
			Vector3(-SIZE.x * 0.5 + 0.5, 3, 0), Vector3(SIZE.x * 0.5 - 0.5, 3, 0))
	_expect_true("interior is clear", space.intersect_ray(query).is_empty())


func _check_resized() -> void:
	_hit("east wall after resize", Vector3(0, 3, 0), Vector3(30, 3, 0), RESIZED_X * 0.5)
	_hit("floor still at the lip", Vector3(0, 3, 0), Vector3(0, -5, 0), FLOOR_LIP)


## Casts a ray and checks the surface it lands on is at the expected distance
## along whichever axis the ray travels.
func _hit(label: String, from: Vector3, to: Vector3, expected: float) -> void:
	var space := root.get_world_3d().direct_space_state
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, to))
	if hit.is_empty():
		# Reported as its own failed check: a ray that hits nothing is a missing
		# surface, which _expect_near could not describe.
		_expect_true("%s (ray reached a surface)" % label, false)
		return
	var position: Vector3 = hit.position
	var axis := (to - from).normalized()
	var got: float = position.x if absf(axis.x) > 0.5 else \
			(position.y if absf(axis.y) > 0.5 else position.z)
	_expect_near(label, got, expected, TOLERANCE)
