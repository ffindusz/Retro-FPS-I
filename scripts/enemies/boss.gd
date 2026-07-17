extends EnemyBase
## Boss: hulking skeleton warrior. Hurls fireball volleys from a distance
## and circle-strafes while attacking instead of standing still. At 50%
## health it enrages: faster movement, shorter attack interval, wider
## volleys, and an eye flare — the phase change.

const FIREBALL := preload("res://scenes/weapons/projectile_fireball.tscn")
const ROAR_SOUND := preload("res://assets/audio/boss_roar.wav")

## Throw clip is 1.4s; sped up so a volley windup fits inside even the
## enraged attack interval (1.7 * 0.55 = 0.94s).
const THROW_SPEED := 1.5

@export var volley_size := 3
@export var enraged_volley_size := 5
@export var volley_spread_degrees := 22.0

var _enraged := false
var _eyes_mat: ShaderMaterial


func _ready() -> void:
	super()
	_clip_attack_hold = "Walking_B"
	# The boss looms upright while dormant instead of lying on the floor.
	_clip_dormant = "Skeleton_Inactive_Standing_Pose"
	_clip_awaken = "Skeletons_Awaken_Standing"
	_awaken_speed = 1.4  # 1.0s clip into the 0.7s notice_delay
	# Per-instance override of the imported eye material so the enrage tint
	# can't leak into other users of the shared mesh resource (the test
	# stage display, future restarts).
	var eyes: MeshInstance3D = visual.find_child("*_Eyes", true, false)
	if eyes == null:
		push_error("Boss model has no *_Eyes mesh for the enrage flare.")
		return
	_eyes_mat = eyes.mesh.surface_get_material(0).duplicate()
	eyes.set_surface_override_material(0, _eyes_mat)


func take_damage(amount: float, from: Vector3 = Vector3.ZERO) -> void:
	var was_above_half := health > max_health * 0.5
	super.take_damage(amount, from)
	if was_above_half and health <= max_health * 0.5 and state != State.DEAD:
		_enrage()


## Unlike the base melee loop, the boss keeps circling the player between
## volleys and flips strafe direction on a timer.
func _tick_attack(delta: float) -> void:
	_face_player(delta)
	_attack_timer -= delta
	_update_strafe(delta, 1.2, 2.4)
	if _distance_to_player() > attack_range * 1.15 or not _can_see_player():
		_enter(State.CHASE)
		return
	var to := _player.global_position - global_position
	to.y = 0.0
	var tangent := to.normalized().cross(Vector3.UP) * _strafe_dir
	velocity.x = tangent.x * move_speed * 0.6
	velocity.z = tangent.z * move_speed * 0.6
	if _attack_timer <= 0.0:
		_attack_timer = attack_interval
		_do_attack()


func _do_attack() -> void:
	if _player == null:
		return
	_play_one_shot("Throw", THROW_SPEED)
	var count := enraged_volley_size if _enraged else volley_size
	var from := global_position + Vector3(0, 2.6, 0) - global_basis.z * 1.2
	# Same cast stream as the mage, but louder to match the volley.
	Fx.spawn_sound(self, from, CAST_SOUND, 2.0)
	var aim := (_player.global_position + Vector3(0, 0.9, 0) - from).normalized()
	for i in count:
		var t := 0.0 if count == 1 else float(i) / float(count - 1) - 0.5
		var dir := aim.rotated(Vector3.UP, deg_to_rad(volley_spread_degrees * t))
		var fireball: Node3D = FIREBALL.instantiate()
		get_parent().add_child(fireball)
		fireball.global_position = from
		fireball.setup(dir, self)


func _die() -> void:
	super()
	GameState.boss_defeated()


func _enrage() -> void:
	_enraged = true
	move_speed *= 1.5
	attack_interval *= 0.55
	if _eyes_mat != null:
		_eyes_mat.set_shader_parameter("albedo_color", Color(1.0, 0.9, 0.2))
	Fx.spawn_sound(self, global_position + Vector3(0, 2.5, 0), ROAR_SOUND, 4.0)
	Fx.spawn(self, global_position + Vector3(0, 2.8, 0), Color(1.0, 0.2, 0.6), 2.0, 0.35)
	visual.scale = Vector3(1.25, 0.85, 1.25)
	var tween := create_tween()
	tween.tween_property(visual, "scale", Vector3.ONE, 0.3)
