extends Node
## Autoload singleton holding global game state (player health, treasure
## score, win/lose routing). Expanded across phases; Phase 0 defines the core
## containers.

signal health_changed(current: int, max_health: int)
signal score_changed(score: int)
signal player_died
signal boss_died
signal level_completed
signal game_won
signal announcement(text: String)
signal teleport_flash

const MAX_HEALTH := 100
const HIGH_SCORE_PATH := "user://scores.cfg"

var health: int = MAX_HEALTH

# Treasure score. Accumulates across the whole run: it survives level advances
# (which never call reset()) and only zeroes on a fresh start_game via reset().
# high_score is the saved all-time best, shown on the title and end screens.
var score := 0
var high_score := 0

# Per-level tallies for the intermission/end-screen stats line.
var kills := 0
var total_enemies := 0
var secrets_found := 0
var total_secrets := 0
var gold_found := 0
var total_gold := 0
var _level_time := 0.0


func _ready() -> void:
	_load_high_score()


func _process(delta: float) -> void:
	# Game-time level timer: _process pauses with the tree, so the pause menu
	# and intermission don't inflate the TIME stat (wall clock would).
	_level_time += delta


func begin_level_stats(enemy_count: int, secret_count: int, gold_count := 0) -> void:
	kills = 0
	secrets_found = 0
	gold_found = 0
	total_enemies = enemy_count
	total_secrets = secret_count
	total_gold = gold_count
	_level_time = 0.0


func enemy_killed() -> void:
	kills += 1


func secret_found() -> void:
	secrets_found += 1


## Gold is always collected (unlike health/ammo it never refuses on "full"):
## it adds to the run score and the per-level found tally.
func collect_gold(value: int) -> void:
	gold_found += 1
	score += value
	score_changed.emit(score)


func stats_line() -> String:
	var secs := int(_level_time)
	return "KILLS %d/%d   ·   SECRETS %d/%d   ·   GOLD %d/%d   ·   TIME %d:%02d" \
			% [kills, total_enemies, secrets_found, total_secrets,
			gold_found, total_gold, secs / 60, secs % 60]


func reset() -> void:
	health = MAX_HEALTH
	health_changed.emit(health, MAX_HEALTH)
	score = 0
	score_changed.emit(score)


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


## Banks the run's score as the new best if it beats it, persisting to disk.
## Returns true when a new record was set (for the end screen's "NEW BEST!").
func finalize_run() -> bool:
	if score <= high_score:
		return false
	high_score = score
	_save_high_score()
	return true


func _load_high_score() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(HIGH_SCORE_PATH) == OK:
		high_score = maxi(int(cfg.get_value("score", "best", 0)), 0)


func _save_high_score() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("score", "best", high_score)
	cfg.save(HIGH_SCORE_PATH)
