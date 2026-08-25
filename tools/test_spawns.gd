extends "res://tools/test_base.gd"
## Debug helper: every enemy spawn in every campaign level is stand-able and
## not walled off from the rest of the level.
##
## Two distinct failures, both of which have actually shipped here:
## - EMBEDDED: the spawn sits inside a prop, so the solver shoves the enemy out
##   on the first frame and it reads as stuck on the scenery. Level 7's Rogue1
##   spawned inside the BoxA2 crate.
## - WALLED IN: the spawn is clear, but a prop blocks the only way out of the
##   pocket it stands in. A bed laid across the mouth of level 5's south cell
##   left 0.5 m gaps either side, and a grunt is 0.9 m wide.
##
##   Godot_v4.7-stable_win64_console.exe --headless --path . -s tools/test_spawns.gd
##
## Scope, so the result is not over-trusted: reachability is a flood fill over
## a STEP-metre grid keyed on (x, z) only, each sample dropped onto whatever
## floor is under that column. It is a ground-plane check. It proves an enemy's
## column is connected to the player spawn's, and it deliberately does NOT
## model climbing, so an enemy parked above the walkable route -- level 1's
## balcony grunt, level 6's platform enemies -- counts as reachable via the
## floor beneath it. The embedded check is exact.

const LEVELS := ["level_01", "level_02", "level_03", "level_04",
		"level_05", "level_06", "level_07"]

## Spawns that were already overlapping something when this test was written,
## with what each one is inside. They are asserted EXACTLY, not merely
## tolerated: a new overlap fails the run, and so does clearing one of these
## without deleting its line, which is the nudge to keep the list shrinking.
## None of them is fatal in play -- the solver shoves the body clear on the
## first frame -- but each is the same defect as the level-7 rogue that read
## as "stuck on the crates", so they are debt, not policy.
const KNOWN_EMBEDDED := {
	"level_01": ["GruntRoomC in ChestRoomC, CratesRoomC"],
	"level_02": ["Grunt3 in LevelCSG"],
	"level_03": ["Grunt4 in ChestGallery"],
	"level_04": ["Grunt3 in ChestWing"],
	"level_05": ["Grunt2 in LevelCSG"],
}

## level_04's Grunt3 is walled off as a CONSEQUENCE of being embedded in
## ChestWing above: the fill cannot sample the cells it is standing in. Clear
## that overlap and this line goes too.
const KNOWN_WALLED := {
	"level_04": ["Grunt3"],
}

## Grid pitch for the flood fill. Half the narrowest gap worth resolving.
const STEP := 0.5
## Height an enemy is assumed to walk up. Above this the fill treats the
## neighbouring column as a different storey and stops.
const MAX_STEP_UP := 1.2
## Keeps a probe capsule off the floor it stands on; below about 0.05 the
## physics margin makes every sample collide with its own ground.
const LIFT := 0.08
## The embedded probe is deliberately short. Full enemy height would measure
## headroom too, and level 1's balcony clears a grunt by only 0.02 m -- real,
## intended, and not what this test is looking for.
const PROBE_HEIGHT := 1.0
## Walking-clearance radius for the fill: a shade under the 0.45 m grunt so
## a corridor sized exactly to the enemy still reads as passable.
const FILL_RADIUS := 0.43
## Cheap runaway guard; the largest level fills about 3400 cells.
const MAX_CELLS := 200000

var _index := -1
var _level: Node3D = null
var _settle := 0
var _auditing := false
## Authored spawn points, captured before the solver gets a chance to move
## anything: {name, position, radius}. Probing the live global_position instead
## measures where the body was PUSHED to, which is exactly the symptom rather
## than the cause -- an enemy embedded in a crate has already been shoved clear
## of it by the time the first physics frame ends.
var _spawns: Array[Dictionary] = []


func _skip_auto_start() -> bool:
	return true


## The work runs on physics_frame: shape queries are only safe to issue while
## the physics server is stepping, and this test does thousands of them.
func _tick(_delta: float) -> bool:
	if not _auditing:
		_auditing = true
		physics_frame.connect(_audit)
	return false


func _audit() -> void:
	if _level == null:
		_index += 1
		if _index >= LEVELS.size():
			_finish()
			return
		_level = (load("res://scenes/levels/%s.tscn" % LEVELS[_index])
				as PackedScene).instantiate()
		_spawns = []
		var spawned: Node3D = _level.get_node_or_null("Enemies")
		if spawned != null:
			for enemy in spawned.get_children():
				_spawns.append({
					"name": String(enemy.name),
					"at": (enemy as Node3D).position,
					"radius": _capsule(enemy).x,
				})
		root.add_child(_level)
		_settle = 0
		return
	# Let the freshly added bodies register with the space before querying it.
	_settle += 1
	if _settle < 4:
		return
	_check(LEVELS[_index], _level)
	_level.queue_free()
	_level = null


