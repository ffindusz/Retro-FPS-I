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

const HURT_SOUND := preload("res://assets/audio/hurt.wav")

var _shake := 0.0

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D


func take_damage(amount: float, _from: Vector3 = Vector3.ZERO) -> void:
	GameState.damage_player(int(amount))
	_shake = minf(_shake + 0.25, 0.5)
	Fx.spawn_sound(self, global_position, HURT_SOUND)


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


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


func _physics_process(delta: float) -> void:
	var input_2d := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var wish_dir := (transform.basis * Vector3(input_2d.x, 0.0, input_2d.y)).normalized()

	if is_on_floor():
		_apply_friction(delta)
		_accelerate(wish_dir, walk_speed, ground_accel, delta)
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity
	else:
		_accelerate(wish_dir, walk_speed, air_accel, delta)
		velocity.y -= gravity * delta

	move_and_slide()


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
