class_name SecretDoor
extends StaticBody3D
## Slab sealing a secret room. Slides into the floor when opened (collision
## moves with it, so the way genuinely opens). Opens either on its own when the
## boss dies (open_on_boss_death, the original campaign secret) or on demand via
## open() -- e.g. a SecretLever wired to this door.

const RUMBLE_SOUND := preload("res://assets/audio/explosion.wav")

@export var slide_distance := 4.0
@export var slide_time := 2.2
## When true the door opens the moment the boss dies. Lever-gated secret rooms
## set this false so only their lever opens them.
@export var open_on_boss_death := true

var _open := false


func _ready() -> void:
	if open_on_boss_death:
		GameState.boss_died.connect(open)


func open() -> void:
	if _open:
		return
	_open = true
	Fx.spawn_sound(self, global_position, RUMBLE_SOUND, 2.0)
	GameState.announce("SOMETHING OPENED...")
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - slide_distance, slide_time) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
