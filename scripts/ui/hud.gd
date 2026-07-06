extends Control
## In-game HUD: health, current weapon + ammo, crosshair, damage flash.
## Weapon info is polled each frame — cheap, and immune to weapon switches.

var _weapon_manager: WeaponManager
var _last_health := GameState.MAX_HEALTH
var _banner_tween: Tween

@onready var _health: Label = %HealthLabel
@onready var _weapon: Label = %WeaponLabel
@onready var _ammo: Label = %AmmoLabel
@onready var _flash: ColorRect = %DamageFlash
@onready var _banner: Label = %BannerLabel


func _ready() -> void:
	GameState.health_changed.connect(_on_health_changed)
	GameState.announcement.connect(show_banner)


## Fading top-center message: level names, "TELEPORTER ONLINE", etc.
func show_banner(text: String) -> void:
	if _banner_tween and _banner_tween.is_valid():
		_banner_tween.kill()
	_banner.text = text
	_banner.modulate.a = 1.0
	_banner_tween = create_tween()
	_banner_tween.tween_interval(1.8)
	_banner_tween.tween_property(_banner, "modulate:a", 0.0, 0.8)


func bind_player(player: PlayerController) -> void:
	_weapon_manager = player.weapon_manager
	_last_health = GameState.health
	_health.text = "HP %d" % GameState.health


func _process(delta: float) -> void:
	if _weapon_manager and is_instance_valid(_weapon_manager):
		var weapon: WeaponBase = _weapon_manager.current_weapon()
		if weapon:
			_weapon.text = weapon.weapon_label
			_ammo.text = str(weapon.ammo)
	_flash.modulate.a = maxf(_flash.modulate.a - delta * 1.8, 0.0)


func _on_health_changed(current: int, _max_health: int) -> void:
	if current < _last_health:
		_flash.modulate.a = 0.5
	_last_health = current
	_health.text = "HP %d" % current
