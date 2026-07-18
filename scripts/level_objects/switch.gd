class_name ShootableSwitch
extends StaticBody3D
## Emerald crystal cluster, gated on combat: it starts as dull dark stone
## (LOCKED) and begins to glow and pulse (ARMED, shootable) once every
## enemy in the level is dead. Shooting it then makes it surge bright and
## powers the wired teleporter. Sits on the enemy collision layer so
## hitscan rays and rockets register hits via take_damage().

signal activated

enum State { LOCKED, ARMED, FLIPPED }

const SWITCH_SOUND := preload("res://assets/audio/switch.wav")
const DUD_SOUND := preload("res://assets/audio/click.wav")

const ALBEDO_LOCKED := Color(0.17, 0.19, 0.23)
const ALBEDO_ARMED := Color(0.16, 0.45, 0.3)
const ALBEDO_FLIPPED := Color(0.6, 0.95, 0.75)
const EMISSION_ARMED := Color(0.12, 0.95, 0.45)
const EMISSION_FLIPPED := Color(0.75, 1.0, 0.85)

@export var teleporter_path: NodePath

var _state := State.LOCKED
var _crystal_mat: StandardMaterial3D
var _poll := 0.0

@onready var _crystal: Node3D = $Crystal
@onready var _glow: MeshInstance3D = $Glow
@onready var _light: OmniLight3D = $Light
@onready var _pulse: AnimationPlayer = $Pulse


func _ready() -> void:
	# All shards share one material; duplicate it so state changes stay
	# per-instance.
	var shards := _crystal.find_children("*", "MeshInstance3D", true, false)
	_crystal_mat = shards[0].get_surface_override_material(0).duplicate()
	for shard: MeshInstance3D in shards:
		shard.set_surface_override_material(0, _crystal_mat)
	_crystal_mat.albedo_color = ALBEDO_LOCKED
	_glow.visible = false
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
	_crystal_mat.albedo_color = ALBEDO_ARMED
	_crystal_mat.emission_enabled = true
	_crystal_mat.emission = EMISSION_ARMED
	_crystal_mat.emission_energy_multiplier = 1.5
	_light.light_color = EMISSION_ARMED
	_light.visible = true
	_glow.visible = true
	_pulse.play("pulse")
	GameState.announce("ALL ENEMIES DOWN - THE EMERALD AWAKENS")


func _flip() -> void:
	_state = State.FLIPPED
	_pulse.stop()
	_crystal_mat.albedo_color = ALBEDO_FLIPPED
	_crystal_mat.emission = EMISSION_FLIPPED
	_crystal_mat.emission_energy_multiplier = 2.2
	_light.light_color = EMISSION_FLIPPED
	_light.light_energy = 1.5
	_glow.scale = Vector3.ONE * 1.25
	Fx.spawn_sound(self, global_position, SWITCH_SOUND, 2.0)
	Fx.spawn(self, global_position - global_basis.z * 0.3, Color(0.3, 1.0, 0.4), 0.5, 0.2)
	activated.emit()
	if not teleporter_path.is_empty():
		var teleporter := get_node_or_null(teleporter_path) as Teleporter
		if teleporter:
			teleporter.activate()
