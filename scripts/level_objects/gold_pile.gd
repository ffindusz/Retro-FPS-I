extends Area3D
## The treasure at the end of the campaign: a gold-filled chest. Touching
## it flings the lid open and wins the game (the end screen arrives after
## main.gd's one-second savor beat, so the opening plays out on screen).

var _claimed := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if _claimed or not body.is_in_group("player"):
		return
	_claimed = true
	# The imported lid mesh pivots at its back edge; negative X swings it
	# up and away from the player entering through the door.
	var lid: MeshInstance3D = find_child("chest_gold_lid", true, false)
	if lid != null:
		var tween := create_tween()
		tween.tween_property(lid, "rotation:x", -1.9, 0.45) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Fx.spawn(self, global_position + Vector3(0, 0.8, 0), Color(1.0, 0.85, 0.3), 1.6, 0.5)
	GameState.win_game()
