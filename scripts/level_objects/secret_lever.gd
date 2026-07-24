class_name SecretLever
extends StaticBody3D
## A wall lever you shoot to open a linked secret door. Sits on the world +
## enemy collision layers so hitscan rays and rocket splash register hits via
## take_damage(). Unlike the crystal exit switch it is NOT gated on clearing
## the level -- it is a hidden bonus, live from the start. One shot throws the
## handle, recolors its glow, and opens the door it points at.

const THROW_SOUND := preload("res://assets/audio/switch.wav")

@export var door_path: NodePath
@export var armed_glow := Color(1.0, 0.68, 0.2)
@export var thrown_glow := Color(0.4, 1.0, 0.5)

var _thrown := false
var _glow_mat: StandardMaterial3D
var _plate_mat: StandardMaterial3D

@onready var _handle: Node3D = $Handle
@onready var _light: OmniLight3D = $Light
@onready var _base: MeshInstance3D = $Base


func _ready() -> void:
	# Own copy of the plate material so recoloring it on throw stays per-lever.
	var plate := _base.mesh.surface_get_material(0)
	if plate != null:
		_plate_mat = plate.duplicate()
		_base.set_surface_override_material(0, _plate_mat)
	# A billboard glow halo (the same trick pickups use) so the lever reads as
	# interactive even in a dark alcove: the level is one CSG mesh, so the
	# mobile renderer silently drops extra omni lights on it.
	var glow := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.85, 0.85)
	glow.mesh = quad
	_glow_mat = StandardMaterial3D.new()
	_glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_glow_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_glow_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_glow_mat.albedo_color = Color(armed_glow, 0.4)
	# Radial falloff so the quad reads as a soft halo, not a colored card.
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	var falloff := GradientTexture2D.new()
	falloff.gradient = gradient
	falloff.fill = GradientTexture2D.FILL_RADIAL
	falloff.fill_from = Vector2(0.5, 0.5)
	falloff.fill_to = Vector2(0.5, 0.0)
	_glow_mat.albedo_texture = falloff
	glow.material_override = _glow_mat
	glow.position = Vector3(0, 1.05, 0.28)
	add_child(glow)


func take_damage(_amount: float, _from: Vector3 = Vector3.ZERO) -> void:
	if _thrown:
		return
	_thrown = true
	# Swing the handle outward (-X is toward the room for a +Z-into-room
	# wall mount); recolor the glow from "armed" amber to "thrown".
	var tween := create_tween()
	tween.tween_property(_handle, "rotation:x", deg_to_rad(-72), 0.25) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_light.light_color = thrown_glow
	_glow_mat.albedo_color = Color(thrown_glow, 0.4)
	if _plate_mat != null:
		_plate_mat.emission = thrown_glow
	# Local offset so the burst sits in front of the handle whichever wall
	# the lever hangs on (a world-space offset drifts sideways along the wall).
	Fx.spawn(self, to_global(Vector3(0, 1.05, 0.3)), thrown_glow, 0.5, 0.2)
	Fx.spawn_sound(self, global_position, THROW_SOUND, 2.0)
	GameState.announce("A MECHANISM GRINDS...")
	# Duck-typed rather than `as SecretDoor`: a class_name reference here would
	# force SecretDoor to compile before it is registered under `-s`, breaking
	# the headless smoke tests.
	if not door_path.is_empty():
		var door := get_node_or_null(door_path)
		if door != null and door.has_method("open"):
			door.open()
