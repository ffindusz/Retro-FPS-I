extends StaticBody3D
## Slab sealing the secret room. Slides into the floor when the boss dies
## (collision moves with it, so the way genuinely opens).

const RUMBLE_SOUND := preload("res://assets/audio/explosion.wav")

@export var slide_distance := 4.0
@export var slide_time := 2.2

var _open := false


func _ready() -> void:
	GameState.boss_died.connect(_open_door)


func _open_door() -> void:
	if _open:
		return
	_open = true
	Fx.spawn_sound(self, global_position, RUMBLE_SOUND, 2.0)
	GameState.announce("SOMETHING OPENED...")
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - slide_distance, slide_time) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
