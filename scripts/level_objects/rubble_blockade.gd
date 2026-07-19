extends StaticBody3D
## Blastable rubble heap sealing a passage (the dungeon's secret nook).
## Sits on BOTH the world and enemy collision layers: the enemy layer lets
## hitscan rays and rocket splash register hits via take_damage(), while the
## world layer makes it genuinely solid — enemy bolts burst on it instead of
## sailing through, it blocks enemy line of sight, and it occludes splash.
## Pistol shots chip it down; one rocket blows it open in one go.

@export var max_health := 60.0

const CRACK_SOUND := preload("res://assets/audio/bone_hit.wav")
const COLLAPSE_SOUND := preload("res://assets/audio/explosion.wav")
const DUST_COLOR := Color(0.62, 0.55, 0.45)

var _health: float

@onready var _visual: Node3D = $Visual


func _ready() -> void:
	_health = max_health


func take_damage(amount: float, from: Vector3 = Vector3.ZERO) -> void:
	if _health <= 0.0:
		return
	_health -= amount
	if _health <= 0.0:
		_collapse()
		return
	var at := from if from != Vector3.ZERO else global_position + Vector3(0, 1.2, 0)
	Fx.spawn(self, at, DUST_COLOR, 0.35)
	Fx.spawn_sound(self, at, CRACK_SOUND, -6.0, 0.6)
	# Same hit-pop the enemies use, so damage feedback reads consistently.
	_visual.scale = Vector3(1.06, 0.94, 1.06)
	var tween := create_tween()
	tween.tween_property(_visual, "scale", Vector3.ONE, 0.12)


func _collapse() -> void:
	# A row of dust bursts across the heap sells the cave-in.
	for offset in [Vector3(-1.1, 0.7, 0), Vector3(0, 1.3, 0), Vector3(1.1, 0.7, 0)]:
		Fx.spawn(self, global_position + global_basis * offset, DUST_COLOR, 0.9, 0.3)
	Fx.spawn_sound(self, global_position + Vector3(0, 1, 0), COLLAPSE_SOUND, -4.0, 0.8)
	queue_free()
