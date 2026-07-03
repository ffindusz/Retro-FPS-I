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
