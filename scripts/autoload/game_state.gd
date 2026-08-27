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
## The treasure has been claimed and the two endgame portals are live: one
## back to level 1 a loop deeper, one to the monument.
signal new_loop_requested
signal monument_requested
signal announcement(text: String)
## Short, low-key notice for collecting an item (e.g. "+100 GOLD"), shown
## separately from the big announcement banner.
signal pickup_message(text: String)
signal teleport_flash

const MAX_HEALTH := 100
const HIGH_SCORE_PATH := "user://scores.cfg"
## How many best runs the monument engraves.
const RUN_TABLE_SIZE := 5
## Loops past this stop scaling. Beyond it the numbers stop being a fight and
## start being arithmetic, and a grunt with 500 health is not more interesting
## than one with 100.
const MAX_SCALED_LOOP := 5

var health: int = MAX_HEALTH

# Treasure score. Accumulates across the whole run: it survives level advances
# (which never call reset()) and only zeroes on a fresh start_game via reset().
# high_score is the saved all-time best, shown on the title and end screens.
var score := 0
var high_score := 0

## How many times the campaign has been finished on THIS run: 0 the first way
## through, 1 after taking the descend portal once. Session state, zeroed by
## reset() on a fresh start and deliberately not persisted -- only its
## high-water mark reaches disk, banked with each run in `runs`.
var loop := 0

## The monument's table: {"score": int, "loop": int}, best first, at most
## RUN_TABLE_SIZE entries.
var runs: Array[Dictionary] = []

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
	var paid := int(round(value * gold_scale()))
	score += paid
	score_changed.emit(score)
	pickup_message.emit("+%d GOLD" % paid)


## Emits a pickup notice; health/ammo pickups call this (gold goes through
## collect_gold, which emits its own).
func notify_pickup(text: String) -> void:
	pickup_message.emit(text)


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
	loop = 0


## Restores the loadout for the next loop without touching score or `loop`;
## main calls this instead of reset() when the descend portal is taken.
func reset_loadout() -> void:
	health = MAX_HEALTH
	health_changed.emit(health, MAX_HEALTH)


# --- New Game+ scaling ----------------------------------------------------
#
# Every one of these is EXACTLY 1.0 at loop 0, so the first way through the
# campaign plays on the hand-tuned numbers and none of the existing tests
# move. They only bite once a portal has been taken.

func _scaled_loop() -> float:
	return float(mini(loop, MAX_SCALED_LOOP))


func enemy_health_scale() -> float:
	return 1.0 + 0.35 * _scaled_loop()


func enemy_damage_scale() -> float:
	return 1.0 + 0.25 * _scaled_loop()


func gold_scale() -> float:
	return 1.0 + 0.5 * _scaled_loop()


## Fires the descend portal: main bumps `loop` and restarts the campaign with
## the run's score intact.
func begin_new_loop() -> void:
	new_loop_requested.emit()


## Fires the monument portal: main banks the run and loads the monument.
func enter_monument() -> void:
	monument_requested.emit()


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


## Banks the run into the monument table and, if it beat it, as the new best.
## Persists both. Returns true when a new record was set (for the end screen's
## "NEW BEST!"), which is why the beat-the-best check happens before
## high_score moves.
func finalize_run() -> bool:
	var record := score > high_score
	# A run that found nothing is not worth carving. This also keeps the
	# headless tests -- which reach the end screen with an empty purse -- from
	# filling the table with zeroes.
	if score > 0:
		_insert_run(score, loop)
	if record:
		high_score = score
	_save_high_score()
	return record


## Adds one run and keeps the table best-first and bounded. Ties break toward
## the deeper loop, so reaching loop 2 outranks the same score at loop 1.
func _insert_run(run_score: int, run_loop: int) -> void:
	runs.append({"score": run_score, "loop": run_loop})
	runs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			if int(a["score"]) != int(b["score"]):
				return int(a["score"]) > int(b["score"])
			return int(a["loop"]) > int(b["loop"]))
	runs.resize(mini(runs.size(), RUN_TABLE_SIZE))


func _load_high_score() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(HIGH_SCORE_PATH) != OK:
		return
	high_score = maxi(int(cfg.get_value("score", "best", 0)), 0)
	runs = []
	for entry: Variant in cfg.get_value("runs", "entries", []):
		if entry is Dictionary and entry.has("score"):
			runs.append({
				"score": maxi(int(entry["score"]), 0),
				"loop": maxi(int(entry.get("loop", 0)), 0),
			})
	# Migration: a file written before the table existed has only [score]best.
	# Seed the table from it so an existing personal best is not thrown away
	# the first time the monument is opened.
	if runs.is_empty() and high_score > 0:
		runs.append({"score": high_score, "loop": 0})


## Writes the table AND the legacy [score]best int. The old key costs one line
## and means a build from before the table still reads the right best score.
func _save_high_score() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("score", "best", high_score)
	cfg.set_value("runs", "entries", runs)
	cfg.save(HIGH_SCORE_PATH)
