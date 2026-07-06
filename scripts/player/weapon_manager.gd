class_name WeaponManager
extends Node3D
## Holds the weapon viewmodels under the player camera, handles switching
## (number keys + scroll wheel) and routes fire input to the active weapon.

signal weapon_changed(weapon: WeaponBase)

var _weapons: Array[WeaponBase] = []
var _current := 0
var _player: PhysicsBody3D

@onready var _camera: Camera3D = get_parent() as Camera3D


func _ready() -> void:
	_player = owner as PhysicsBody3D
	if _camera == null:
		push_error("WeaponManager expects its parent to be a Camera3D.")
	if _player == null:
		push_error("WeaponManager expects its owner to be a PhysicsBody3D.")
	for child in get_children():
		if child is WeaponBase:
			_weapons.append(child)
	if _weapons.is_empty():
		push_error("WeaponManager has no WeaponBase children.")
	else:
		_select(0)


func _unhandled_input(event: InputEvent) -> void:
	if _weapons.is_empty():
		return
	if event.is_action_pressed("weapon_1"):
		_select(0)
	elif event.is_action_pressed("weapon_2"):
		_select(1)
	elif event.is_action_pressed("weapon_3"):
		_select(2)
	elif event.is_action_pressed("weapon_4"):
		_select(3)
	elif event.is_action_pressed("weapon_next"):
		_select((_current + 1) % _weapons.size())
	elif event.is_action_pressed("weapon_prev"):
		_select((_current - 1 + _weapons.size()) % _weapons.size())


func _process(_delta: float) -> void:
	# Poll instead of input events so holding the button auto-fires at each
	# weapon's own fire_interval. Ignore clicks while the mouse is freed.
	if _weapons.is_empty() or _camera == null or _player == null:
		return
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and Input.is_action_pressed("fire"):
		current_weapon().try_fire(_camera, _player)


func current_weapon() -> WeaponBase:
	if _weapons.is_empty():
		return null
	return _weapons[_current]


func add_ammo_for_type(type: Pickup.Type, amount: int) -> bool:
	for weapon in _weapons:
		if weapon.ammo_type == type:
			return weapon.add_ammo(amount)
	return false


func _select(index: int) -> void:
	if index < 0 or index >= _weapons.size():
		return
	_current = index
	for i in _weapons.size():
		_weapons[i].visible = i == index
	weapon_changed.emit(_weapons[index])