## The enemy's real capsule -- the boss is far larger than a grunt, so probing
## everything with one hardcoded size reports nonsense for it.
func _capsule(enemy: Node) -> Vector2:
	var cs := enemy.find_child("CollisionShape3D", true, false) as CollisionShape3D
	if cs != null and cs.shape is CapsuleShape3D:
		var shape := cs.shape as CapsuleShape3D
		return Vector2(shape.radius, shape.height)
	return Vector2(0.45, 1.7)


func _blockers(space: PhysicsDirectSpaceState3D, at: Vector3, radius: float,
		height: float) -> Array[String]:
	var shape := CapsuleShape3D.new()
	shape.radius = radius
	shape.height = height
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY,
			at + Vector3(0, height * 0.5 + LIFT, 0))
	query.collision_mask = 1  # world geometry and props, not other enemies
	var names: Array[String] = []
	for hit in space.intersect_shape(query, 8):
		names.append(String((hit["collider"] as Node).name))
	return names


## Floor height in this column, searched from near_y so a multi-storey column
## resolves to the storey the fill is already walking on. NAN means no floor.
func _floor_y(space: PhysicsDirectSpaceState3D, x: float, z: float,
		near_y: float) -> float:
	var query := PhysicsRayQueryParameters3D.create(
			Vector3(x, near_y + 2.0, z), Vector3(x, near_y - 60.0, z), 1)
	var hit := space.intersect_ray(query)
	return hit["position"].y if hit else NAN


func _check(level_name: String, level: Node3D) -> void:
	var space := root.get_world_3d().direct_space_state
	var enemies: Node3D = level.get_node_or_null("Enemies")
	if enemies == null:
		_expect_true("%s has an Enemies node" % level_name, false)
		return
	var spawn := level.find_child("PlayerSpawn", true, false) as Node3D
	var start: Vector3 = spawn.global_position if spawn != null else Vector3.ZERO

	var embedded: Array[String] = []
	for spawn_point in _spawns:
		var names := _blockers(space, spawn_point["at"] as Vector3,
				spawn_point["radius"] as float, PROBE_HEIGHT)
		if not names.is_empty():
			embedded.append("%s in %s" % [spawn_point["name"], ", ".join(names)])
	embedded.sort()
	var known_embedded: Array[String] = []
	known_embedded.assign(KNOWN_EMBEDDED.get(level_name, []))
	known_embedded.sort()
	_expect("%s: embedded spawns are only the known ones" % level_name,
			embedded, known_embedded)

	var reached := _flood(space, start)
	var walled: Array[String] = []
	for spawn_point in _spawns:
		if not _near_reached(reached, spawn_point["at"] as Vector3):
			walled.append(spawn_point["name"] as String)
	walled.sort()
	var known_walled: Array[String] = []
	known_walled.assign(KNOWN_WALLED.get(level_name, []))
	known_walled.sort()
	_expect("%s: walled-off spawns are only the known ones" % level_name,
			walled, known_walled)
	_expect_greater("%s: fill covered the level" % level_name,
			float(reached.size()), 200.0)


## Walkable columns connected to `start`, as {Vector2i cell: floor height}.
func _flood(space: PhysicsDirectSpaceState3D, start: Vector3) -> Dictionary:
	var seen := {}
	var queue: Array[Vector2i] = []
	var first := Vector2i(roundi(start.x / STEP), roundi(start.z / STEP))
	seen[first] = start.y
	queue.append(first)
	var guard := 0
	while not queue.is_empty() and guard < MAX_CELLS:
		guard += 1
		var cell: Vector2i = queue.pop_back()
		var from_y: float = seen[cell]
		for offset in [Vector2i(1, 0), Vector2i(-1, 0),
				Vector2i(0, 1), Vector2i(0, -1)]:
			var next: Vector2i = cell + offset
			if seen.has(next):
				continue
			var x := next.x * STEP
			var z := next.y * STEP
			var y := _floor_y(space, x, z, from_y)
			if is_nan(y) or absf(y - from_y) > MAX_STEP_UP:
				continue
			if not _blockers(space, Vector3(x, y, z), FILL_RADIUS,
					PROBE_HEIGHT).is_empty():
				continue
			seen[next] = y
			queue.append(next)
	return seen


## True if any of the nine cells around this position was reached. The slack
## absorbs a spawn sitting mid-cell rather than on a grid point.
func _near_reached(reached: Dictionary, at: Vector3) -> bool:
	var cell := Vector2i(roundi(at.x / STEP), roundi(at.z / STEP))
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			if reached.has(cell + Vector2i(dx, dz)):
				return true
	return false
