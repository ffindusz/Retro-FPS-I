extends Area3D
## Invisible trigger marking a secret spot. First time the player enters:
## chime + banner + counts toward the level's secret tally.

const FOUND_SOUND := preload("res://assets/audio/heal.wav")

var _found := false


func _ready() -> void:
	add_to_group("secret_areas")
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if _found or not body.is_in_group("player"):
		return
	_found = true
	GameState.secret_found()
	GameState.announce("SECRET FOUND!")
	Fx.spawn_sound(self, global_position, FOUND_SOUND, 4.0)
