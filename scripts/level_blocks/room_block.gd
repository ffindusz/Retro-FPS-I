@tool
class_name RoomBlock
extends CSGCombiner3D
## A hollow room as one node, for building levels in the viewport.
##
## Every room in the hand-built levels is three CSG brushes that have to be
## kept in sync by hand -- a solid Shell, a slightly smaller Cut subtracted to
## hollow it out, and a thin Floor slab poking up through the bottom so the
## floor reads as a different material from the walls. Resizing a room means
## editing all three, and retexturing one means finding every one of them
## (level_05 has 38 separate material assignments).
##
## This builds those three from room_size and two material slots, and rebuilds
## them whenever you drag a handle in the editor.
##
## Placement: the origin sits at the CENTRE OF THE FLOOR, not the centre of
## the box, so a room dropped at a point on the ground is standing on it. The
## interior spans y in [0, room_size.y].
##
## Doorways: cut them the usual way, with a CSGBox3D set to Subtraction as a
## SIBLING of this node inside the level's LevelCSG. A nested combiner is a
## single operand to its parent, so a later sibling subtraction still carves
## through these walls. What it does NOT do is let an unrelated Cut elsewhere
## in the level reach in and hollow this room by accident, which is the
## failure mode of one big flat combiner.
##
## The generated children are deliberately not given an owner, so they are
## rebuilt on load rather than serialized into the level .tscn -- the whole
## point is that the file stores a room, not three boxes.

## Interior dimensions: the space you can actually walk around in.
@export var room_size := Vector3(12.0, 6.0, 12.0):
	set(value):
		room_size = value
		_rebuild()

## Wall/ceiling/underfloor solidity around the interior.
@export var wall_thickness := 1.0:
	set(value):
		wall_thickness = maxf(value, 0.01)
		_rebuild()

@export var wall_material: Material:
	set(value):
		wall_material = value
		_rebuild()

@export_group("Floor")
## Set false for a room that should open onto whatever is underneath it, like
## a ledge over a lava pit.
@export var build_floor := true:
	set(value):
		build_floor = value
		_rebuild()

@export var floor_material: Material:
	set(value):
		floor_material = value
		_rebuild()

@export var floor_thickness := 0.25:
	set(value):
		floor_thickness = maxf(value, 0.01)
		_rebuild()

## How far the slab pokes up past y=0 into the room. Without this the slab top
## and the interior floor are coplanar and z-fight; matches the 0.05 the
## hand-built levels use.
@export var floor_lip := 0.05:
	set(value):
		floor_lip = value
		_rebuild()
@export_group("")

var _shell: CSGBox3D
var _cut: CSGBox3D
var _slab: CSGBox3D


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	# Setters fire while the scene is still loading, before the node is in the
	# tree and before the other exports have their stored values; _ready()
	# runs the build that counts.
	if not is_inside_tree():
		return
	_ensure_children()

	var interior := room_size
	var half_height := interior.y * 0.5

	_shell.size = interior + Vector3.ONE * wall_thickness * 2.0
	_shell.position = Vector3(0.0, half_height, 0.0)
	_shell.material = wall_material

	_cut.size = interior
	_cut.position = Vector3(0.0, half_height, 0.0)
	_cut.operation = CSGShape3D.OPERATION_SUBTRACTION
	# The cut brush is what actually produces the visible inner wall faces, so
	# it needs the wall material too -- a cut left without one is how the
	# untextured-alcove bugs happened.
	_cut.material = wall_material

	_slab.visible = build_floor
	if build_floor:
		# Slightly oversized in x/z so its edges bury into the walls instead of
		# z-fighting along the seam.
		_slab.size = Vector3(interior.x + 0.1, floor_thickness, interior.z + 0.1)
		_slab.position = Vector3(0.0, floor_lip - floor_thickness * 0.5, 0.0)
		_slab.material = floor_material


func _ensure_children() -> void:
	if _shell == null:
		_shell = _make_box("Shell")
	if _cut == null:
		_cut = _make_box("Cut")
	if _slab == null:
		_slab = _make_box("Floor")


func _make_box(node_name: String) -> CSGBox3D:
	# Reuse a child that already exists (a rebuild after a reload can outrun
	# our references) rather than stacking up duplicates.
	var existing := get_node_or_null(NodePath(node_name)) as CSGBox3D
	if existing != null:
		return existing
	var box := CSGBox3D.new()
	box.name = node_name
	add_child(box)
	# No owner on purpose: un-owned children are not written to the .tscn.
	return box


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if wall_material == null:
		warnings.append("No wall_material: the room will render untextured.")
	if build_floor and floor_material == null:
		warnings.append("No floor_material: the floor slab will render untextured.")
	if room_size.x <= 0.0 or room_size.y <= 0.0 or room_size.z <= 0.0:
		warnings.append("room_size must be positive on every axis.")
	return warnings
