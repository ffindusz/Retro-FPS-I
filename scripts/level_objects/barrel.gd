class_name ExplosiveBarrel
extends StaticBody3D
## Classic red barrel: any weapon hit pops it, dealing radial splash to
## players, enemies, AND other barrels (same collision layer), so clusters
## chain-react. A short random fuse makes chains ripple instead of firing
## on the same frame. Sits on the enemy layer so hitscan/rockets hit it.

const EXPLOSION_SOUND := preload("res://assets/audio/barrel_boom.wav")

## Bit values: 2 = player, 4 = enemies + barrels.
const SPLASH_MASK := 0b110

@export var health := 10.0
@export var splash_damage := 45.0
@export var splash_radius := 3.5

var _primed := false


func take_damage(amount: float, _from: Vector3 = Vector3.ZERO) -> void:
	if _primed:
		return
	health -= amount
	if health <= 0.0:
		_primed = true
		# process_always=false so a paused game doesn't cook off barrels.
		get_tree().create_timer(randf_range(0.06, 0.18), false).timeout.connect(_explode)


func _explode() -> void:
	Fx.spawn(self, global_position + Vector3(0, 0.6, 0), Color(1.0, 0.55, 0.15), 1.6, 0.25)
	Fx.spawn_sound(self, global_position, EXPLOSION_SOUND, 5.0)
	var query := PhysicsShapeQueryParameters3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = splash_radius
	query.shape = sphere
	query.transform = Transform3D(Basis(), global_position)
	query.collision_mask = SPLASH_MASK
	query.exclude = [get_rid()]
	for hit in get_world_3d().direct_space_state.intersect_shape(query, 16):
		var body: Object = hit.collider
		if body is Node3D and body.has_method("take_damage"):
			var dist: float = global_position.distance_to((body as Node3D).global_position)
			var falloff := clampf(1.0 - dist / splash_radius, 0.2, 1.0)
			body.take_damage(splash_damage * falloff, global_position)
	queue_free()
