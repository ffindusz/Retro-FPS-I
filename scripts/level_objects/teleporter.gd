class_name Teleporter
extends Area3D
## Portal pad that sends the player to the next level once a crystal
## switch has opened it. A dark inert dais until then; on activation a
## swirling vortex (shaders/vortex.gdshader) appears above a slowly
## churning pool, and stepping in completes the level.

const TELEPORT_SOUND := preload("res://assets/audio/teleport.wav")

var _active := false
var _used := false

@onready var _pool: MeshInstance3D = $Pool
@onready var _vortex: MeshInstance3D = $Vortex
@onready var _halo: MeshInstance3D = $Halo
@onready var _light: OmniLight3D = $Light
@onready var _pulse: AnimationPlayer = $Pulse


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_pool.visible = false
	_vortex.visible = false
	_halo.visible = false
	_light.visible = false


func activate() -> void:
	if _active:
		return
	_active = true
	_pool.visible = true
	_vortex.visible = true
	_halo.visible = true
	_light.visible = true
	_pulse.play("pulse")
	GameState.announce("THE PORTAL OPENS")


func _on_body_entered(body: Node3D) -> void:
	if not _active or _used or not body.is_in_group("player"):
		return
	_used = true
	Fx.spawn_sound(self, global_position, TELEPORT_SOUND, 3.0)
	GameState.flash_teleport()
	# Departure: the vortex swells and flares while the screen whites out,
	# then the level completes. Stop the idle pulse first - it animates the
	# same properties the swell tween drives.
	_pulse.stop()
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_vortex, "scale", Vector3.ONE * 1.7, 0.45) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(_halo, "scale", Vector3.ONE * 1.9, 0.45) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(_light, "light_energy", 3.5, 0.45)
	tween.chain().tween_callback(GameState.complete_level)
