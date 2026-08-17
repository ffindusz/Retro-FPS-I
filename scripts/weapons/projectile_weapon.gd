extends WeaponBase
## Casting weapon (fire staff, tome): overrides _fire to spawn a projectile
## instead of hitscanning. Damage numbers live on the projectile scene itself.


func _fire(camera: Camera3D, shooter: PhysicsBody3D) -> void:
	var projectile: Node3D = projectile_scene.instantiate()
	# Parent to the game viewport so the projectile lives in the 3D world and
	# survives weapon switches.
	get_viewport().add_child(projectile)
	var dir := -camera.global_basis.z
	projectile.global_position = camera.global_position + dir * 0.8 \
			- camera.global_basis.y * 0.12
	projectile.setup(dir, shooter)
