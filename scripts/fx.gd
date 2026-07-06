class_name Fx
extends Object
## Helper for short-lived flash effects (bullet impacts, explosions).
## Spawns an unshaded billboard quad + omni light that frees itself.


static func spawn(context: Node3D, pos: Vector3, color: Color, size: float, life := 0.08) -> void:
	var vp := context.get_viewport()
	if vp == null:
		return
	var fx := Node3D.new()
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 2.0
	light.omni_range = maxf(size * 8.0, 2.0)
	fx.add_child(light)
	var mesh := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(size, size)
	mesh.mesh = quad
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mesh.material_override = mat
	fx.add_child(mesh)
	vp.add_child(fx)
	fx.global_position = pos
	fx.get_tree().create_timer(life).timeout.connect(fx.queue_free)


## One-shot positional sound that outlives its emitter (e.g. exploding
## rockets, dying enemies).
static func spawn_sound(context: Node3D, pos: Vector3, stream: AudioStream,
		volume_db := 0.0) -> void:
	var vp := context.get_viewport()
	if vp == null:
		return
	var player := AudioStreamPlayer3D.new()
	player.stream = stream
	player.volume_db = volume_db
	player.max_distance = 60.0
	vp.add_child(player)
	player.global_position = pos
	player.play()
	player.finished.connect(player.queue_free)


## Radial explosion damage with linear falloff (full `damage` at the center,
## `falloff_min` fraction of it at the edge of `radius`). `skip_body` is
## excluded from the hit loop (e.g. a body that already took direct damage);
## `exclude_rids` is excluded at the physics-query level (e.g. the explosive
## itself, so it doesn't damage its own collider).
static func apply_splash_damage(context: Node3D, origin: Vector3, radius: float,
		damage: float, mask: int, falloff_min: float, skip_body: Object = null,
		exclude_rids: Array[RID] = []) -> void:
	var query := PhysicsShapeQueryParameters3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = radius
	query.shape = sphere
	query.transform = Transform3D(Basis(), origin)
	query.collision_mask = mask
	query.exclude = exclude_rids
	for hit in context.get_world_3d().direct_space_state.intersect_shape(query, 16):
		var body: Object = hit.collider
		if body == skip_body or not body is Node3D:
			continue
		if body.has_method("take_damage"):
			var dist: float = origin.distance_to((body as Node3D).global_position)
			var falloff := clampf(1.0 - dist / radius, falloff_min, 1.0)
			body.take_damage(damage * falloff, origin)
