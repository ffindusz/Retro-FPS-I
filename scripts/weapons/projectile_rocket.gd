class_name RocketProjectile
extends Area3D
## Straight-flying rocket. Detonates on contact (world or enemy) with
## direct damage plus radial splash. Splash can hurt the shooter too —
## classic rocket-jump-adjacent danger.

@export var speed := 18.0
@export var direct_damage := 60.0
@export var splash_damage := 50.0
@export var splash_radius := 4.0
@export var lifetime := 6.0

## Bit values: 2 = player, 4 = enemies.
const SPLASH_MASK := 0b110

var _dir := Vector3.FORWARD
var _shooter: PhysicsBody3D
var _exploded := false


func setup(dir: Vector3, shooter: PhysicsBody3D) -> void:
	_dir = dir.normalized()
	_shooter = shooter
	var up := Vector3.UP if absf(_dir.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	look_at(global_position + _dir, up)


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	global_position += _dir * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		_explode(null)


func _on_body_entered(body: Node) -> void:
	if body == _shooter:
		return
	if body.has_method("take_damage"):
		body.take_damage(direct_damage, global_position)
	_explode(body)


func _explode(direct_hit: Node) -> void:
	if _exploded:
		return
	_exploded = true
	Fx.spawn(self, global_position, Color(1.0, 0.55, 0.15), 1.4, 0.22)
	var q := PhysicsShapeQueryParameters3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = splash_radius
	q.shape = sphere
	q.transform = Transform3D(Basis(), global_position)
	q.collision_mask = SPLASH_MASK
	var results := get_world_3d().direct_space_state.intersect_shape(q, 16)
	for r in results:
		var body: Object = r.collider
		if body == direct_hit or not body is Node3D:
			continue
		if body.has_method("take_damage"):
			var dist: float = global_position.distance_to((body as Node3D).global_position)
			var falloff := clampf(1.0 - dist / splash_radius, 0.15, 1.0)
			body.take_damage(splash_damage * falloff, global_position)
	queue_free()
