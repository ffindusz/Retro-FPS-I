class_name Pickup
extends Area3D
## Spinning floor pickup for health or ammo. Classic rule: refuses
## collection while the stat is already full, so it stays for later.

enum Type { HEALTH, BULLETS, SHELLS, ROCKETS, CELLS }

const HEAL_SOUND := preload("res://assets/audio/heal.wav")
const PICKUP_SOUND := preload("res://assets/audio/pickup.wav")

@export var type := Type.HEALTH
@export var amount := 25

var _taken := false

@onready var _visual: Node3D = $Visual


func _ready() -> void:
	add_to_group("pickups")
	body_entered.connect(_try_collect)


func _process(delta: float) -> void:
	_visual.rotate_y(delta * 2.2)
	_visual.position.y = 0.05 + (sin(Time.get_ticks_msec() * 0.003) + 1.0) * 0.05


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
		var wm: WeaponManager = body.get_node_or_null("Head/Camera3D/WeaponManager")
		if wm:
			applied = wm.add_ammo_for_type(type, amount)
	if not applied:
		return
	_taken = true
	var color := Color(0.6, 1.0, 0.7) if type == Type.HEALTH else Color(1.0, 0.9, 0.5)
	Fx.spawn_sound(self, global_position, HEAL_SOUND if type == Type.HEALTH else PICKUP_SOUND)
	Fx.spawn(self, global_position + Vector3(0, 0.5, 0), color, 0.45, 0.15)
	queue_free()
