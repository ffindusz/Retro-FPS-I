extends Node
## Autoload singleton holding global game state (player health, win/lose
## routing). Expanded across phases; Phase 0 defines the core containers.

signal health_changed(current: int, max_health: int)
signal player_died
signal boss_died

const MAX_HEALTH := 100

var health: int = MAX_HEALTH


func reset() -> void:
	health = MAX_HEALTH
	health_changed.emit(health, MAX_HEALTH)


func damage_player(amount: int) -> void:
	if health <= 0:
		return
	health = maxi(health - amount, 0)
	health_changed.emit(health, MAX_HEALTH)
	if health == 0:
		player_died.emit()
