extends Area3D
## The treasure at the end of the campaign: a gold-filled chest. Touching it
## flings the lid open and powers the two portals flanking it -- one back to
## level 1 a loop deeper, one to the monument. Claiming it no longer ends the
## game by itself; which portal you step into decides how the run finishes.

## The pads this chest powers. Wired in the level file rather than found by
## name, so the connection is visible where the pads are placed.
@export var pads: Array[NodePath] = []

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
	for path in pads:
		var pad := get_node_or_null(path) as Teleporter
		if pad != null:
			pad.activate()
	GameState.announce("THE TREASURE IS YOURS")
