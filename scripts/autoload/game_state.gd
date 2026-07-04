extends Node
## Autoload singleton holding global game state (player health, win/lose
## routing). Expanded across phases; Phase 0 defines the core containers.

signal health_changed(current: int, max_health: int)
signal player_died
signal boss_died
signal level_completed
signal game_won
signal announcement(text: String)

const MAX_HEALTH := 100

var health: int = MAX_HEALTH


func reset() -> void:
	health = MAX_HEALTH
	health_changed.emit(health, MAX_HEALTH)


func boss_defeated() -> void:
	boss_died.emit()


func complete_level() -> void:
	level_completed.emit()


func win_game() -> void:
	game_won.emit()


func announce(text: String) -> void:
	announcement.emit(text)


func heal(amount: int) -> bool:
	# False when already full (or dead) so pickups can refuse collection.
	if health >= MAX_HEALTH or health <= 0:
		return false
	health = mini(health + amount, MAX_HEALTH)
	health_changed.emit(health, MAX_HEALTH)
	return true


func damage_player(amount: int) -> void:
	if health <= 0:
		return
	health = maxi(health - amount, 0)
	health_changed.emit(health, MAX_HEALTH)
	if health == 0:
		player_died.emit()
