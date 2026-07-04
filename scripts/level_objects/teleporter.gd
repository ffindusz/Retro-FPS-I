class_name Teleporter
extends Area3D
## Floor pad that sends the player to the next level once a switch has
## activated it. Dark and inert until then.

const TELEPORT_SOUND := preload("res://assets/audio/teleport.wav")

var _active := false
var _used := false

@onready var _core: MeshInstance3D = $Core
@onready var _light: OmniLight3D = $Light


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_light.visible = false


func activate() -> void:
	if _active:
		return
	_active = true
	var mat: StandardMaterial3D = _core.get_surface_override_material(0).duplicate()
	mat.albedo_color = Color(0.3, 1.0, 0.9)
	_core.set_surface_override_material(0, mat)
	_light.visible = true
	GameState.announce("TELEPORTER ONLINE")


func _on_body_entered(body: Node3D) -> void:
	if not _active or _used or not body.is_in_group("player"):
		return
	_used = true
	Fx.spawn_sound(self, global_position, TELEPORT_SOUND, 3.0)
	GameState.complete_level()
