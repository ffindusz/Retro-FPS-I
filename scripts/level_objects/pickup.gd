class_name Pickup
extends Area3D
## Spinning floor pickup for health or ammo. Classic rule: refuses
## collection while the stat is already full, so it stays for later.

enum Type { HEALTH, BULLETS, SHELLS, ROCKETS, CELLS }

const HEAL_SOUND := preload("res://assets/audio/heal.wav")
const PICKUP_SOUND := preload("res://assets/audio/pickup.wav")

const SPIN_SPEED := 2.2  ## Radians/sec.
const FLOAT_SPEED := 0.003  ## Sine input scale applied to msec.
const FLOAT_MIN_HEIGHT := 0.05
const FLOAT_AMPLITUDE := 0.05

@export var type := Type.HEALTH
@export var amount := 25

var _taken := false

@onready var _visual: Node3D = $Visual


func _ready() -> void:
	add_to_group("pickups")
	body_entered.connect(_try_collect)


func _process(delta: float) -> void:
	_visual.rotate_y(delta * SPIN_SPEED)
	_visual.position.y = FLOAT_MIN_HEIGHT \
			+ (sin(Time.get_ticks_msec() * FLOAT_SPEED) + 1.0) * FLOAT_AMPLITUDE


func _physics_process(_delta: float) -> void:
	# body_entered alone misses a player who is ALREADY standing on the
	# pickup when they become eligible (e.g. take damage while on a medkit
	# they were too healthy to grab), so re-check overlaps continuously.
	if _taken:
		return
	for body in get_overlapping_bodies():
		_try_collect(body)


func _try_collect(body: Node3D) -> void:
	if _taken or not body.is_in_group("player"):
		return
	var applied := false
	if type == Type.HEALTH:
		applied = GameState.heal(amount)
	else:
		var pc := body as PlayerController
		if pc:
			applied = pc.weapon_manager.add_ammo_for_type(type, amount)
	if not applied:
		return
	_taken = true
	var color := Color(0.6, 1.0, 0.7) if type == Type.HEALTH else Color(1.0, 0.9, 0.5)
	Fx.spawn_sound(self, global_position, HEAL_SOUND if type == Type.HEALTH else PICKUP_SOUND)
	Fx.spawn(self, global_position + Vector3(0, 0.5, 0), color, 0.45, 0.15)
	queue_free()
