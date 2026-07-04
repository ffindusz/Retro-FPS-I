extends Area3D
## Lava hazard: periodically burns anything standing in it — the player
## AND enemies (a grunt chasing you across the bridge can take the plunge).

@export var damage_per_tick := 8.0
@export var tick_interval := 0.4

var _cooldown := 0.0


func _physics_process(delta: float) -> void:
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	_cooldown = tick_interval
	for body in get_overlapping_bodies():
		if body.has_method("take_damage"):
			body.take_damage(damage_per_tick, global_position)
