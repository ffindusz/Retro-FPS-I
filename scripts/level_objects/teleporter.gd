class_name Teleporter
extends Area3D
## Portal pad that sends the player to the next level once a crystal
## switch has opened it. A dark inert dais until then; on activation a
## swirling vortex (shaders/vortex.gdshader) appears above a slowly
## churning pool, and stepping in completes the level.

## Where stepping in leads. NEXT_LEVEL is the campaign teleporter every level
## uses; the other two are the pair flanking the treasure in level 7.
enum Destination { NEXT_LEVEL, NEW_LOOP, MONUMENT }

const TELEPORT_SOUND := preload("res://assets/audio/teleport.wav")

@export var destination: Destination = Destination.NEXT_LEVEL

@export_group("Colour")
## Recolours the portal so two pads in the same room can be told apart at a
## glance -- the endgame pair in level 7 is red for "descend, harder" and gold
## for "the monument". The defaults reproduce the campaign teleporter exactly,
## so every existing pad is untouched.
@export var tint_a := Color(0.2, 1.0, 0.9)
@export var tint_b := Color(0.45, 0.3, 1.0)
## Drives the point light and the halo glow (the halo keeps its own alpha).
@export var portal_color := Color(0.4, 1.0, 0.9)
@export_group("")

@export_group("Departure")
## How long the vortex swells and the screen whites out before the level
## actually completes. Headless tests pad their waits around this (see
## tools/test_progression.gd), so lengthening it means lengthening those.
@export var departure_time := 0.45
@export var vortex_swell := 1.7
@export var halo_swell := 1.9
@export var flare_energy := 3.5
@export_group("")

var _active := false
var _used := false

@onready var _pool: MeshInstance3D = $Pool
@onready var _vortex: MeshInstance3D = $Vortex
@onready var _halo: MeshInstance3D = $Halo
@onready var _light: OmniLight3D = $Light
@onready var _pulse: AnimationPlayer = $Pulse


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_apply_colour()
	_pool.visible = false
	_vortex.visible = false
	_halo.visible = false
	_light.visible = false


## Materials defined inside teleporter.tscn are SHARED between every instance
## of it, so setting a shader parameter straight on one pad would recolour all
## of them -- including the six campaign teleporters. Duplicate first, then
## tint, so each pad owns its look.
func _apply_colour() -> void:
	for mesh: MeshInstance3D in [_pool, _vortex]:
		var mat := (mesh.material_override as ShaderMaterial).duplicate() as ShaderMaterial
		mat.set_shader_parameter("tint_a", tint_a)
		mat.set_shader_parameter("tint_b", tint_b)
		mesh.material_override = mat
	var halo := (_halo.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
	halo.albedo_color = Color(portal_color.r, portal_color.g, portal_color.b,
			halo.albedo_color.a)
	_halo.material_override = halo
	_light.light_color = portal_color


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
	tween.tween_property(_vortex, "scale", Vector3.ONE * vortex_swell, departure_time) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(_halo, "scale", Vector3.ONE * halo_swell, departure_time) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(_light, "light_energy", flare_energy, departure_time)
	tween.chain().tween_callback(_depart)


func _depart() -> void:
	match destination:
		Destination.NEW_LOOP:
			GameState.begin_new_loop()
		Destination.MONUMENT:
			GameState.enter_monument()
		_:
			GameState.complete_level()
