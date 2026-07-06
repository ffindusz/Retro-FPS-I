class_name EnemyBase
extends CharacterBody3D
## Base enemy with a simple FSM: IDLE -> NOTICE -> CHASE -> ATTACK -> DEAD.
## Detection is distance + line-of-sight; steering is direct pursuit (the
## level is open enough that no navmesh is needed). Subclasses override
## _do_attack() for their attack type.

signal died(enemy: EnemyBase)

enum State { IDLE, NOTICE, CHASE, ATTACK, DEAD }

@export var max_health := 40.0
@export var move_speed := 3.5
@export var notice_range := 13.0
@export var attack_range := 2.0
@export var attack_damage := 10.0
@export var attack_interval := 1.1
@export var notice_delay := 0.45
@export var turn_speed := 8.0
@export var gravity := 20.0

## Bit values: 1 = world, 2 = player. Other enemies never block LOS.
const LOS_MASK := 0b11

const HIT_SOUND := preload("res://assets/audio/enemy_hit.wav")
const DIE_SOUND := preload("res://assets/audio/enemy_die.wav")

var health: float
var state: State = State.IDLE

var _player: Node3D
var _state_time := 0.0
var _attack_timer := 0.0
var _check_timer := 0.0

@onready var visual: Node3D = $Visual


func _ready() -> void:
	health = max_health
	add_to_group("enemies")


func _physics_process(delta: float) -> void:
	# Lazy player lookup: the level (with enemies) can enter the tree before
	# the player does, and the player is replaced on restart.
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
	_state_time += delta
	if not is_on_floor():
		velocity.y -= gravity * delta
	match state:
		State.IDLE:
			_tick_idle(delta)
		State.NOTICE:
			_tick_notice(delta)
		State.CHASE:
			_tick_chase(delta)
		State.ATTACK:
			_tick_attack(delta)
		State.DEAD:
			velocity.x = 0.0
			velocity.z = 0.0
	move_and_slide()


func take_damage(amount: float, _from: Vector3 = Vector3.ZERO) -> void:
	if state == State.DEAD:
		return
	health -= amount
	_flash_hit()
	if health <= 0.0:
		_die()
	elif state == State.IDLE or state == State.NOTICE:
		# Getting shot skips the polite notice pause.
		_enter(State.CHASE)


func _tick_idle(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	# Perception polls on a coarse timer; raycasts every physics tick for
	# every idle enemy would be wasted work.
	_check_timer -= delta
	if _check_timer <= 0.0:
		_check_timer = 0.25
		if _distance_to_player() < notice_range and _can_see_player():
			_enter(State.NOTICE)


func _tick_notice(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	_face_player(delta)
	if _state_time >= notice_delay:
		_enter(State.CHASE)


func _tick_chase(delta: float) -> void:
	if _player == null:
		return
	_face_player(delta)
	var to := _player.global_position - global_position
	to.y = 0.0
	var dir := to.normalized()
	# Obstacle handling: when pressed against a wall/crate, steer along it
	# instead of grinding into it head-on (poor man's avoidance).
	if is_on_wall():
		var normal := get_wall_normal()
		normal.y = 0.0
		var slide := dir - normal * dir.dot(normal)
		if slide.length() < 0.25:
			slide = normal.cross(Vector3.UP)
		dir = slide.normalized()
	velocity.x = dir.x * move_speed
	velocity.z = dir.z * move_speed
	if to.length() <= attack_range and _can_see_player():
		_enter(State.ATTACK)


func _tick_attack(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	_face_player(delta)
	_attack_timer -= delta
	if _distance_to_player() > attack_range * 1.3 or not _can_see_player():
		_enter(State.CHASE)
		return
	if _attack_timer <= 0.0:
		_attack_timer = attack_interval
		_do_attack()


## Default attack: melee swipe. Range re-checked with slack so a player
## backpedaling mid-swing can still be clipped.
func _do_attack() -> void:
	if _player and _player.has_method("take_damage") \
			and _distance_to_player() <= attack_range * 1.4:
		_player.take_damage(attack_damage, global_position)


func _enter(new_state: State) -> void:
	state = new_state
	_state_time = 0.0
	if new_state == State.ATTACK:
		# First swing comes after a short windup, not a full interval.
		_attack_timer = attack_interval * 0.5


func _die() -> void:
	state = State.DEAD
	died.emit(self)
	GameState.enemy_killed()
	# Leave the group immediately so kill-counting logic (switch arming)
	# doesn't wait out the corpse-despawn delay.
	remove_from_group("enemies")
	Fx.spawn_sound(self, global_position + Vector3(0, 1, 0), DIE_SOUND)
	# Corpse: no longer hittable or blocking, topples over, then despawns.
	collision_layer = 0
	collision_mask = 1
	var tween := create_tween()
	tween.tween_property(visual, "rotation:x", -PI / 2.0, 0.35) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_interval(1.4)
	tween.tween_callback(queue_free)


func _face_player(delta: float) -> void:
	if _player == null:
		return
	var to := _player.global_position - global_position
	var target_yaw := atan2(-to.x, -to.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, minf(turn_speed * delta, 1.0))


func _distance_to_player() -> float:
	# Horizontal distance: keeps range checks consistent with chase steering
	# and avoids attack-state flicker when heights differ slightly.
	if _player == null:
		return INF
	var to := _player.global_position - global_position
	to.y = 0.0
	return to.length()


func _can_see_player() -> bool:
	if _player == null:
		return false
	var from := global_position + Vector3(0, 1.4, 0)
	var to := _player.global_position + Vector3(0, 0.9, 0)
	var query := PhysicsRayQueryParameters3D.create(from, to, LOS_MASK, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.collider == _player


func _flash_hit() -> void:
	Fx.spawn(self, global_position + Vector3(0, 1.1, 0), Color(0.9, 0.2, 0.15), 0.3)
	Fx.spawn_sound(self, global_position + Vector3(0, 1.1, 0), HIT_SOUND, -4.0)
	if visual == null:
		return
	visual.scale = Vector3(1.12, 0.9, 1.12)
	var tween := create_tween()
	tween.tween_property(visual, "scale", Vector3.ONE, 0.12)
