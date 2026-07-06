class_name ShootableSwitch
extends StaticBody3D
## Doom-style wall switch, gated on combat: it starts dark (LOCKED) and
## only lights up red (ARMED, shootable) once every enemy in the level is
## dead. Shooting it then flips it green and powers the wired teleporter.
## Sits on the enemy collision layer so hitscan rays and rockets register
## hits via take_damage().

signal activated

enum State { LOCKED, ARMED, FLIPPED }

const SWITCH_SOUND := preload("res://assets/audio/switch.wav")
const DUD_SOUND := preload("res://assets/audio/click.wav")

const COLOR_LOCKED := Color(0.28, 0.29, 0.32)
const COLOR_ARMED := Color(0.95, 0.15, 0.1)
const COLOR_FLIPPED := Color(0.25, 1.0, 0.35)

@export var teleporter_path: NodePath

var _state := State.LOCKED
var _face_mat: StandardMaterial3D
var _poll := 0.0

@onready var _face: MeshInstance3D = $Face
@onready var _light: OmniLight3D = $Light


func _ready() -> void:
	_face_mat = _face.get_surface_override_material(0).duplicate()
	_face.set_surface_override_material(0, _face_mat)
	_face_mat.albedo_color = COLOR_LOCKED
	_light.visible = false


func _process(delta: float) -> void:
	if _state != State.LOCKED:
		return
	# Coarse poll; corpses leave the "enemies" group the moment they die.
	_poll -= delta
	if _poll <= 0.0:
		_poll = 0.3
		if get_tree().get_nodes_in_group("enemies").is_empty():
			_arm()


func take_damage(_amount: float, _from: Vector3 = Vector3.ZERO) -> void:
	match _state:
		State.LOCKED:
			Fx.spawn_sound(self, global_position, DUD_SOUND, -6.0)
		State.ARMED:
			_flip()
		State.FLIPPED:
			pass


func _arm() -> void:
	_state = State.ARMED
	_face_mat.albedo_color = COLOR_ARMED
	_light.light_color = COLOR_ARMED
	_light.visible = true
	GameState.announce("ALL ENEMIES DOWN - SWITCH ARMED")


func _flip() -> void:
	_state = State.FLIPPED
	_face_mat.albedo_color = COLOR_FLIPPED
	_light.light_color = COLOR_FLIPPED
	Fx.spawn_sound(self, global_position, SWITCH_SOUND, 2.0)
	Fx.spawn(self, global_position - global_basis.z * 0.3, Color(0.3, 1.0, 0.4), 0.5, 0.2)
	activated.emit()
	if not teleporter_path.is_empty():
		var teleporter := get_node_or_null(teleporter_path) as Teleporter
		if teleporter:
			teleporter.activate()
