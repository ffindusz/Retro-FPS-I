class_name WeaponBase
extends Node3D
## Base class for viewmodel weapons. Default fire behavior is hitscan with
## optional multi-pellet spread; subclasses override _fire() for projectiles.

signal fired
signal ammo_changed(ammo: int)

@export var weapon_label := "WEAPON"
@export var ammo_type: Pickup.Type = Pickup.Type.BULLETS
@export var damage := 10.0
@export var fire_interval := 0.2
@export var max_ammo := 50
@export var pellet_count := 1
@export var spread_degrees := 0.0
@export var hitscan_range := 100.0
@export var projectile_scene: PackedScene

## Bit values: 1 = world geometry, 4 = enemies.
const HITSCAN_MASK := 0b101

var ammo: int
var _cooldown := 0.0
var _kick := 0.0
var _rest_position: Vector3

@onready var _muzzle_flash: Node3D = get_node_or_null("MuzzleFlash")
@onready var _shot_sound: AudioStreamPlayer = get_node_or_null("ShotSound")
@onready var _click_sound: AudioStreamPlayer = get_node_or_null("ClickSound")


func _ready() -> void:
	ammo = max_ammo
	_rest_position = position
	if _muzzle_flash:
		_muzzle_flash.visible = false


func _process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	# Recoil: viewmodel kicks toward the camera, then eases back to rest.
	_kick = lerpf(_kick, 0.0, minf(delta * 12.0, 1.0))
	position = _rest_position + Vector3(0.0, 0.0, _kick)


func add_ammo(pickup_amount: int) -> bool:
	# False when already full so ammo pickups can refuse collection.
	if ammo >= max_ammo:
		return false
	ammo = mini(ammo + pickup_amount, max_ammo)
	ammo_changed.emit(ammo)
	return true


func try_fire(camera: Camera3D, shooter: PhysicsBody3D) -> bool:
	if _cooldown > 0.0:
		return false
	if ammo <= 0:
		# Dry fire: click at most a few times a second while held.
		_cooldown = 0.3
		if _click_sound:
			_click_sound.play()
		return false
	ammo -= 1
	_cooldown = fire_interval
	_kick = 0.08
	if _shot_sound:
		_shot_sound.play()
	_show_muzzle_flash()
	_fire(camera, shooter)
	fired.emit()
	ammo_changed.emit(ammo)
	return true


func _fire(camera: Camera3D, shooter: PhysicsBody3D) -> void:
	var space := camera.get_world_3d().direct_space_state
	for i in pellet_count:
		var dir := -camera.global_basis.z
		if spread_degrees > 0.0:
			dir = dir.rotated(camera.global_basis.x.normalized(),
					deg_to_rad(randf_range(-spread_degrees, spread_degrees)))
			dir = dir.rotated(camera.global_basis.y.normalized(),
					deg_to_rad(randf_range(-spread_degrees, spread_degrees)))
		var from := camera.global_position
		var query := PhysicsRayQueryParameters3D.create(
				from, from + dir * hitscan_range, HITSCAN_MASK, [shooter.get_rid()])
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			continue
		if hit.collider.has_method("take_damage"):
			hit.collider.take_damage(damage, hit.position)
			Fx.spawn(self, hit.position, Color(1.0, 0.35, 0.25), 0.25)
		else:
			Fx.spawn(self, hit.position + hit.normal * 0.05, Color(1.0, 0.85, 0.45), 0.16)


func _show_muzzle_flash() -> void:
	if _muzzle_flash == null:
		return
	_muzzle_flash.visible = true
	get_tree().create_timer(0.06).timeout.connect(func() -> void:
		if is_instance_valid(_muzzle_flash):
			_muzzle_flash.visible = false)
