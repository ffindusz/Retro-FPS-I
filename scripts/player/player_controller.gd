class_name PlayerController
extends CharacterBody3D
## Quake-style first-person controller: ground friction + acceleration
## toward a "wish direction", mild air control, jump, mouse look.
## Movement math mirrors Quake 1's pmove.

@export_group("Look")
@export var mouse_sensitivity := 0.002
@export var pitch_limit_deg := 89.0

@export_group("Movement")
@export var walk_speed := 7.0
@export var ground_accel := 10.0
@export var air_accel := 1.5
@export var friction := 6.0
@export var jump_velocity := 8.0
@export var gravity := 20.0

@export_group("Crouch")
@export var crouch_height := 1.2
@export var crouch_speed_factor := 0.55
@export var crouch_head_height := 1.0

const HURT_SOUND := preload("res://assets/audio/hurt.wav")

var _shake := 0.0
var _crouching := false
var _stand_height := 1.8
var _stand_head_height := 1.6

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var _collision: CollisionShape3D = $CollisionShape3D


func take_damage(amount: float, _from: Vector3 = Vector3.ZERO) -> void:
	GameState.damage_player(int(amount))
	_shake = minf(_shake + 0.25, 0.5)
	Fx.spawn_sound(self, global_position, HURT_SOUND)


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Unique capsule so runtime crouch resizing can't leak into the packed
	# scene's shared resource (and thus into the next respawned player).
	_collision.shape = _collision.shape.duplicate()
	_stand_height = (_collision.shape as CapsuleShape3D).height
	_stand_head_height = head.position.y


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# screen_relative is in physical pixels, unaffected by the low-res
		# SubViewport scaling (plain `relative` arrives divided by the
		# container's stretch factor, which would slow the look 4x).
		var motion: Vector2 = event.screen_relative
		rotate_y(-motion.x * mouse_sensitivity)
		head.rotation.x = clampf(head.rotation.x - motion.y * mouse_sensitivity,
				-deg_to_rad(pitch_limit_deg), deg_to_rad(pitch_limit_deg))
	elif event.is_action_pressed("ui_cancel"):
		# Dev convenience: Esc toggles mouse capture.
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(delta: float) -> void:
	# Damage screen shake: random camera offset with quick decay.
	_shake = maxf(_shake - delta * 1.6, 0.0)
	camera.h_offset = randf_range(-_shake, _shake) * 0.35
	camera.v_offset = randf_range(-_shake, _shake) * 0.35
	# Smooth camera drop/rise between crouch and stand.
	var target_head := crouch_head_height if _crouching else _stand_head_height
	head.position.y = lerpf(head.position.y, target_head, minf(delta * 12.0, 1.0))


func _physics_process(delta: float) -> void:
	_update_crouch()
	var speed := walk_speed * (crouch_speed_factor if _crouching else 1.0)
	var input_2d := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var wish_dir := (transform.basis * Vector3(input_2d.x, 0.0, input_2d.y)).normalized()

	if is_on_floor():
		_apply_friction(delta)
		_accelerate(wish_dir, speed, ground_accel, delta)
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity
	else:
		_accelerate(wish_dir, speed, air_accel, delta)
		velocity.y -= gravity * delta

	move_and_slide()


func _update_crouch() -> void:
	var want := Input.is_action_pressed("crouch")
	if want == _crouching:
		return
	if want:
		_set_crouch(true)
	elif _has_headroom():
		_set_crouch(false)


func _set_crouch(crouch: bool) -> void:
	_crouching = crouch
	var height := crouch_height if crouch else _stand_height
	(_collision.shape as CapsuleShape3D).height = height
	# Keep the capsule's feet on the floor while it shrinks from the top.
	_collision.position.y = height / 2.0


func _has_headroom() -> bool:
	var from := global_position + Vector3(0, crouch_height - 0.1, 0)
	var to := global_position + Vector3(0, _stand_height + 0.05, 0)
	var query := PhysicsRayQueryParameters3D.create(from, to, 1, [get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _accelerate(wish_dir: Vector3, wish_speed: float, accel: float, delta: float) -> void:
	# Quake accelerate: only add speed up to the shortfall between wish_speed
	# and the velocity already projected onto wish_dir, so holding a direction
	# you are already moving in fast adds nothing.
	var current_speed := velocity.dot(wish_dir)
	var add_speed := wish_speed - current_speed
	if add_speed <= 0.0:
		return
	velocity += wish_dir * minf(accel * wish_speed * delta, add_speed)


func _apply_friction(delta: float) -> void:
	var speed := Vector2(velocity.x, velocity.z).length()
	if speed < 0.01:
		velocity.x = 0.0
		velocity.z = 0.0
		return
	# Exponential-ish decay: drop a fraction of current speed each tick.
	var drop := speed * friction * delta
	var scale := maxf(speed - drop, 0.0) / speed
	velocity.x *= scale
	velocity.z *= scale
