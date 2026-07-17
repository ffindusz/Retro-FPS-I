extends EnemyBase
## Ranged skirmisher: skeleton mage model. Spits plasma bolts from range and
## backpedals when the player closes in — the opposite pressure to the melee
## grunt. Strafes between shots like the boss, but fragile. Channels the
## Spellcasting loop while skirmishing, with a cast one-shot per bolt.

const PLASMA := preload("res://scenes/weapons/projectile_plasma.tscn")
const CAST_CLIP := "Spellcast_Shoot"

## Below this distance the spitter retreats while still firing.
@export var preferred_range := 6.0


func _ready() -> void:
	super()
	_clip_attack_hold = "Spellcasting"


func _tick_attack(delta: float) -> void:
	_face_player(delta)
	_attack_timer -= delta
	_update_strafe(delta, 1.0, 2.0)
	if _distance_to_player() > attack_range * 1.2 or not _can_see_player():
		_enter(State.CHASE)
		return
	var to := _player.global_position - global_position
	to.y = 0.0
	var dir := to.normalized()
	var move := dir.cross(Vector3.UP) * _strafe_dir * move_speed * 0.4
	if to.length() < preferred_range:
		move += -dir * move_speed * 0.8
	velocity.x = move.x
	velocity.z = move.z
	if _attack_timer <= 0.0:
		_attack_timer = attack_interval
		_do_attack()


func _do_attack() -> void:
	if _player == null:
		return
	_play_one_shot(CAST_CLIP)
	var from := global_position + Vector3(0, 1.0, 0) - global_basis.z * 0.5
	Fx.spawn_sound(self, from, CAST_SOUND, -4.0)
	var aim := (_player.global_position + Vector3(0, 0.9, 0) - from).normalized()
	var bolt: Node3D = PLASMA.instantiate()
	get_parent().add_child(bolt)
	bolt.global_position = from
	bolt.setup(aim, self)
