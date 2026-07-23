extends StaticBody3D
## A gold chest you shoot open for a lump treasure reward. Sits on BOTH the
## world and enemy collision layers (like the rubble blockade): the enemy layer
## lets hitscan rays and rocket splash register hits via take_damage(), the
## world layer makes it solid. Joins the "gold" group so it counts as one
## treasure "find" in the level tally, alongside the loose gems. One hit flips
## the lid up, bursts coins, and banks the reward.

@export var value := 300
## Turn off in light-crowded rooms: the level is one CSG mesh and the mobile
## renderer drops omnis over its per-object limit, so an extra glow light there
## makes nearby lights flicker. The chest still reads by its gold model.
@export var glow := true

const COIN_SOUND := preload("res://assets/audio/coin.wav")

var _opened := false


func _ready() -> void:
	add_to_group("gold")
	$Glow.visible = glow


func take_damage(_amount: float, _from: Vector3 = Vector3.ZERO) -> void:
	if _opened:
		return
	_opened = true
	# The imported lid mesh pivots at its back edge; negative X tips it open.
	var lid: MeshInstance3D = find_child("chest_gold_lid", true, false)
	if lid != null:
		var tween := create_tween()
		tween.tween_property(lid, "rotation:x", -1.9, 0.4) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Fx.spawn(self, global_position + Vector3(0, 0.9, 0), Color(1.0, 0.82, 0.3), 1.3, 0.45)
	Fx.spawn_sound(self, global_position, COIN_SOUND, 3.0)
	GameState.collect_gold(value)
	GameState.announce("TREASURE!")
