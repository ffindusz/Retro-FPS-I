extends EnemyBase
## Cloaking rogue: a fast dagger stalker. While chasing at range it shrouds
## itself — only a faint ghost and its footfall rattle remain — then drops
## the cloak inside decloak_range to strike (the tell). Damaging it rips the
## cloak away for reveal_time, so tagging the shimmer is rewarded. Unlike
## the other skeletons it lurks upright (standing dormant pose) and wakes
## fast.

const STAB_CLIP := "Dualwield_Melee_Attack_Stab"
## The stab clip runs 1.6s but attack_interval is 1.0s: sped up so each
## strike finishes before the next one starts.
const STAB_SPEED := 1.8
## Reused for the cloak shimmer: pitched way up it reads as a whisper of
## magic rather than the spitter's full cast.
const CLOAK_SOUND := preload("res://assets/audio/cast.wav")

## 0.94 leaves a barely-there ghost (readable up close, lost at range).
@export var cloak_transparency := 0.94
## Inside this range the rogue materializes to strike.
@export var decloak_range := 4.0
## How long taking a hit keeps the cloak suppressed.
@export var reveal_time := 2.5
## Shorter reveal after its own strike: it lands the blow, lingers a beat,
## then melts away again.
@export var strike_reveal_time := 1.0

var cloaked := false  # exposed for tests

## Game-time countdown (ticks in _physics_process, so pausing doesn't eat
## the reveal window the way a wall-clock deadline would).
var _reveal_timer := 0.0
var _meshes: Array[GeometryInstance3D] = []


func _ready() -> void:
	super()
	_clip_dormant = "Skeleton_Inactive_Standing_Pose"
	_clip_awaken = "Skeletons_Awaken_Standing"
	# The standing awaken runs 1.0s; paced to fit inside notice_delay.
	_awaken_speed = 1.0 / notice_delay
	_clip_attack_hold = "Idle_Combat"
	for mesh in visual.find_children("*", "MeshInstance3D", true, false):
		_meshes.append(mesh as GeometryInstance3D)


func _physics_process(delta: float) -> void:
	super(delta)
	_reveal_timer = maxf(_reveal_timer - delta, 0.0)
	_update_cloak()


func take_damage(amount: float, from: Vector3 = Vector3.ZERO) -> void:
	# Reveal before the base handler so the hit flash lands on a visible
	# body (and death never leaves an invisible corpse).
	_reveal(reveal_time)
	super(amount, from)


func _do_attack() -> void:
	super()
	_play_one_shot(STAB_CLIP, STAB_SPEED)
	_reveal(strike_reveal_time)


func _update_cloak() -> void:
	var want := state == State.CHASE \
			and _reveal_timer <= 0.0 \
			and _distance_to_player() > decloak_range
	if want != cloaked:
		_set_cloak(want)


func _reveal(secs: float) -> void:
	_reveal_timer = maxf(_reveal_timer, secs)
	if cloaked:
		_set_cloak(false)


func _set_cloak(on: bool) -> void:
	cloaked = on
	for mesh in _meshes:
		mesh.transparency = cloak_transparency if on else 0.0
	# A cold green-white flicker marks both edges of the cloak so the player
	# gets a position fix at the moment it (dis)appears.
	Fx.spawn(self, global_position + Vector3(0, 1.1, 0), Color(0.55, 0.9, 0.75), 0.45)
	Fx.spawn_sound(self, global_position + Vector3(0, 1.1, 0), CLOAK_SOUND,
			-10.0, 1.7 if on else 1.15)
