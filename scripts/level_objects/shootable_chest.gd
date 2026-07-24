extends StaticBody3D
## A gold chest you shoot open. Sits on BOTH the world and enemy collision
## layers (like the rubble blockade): the enemy layer lets hitscan rays and
## rocket splash register hits via take_damage(), the world layer makes it
## solid. One hit flips the lid up, bursts coins, and tosses a gold gem out --
## the reward only counts once the player walks over and picks that gem up.

@export var value := 300

const COIN_SOUND := preload("res://assets/audio/coin.wav")
const GOLD_PICKUP := preload("res://scenes/level_objects/pickup_gold.tscn")

var _opened := false


func _ready() -> void:
	add_to_group("gold")


func take_damage(_amount: float, hit_from: Vector3 = Vector3.ZERO) -> void:
	if _opened:
		return
	_opened = true
	# The treasure is now the gem that pops out, so the chest itself is no
	# longer a pending "find" -- that credit transfers to collecting the gem.
	remove_from_group("gold")
	# The imported lid mesh pivots at its back edge; negative X tips it open.
	var lid: MeshInstance3D = find_child("chest_gold_lid", true, false)
	if lid != null:
		var tween := create_tween()
		tween.tween_property(lid, "rotation:x", -1.9, 0.4) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Fx.spawn(self, global_position + Vector3(0, 0.9, 0), Color(1.0, 0.82, 0.3), 1.3, 0.45)
	Fx.spawn_sound(self, global_position, COIN_SOUND, 3.0)
	GameState.announce("TREASURE!")
	_pop_gold(hit_from)


## Spawns a single gold gem worth the chest's value and arcs it up out of the
## lid to land a short hop toward the shooter (open ground), where the player
## collects it like any other loose gem.
func _pop_gold(hit_from: Vector3) -> void:
	var gem := GOLD_PICKUP.instantiate() as Node3D
	gem.set("amount", value)
	get_parent().add_child(gem)
	var base := global_position
	gem.global_position = base + Vector3(0, 0.9, 0)  # start at the open lid
	# Toss toward whoever shot it (the open side); fall back to the chest front.
	var dir := hit_from - base
	dir.y = 0.0
	if dir.length() < 0.3:
		dir = global_transform.basis.z
	dir = dir.normalized()
	var land := base + dir * 1.0
	land.y = base.y + 0.4
	var apex := gem.global_position.lerp(land, 0.5) + Vector3(0, 0.7, 0)
	var tween := gem.create_tween()
	tween.tween_property(gem, "global_position", apex, 0.22) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(gem, "global_position", land, 0.3) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
