extends WeaponBase
## Rocket launcher: overrides _fire to spawn a projectile instead of
## hitscanning. Damage numbers live on the rocket scene itself.


func _fire(camera: Camera3D, shooter: PhysicsBody3D) -> void:
	var rocket: Node3D = projectile_scene.instantiate()
	# Parent to the game viewport so the rocket lives in the 3D world and
	# survives weapon switches.
	get_viewport().add_child(rocket)
	var dir := -camera.global_basis.z
	rocket.global_position = camera.global_position + dir * 0.8 - camera.global_basis.y * 0.12
	rocket.setup(dir, shooter)
