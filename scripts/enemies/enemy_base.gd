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
## Defaults to the project's physics/3d/default_gravity (see project.godot)
## rather than a separately hardcoded value.
@export var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

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

## Circle-strafe direction/timer shared by attack patterns that keep moving
## instead of standing still (see boss.gd, enemy_spitter.gd).
var _strafe_dir := 1.0
var _strafe_timer := 0.0

## Animation driver for skinned models: if the Visual holds an imported
## AnimationPlayer (grunt, spitter), these looping clips play per FSM state
## and _death_visual() plays Death_A. Box-model enemies (boss) have no
## AnimationPlayer and keep the tween-based presentation. Subclasses adjust
## the clip names in _ready() and fire one-shots via _play_one_shot().
const ANIM_BLEND := 0.15
var _clip_idle := "Idle"         ## IDLE / NOTICE
var _clip_run := "Running_A"     ## CHASE
var _clip_attack_hold := "Idle"  ## ATTACK, between one-shot swings
var _one_shot := ""              ## in-flight swing clip; never interrupted
var _anim: AnimationPlayer

@onready var visual: Node3D = $Visual


func _ready() -> void:
	health = max_health
	add_to_group("enemies")
	_anim = visual.find_child("AnimationPlayer", true, false)


func _process(_delta: float) -> void:
	if _anim == null:
		return
	match state:
		State.DEAD:
			pass  # _death_visual() played the death clip; hold the pose.
		State.CHASE:
			_ensure(_clip_run)
		State.ATTACK:
			if _one_shot == "" or _anim.current_animation != _one_shot \
					or not _anim.is_playing():
				_ensure(_clip_attack_hold)
		_:
			_ensure(_clip_idle)


func _play_one_shot(clip: String, speed := 1.0) -> void:
	if _anim != null:
		_one_shot = clip
		_anim.play(clip, ANIM_BLEND, speed)


func _ensure(clip: String) -> void:
	if _anim.current_animation != clip:
		_anim.play(clip, ANIM_BLEND)


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
	# Corpse: no longer hittable or blocking; despawns after the death
	# presentation has had time to play out.
	collision_layer = 0
	collision_mask = 1
	_death_visual()
	# process_always=false so a paused game doesn't despawn corpses.
	get_tree().create_timer(1.75, false).timeout.connect(queue_free)


## Death presentation: a death clip for skinned models, the topple tween
## for box models.
func _death_visual() -> void:
	if _anim != null:
		_anim.play("Death_A", ANIM_BLEND)
		return
	var tween := create_tween()
	tween.tween_property(visual, "rotation:x", -PI / 2.0, 0.35) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func _face_player(delta: float) -> void:
	if _player == null:
		return
	var to := _player.global_position - global_position
	var target_yaw := atan2(-to.x, -to.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, minf(turn_speed * delta, 1.0))


## Counts down _strafe_timer and flips _strafe_dir on expiry, picking a new
## random interval in [min_interval, max_interval]. Subclasses that circle
## the player while attacking call this each tick with their own interval.
func _update_strafe(delta: float, min_interval: float, max_interval: float) -> void:
	_strafe_timer -= delta
	if _strafe_timer <= 0.0:
		_strafe_timer = randf_range(min_interval, max_interval)
		_strafe_dir = -_strafe_dir


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
