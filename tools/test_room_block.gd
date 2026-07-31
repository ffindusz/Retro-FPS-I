extends SceneTree
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
var _ok := true


func _initialize() -> void:
	_level = CSGCombiner3D.new()
	_level.use_collision = true
	root.add_child(_level)
	_room = ROOM.instantiate()
	_level.add_child(_room)
	_room.room_size = SIZE
	physics_frame.connect(_step)


func _step() -> void:
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
			print("ROOM BLOCK TEST: %s" % ["PASS" if _ok else "FAIL"])
			quit(0 if _ok else 1)


func _check_built() -> void:
	# Generated brushes must exist at runtime but stay out of the saved scene,
	# which is what having no owner means.
	var owned := 0
	for child in _room.get_children():
		if child.owner != null:
			owned += 1
	_report("generated children", _room.get_child_count(), 3)
	_report("children serialized into the scene", owned, 0)

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
	_report("interior is clear", space.intersect_ray(query).is_empty(), true)


func _check_resized() -> void:
	_hit("east wall after resize", Vector3(0, 3, 0), Vector3(30, 3, 0), RESIZED_X * 0.5)
	_hit("floor still at the lip", Vector3(0, 3, 0), Vector3(0, -5, 0), FLOOR_LIP)


## Casts a ray and checks the surface it lands on is at the expected distance
## along whichever axis the ray travels.
func _hit(label: String, from: Vector3, to: Vector3, expected: float) -> void:
	var space := root.get_world_3d().direct_space_state
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, to))
	if hit.is_empty():
		_ok = false
		print("%s: NO HIT (expected %.2f)  <-- MISMATCH" % [label, expected])
		return
	var position: Vector3 = hit.position
	var axis := (to - from).normalized()
	var got: float = position.x if absf(axis.x) > 0.5 else \
			(position.y if absf(axis.y) > 0.5 else position.z)
	var close := absf(got - expected) <= TOLERANCE
	if not close:
		_ok = false
	print("%s: %.3f (expect %.2f)%s"
			% [label, got, expected, "" if close else "  <-- MISMATCH"])


func _report(label: String, got: Variant, want: Variant) -> void:
	var hit: bool = got == want
	if not hit:
		_ok = false
	print("%s: %s (expect %s)%s" % [label, got, want, "" if hit else "  <-- MISMATCH"])
