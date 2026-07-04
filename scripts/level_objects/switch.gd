class_name ShootableSwitch
extends StaticBody3D
## Doom-style wall switch: shoot it to flip it. Sits on the enemy collision
## layer so hitscan rays and rockets register hits via take_damage(). Wire
## `teleporter_path` in the level scene (or connect `activated` manually).

signal activated

const SWITCH_SOUND := preload("res://assets/audio/switch.wav")

@export var teleporter_path: NodePath

var _flipped := false

@onready var _face: MeshInstance3D = $Face


func take_damage(_amount: float, _from: Vector3 = Vector3.ZERO) -> void:
	if _flipped:
		return
	_flipped = true
	var mat: StandardMaterial3D = _face.get_surface_override_material(0).duplicate()
	mat.albedo_color = Color(0.25, 1.0, 0.35)
	_face.set_surface_override_material(0, mat)
	Fx.spawn_sound(self, global_position, SWITCH_SOUND, 2.0)
	Fx.spawn(self, global_position - global_basis.z * 0.3, Color(0.3, 1.0, 0.4), 0.5, 0.2)
	activated.emit()
	if not teleporter_path.is_empty():
		var teleporter := get_node_or_null(teleporter_path)
		if teleporter:
			teleporter.activate()
