extends Area3D
## The treasure at the end of the campaign. Touching it wins the game.

var _claimed := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if _claimed or not body.is_in_group("player"):
		return
	_claimed = true
	Fx.spawn(self, global_position + Vector3(0, 0.8, 0), Color(1.0, 0.85, 0.3), 1.6, 0.5)
	GameState.win_game()
