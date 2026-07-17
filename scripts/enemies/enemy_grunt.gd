extends EnemyBase
## Melee grunt: skeleton minion model (assets/models/skeleton_minion),
## animation-driven on top of the base FSM — Idle/Running loops per state,
## a punch on each swing, and Death_A instead of the base topple.

const PUNCH_CLIP := "Unarmed_Melee_Attack_Punch_A"
## The punch clip runs 1.5s but attack_interval is 1.1s: sped up so each
## swing finishes before the next one starts.
const PUNCH_SPEED := 1.5
const BLEND := 0.15

@onready var _anim: AnimationPlayer = $Visual/Model/AnimationPlayer


func _process(_delta: float) -> void:
	match state:
		State.DEAD:
			pass  # _death_visual() played the death clip; hold the pose.
		State.CHASE:
			_ensure("Running_A")
		State.ATTACK:
			# Between swings, hold the combat stance; never interrupt a punch
			# that is still playing.
			if _anim.current_animation != PUNCH_CLIP or not _anim.is_playing():
				_ensure("Idle_Combat")
		_:
			_ensure("Idle")


func _do_attack() -> void:
	super()
	_anim.play(PUNCH_CLIP, BLEND, PUNCH_SPEED)


func _death_visual() -> void:
	_anim.play("Death_A", BLEND)


func _ensure(clip: String) -> void:
	if _anim.current_animation != clip:
		_anim.play(clip, BLEND)
