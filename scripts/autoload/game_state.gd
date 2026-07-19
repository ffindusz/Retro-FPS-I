extends Node
## Autoload singleton holding global game state (player health, win/lose
## routing). Expanded across phases; Phase 0 defines the core containers.

signal health_changed(current: int, max_health: int)
signal player_died
signal boss_died
signal level_completed
signal game_won
signal announcement(text: String)
signal teleport_flash

const MAX_HEALTH := 100

var health: int = MAX_HEALTH

# Per-level tallies for the intermission/end-screen stats line.
var kills := 0
var total_enemies := 0
var secrets_found := 0
var total_secrets := 0
var _level_time := 0.0


func _process(delta: float) -> void:
	# Game-time level timer: _process pauses with the tree, so the pause menu
	# and intermission don't inflate the TIME stat (wall clock would).
	_level_time += delta


func begin_level_stats(enemy_count: int, secret_count: int) -> void:
	kills = 0
	secrets_found = 0
	total_enemies = enemy_count
	total_secrets = secret_count
	_level_time = 0.0


func enemy_killed() -> void:
	kills += 1


func secret_found() -> void:
	secrets_found += 1


func stats_line() -> String:
	var secs := int(_level_time)
	return "KILLS %d/%d   ·   SECRETS %d/%d   ·   TIME %d:%02d" \
			% [kills, total_enemies, secrets_found, total_secrets, secs / 60, secs % 60]


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


func flash_teleport() -> void:
	teleport_flash.emit()


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
