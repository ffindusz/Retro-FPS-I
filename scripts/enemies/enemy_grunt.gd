extends EnemyBase
## Melee grunt: skeleton minion model, driven by the base animation driver —
## combat stance between swings, a sped-up punch per attack.

const PUNCH_CLIP := "Unarmed_Melee_Attack_Punch_A"
## The punch clip runs 1.5s but attack_interval is 1.1s: sped up so each
## swing finishes before the next one starts.
const PUNCH_SPEED := 1.5


func _ready() -> void:
	super()
	_clip_attack_hold = "Idle_Combat"


func _do_attack() -> void:
	super()
	_play_one_shot(PUNCH_CLIP, PUNCH_SPEED)
