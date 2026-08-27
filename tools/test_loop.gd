extends "res://tools/test_base.gd"
## Debug helper: the endgame. Claiming the treasure in level 7 no longer wins
## outright -- it powers two portals, one back to level 1 a loop deeper and one
## to the monument.
## - loop 0 is IDENTITY: no scaling applies on the first way through
## - the chest powers both pads and does not end the game by itself
## - the descend pad bumps the loop, keeps the score, restores the loadout,
##   and level 1 comes back with scaled enemies and richer gold
## - the monument pad banks the run, engraves the slab, and any key closes out
##   on the existing win screen
## - the run table sorts/truncates, and a legacy best-only save migrates
##   Godot_v4.7-stable_win64_console.exe --headless --path . -s tools/test_loop.gd
##
## Banking a run WRITES user://scores.cfg, the player's real save; test_base
## snapshots it on the way in and restores it in _finish().

const BASE_GRUNT_HEALTH := 40.0


func _boot_level_index() -> int:
	return 6  # level 7, where the treasure is


func _count_score(runs: Array, score: int) -> int:
	var n := 0
	for run: Dictionary in runs:
		if int(run["score"]) == score:
			n += 1
	return n


func _tick(_delta: float) -> bool:
	var world := current_scene.get_node(WORLD_PATH)
	var gs := root.get_node(GAME_STATE_PATH)
	match _step:
		0:
			_next(700)
		1:
			var level := world.get_node_or_null("Level07")
			_expect_true("level 7 has both endgame pads",
					level != null and level.get_node_or_null("PadLoop") != null
					and level.get_node_or_null("PadMonument") != null)
			# The two pads sit side by side, so they must not look alike:
			# distinct portal colours and a sign naming each destination.
			var loop_pad: Node = level.get_node("PadLoop")
			var mon_pad: Node = level.get_node("PadMonument")
			_expect_true("the pads are different colours",
					loop_pad.portal_color != mon_pad.portal_color)
			var loop_sign := level.get_node_or_null("SignLoop") as Label3D
			var mon_sign := level.get_node_or_null("SignMonument") as Label3D
			_expect_true("the descend pad is signed",
					loop_sign != null and loop_sign.text.contains("DESCEND"))
			_expect_true("the monument pad is signed",
					mon_sign != null and mon_sign.text.contains("MONUMENT"))
			_expect("run starts at loop 0", gs.loop, 0)
			_expect_near("loop 0 leaves gold alone", gs.gold_scale(), 1.0)
			_expect_near("loop 0 leaves enemy health alone",
					gs.enemy_health_scale(), 1.0)
			_expect_near("loop 0 leaves enemy damage alone",
					gs.enemy_damage_scale(), 1.0)
			_claim_treasure(world)
			_next(700)
		2:
			var level := world.get_node("Level07")
			_expect_true("the chest powers the descend pad",
					level.get_node("PadLoop")._active)
			_expect_true("the chest powers the monument pad",
					level.get_node("PadMonument")._active)
			_expect_false("the chest alone does not end the game",
					current_scene.get_node("EndScreen").visible)
			gs.score = 4900
			gs.health = 30
			_step_onto(world, Vector3(-1.8, 0.3, -29.6))
			_next(1500)
		3:
			_expect("descend pad bumped the loop", gs.loop, 1)
			_expect("the run's score survived the loop", gs.score, 4900)
			_expect("the loadout was restored", gs.health, 100)
			_expect_true("level 1 came back",
					world.get_node_or_null("Level01") != null)
			var grunt: Node = world.get_node("Level01/Enemies/Grunt1")
			_expect_near("loop 1 grunt is 1.35x tougher", grunt.health,
					BASE_GRUNT_HEALTH * 1.35, 0.1)
			var before: int = gs.score
			gs.collect_gold(100)
			_expect("loop 1 gold pays 1.5x", gs.score - before, 150)
			_check_table(gs)
			_check_migration(gs)
			# Back to level 7 on a clean run for the other pad.
			current_scene.start_game(6)
			_next(800)
		4:
			_expect("a fresh start clears the loop", gs.loop, 0)
			gs.score = 7250
			_claim_treasure(world)
			_next(700)
		5:
			_step_onto(world, Vector3(1.8, 0.3, -29.6))
			_next(1500)
		6:
			_expect_true("monument loaded",
					world.get_node_or_null("LevelMonument") != null)
			_expect("the run was banked once",
					_count_score(gs.runs, 7250), 1)
			var face: Label3D = world.get_node("LevelMonument/Monolith/Face")
			_expect_true("the slab is engraved with the run",
					face.text.contains("7250"))
			_expect_false("the monument holds the win screen back",
					current_scene.get_node("EndScreen").visible)
			_key(KEY_SPACE)
			_next(600)
		7:
			_expect_true("any key closes out on the win screen",
					current_scene.get_node("EndScreen").visible)
			_expect("leaving the monument did not bank the run twice",
					_count_score(gs.runs, 7250), 1)
			return _finish()
	return false


func _claim_treasure(world: Node) -> void:
	_step_onto(world, Vector3(0, 0.3, -28))


func _step_onto(world: Node, at: Vector3) -> void:
	var player: CharacterBody3D = world.get_node("Player")
	player.global_position = at
	player.velocity = Vector3.ZERO


## Six runs in, best five out, ordered; ties break toward the deeper loop.
func _check_table(gs: Node) -> void:
	var keep: Array[Dictionary] = gs.runs.duplicate()
	gs.runs = [] as Array[Dictionary]
	for entry in [[100, 0], [900, 0], [500, 1], [900, 2], [50, 0], [700, 0]]:
		gs._insert_run(entry[0], entry[1])
	_expect("table keeps five", gs.runs.size(), 5)
	var scores := PackedInt32Array()
	for run: Dictionary in gs.runs:
		scores.append(int(run["score"]))
	_expect("table is best first", scores, PackedInt32Array([900, 900, 700, 500, 100]))
	_expect("ties break toward the deeper loop", int(gs.runs[0]["loop"]), 2)
	gs.runs = keep


## A save written before the table existed still yields its best score.
func _check_migration(gs: Node) -> void:
	var keep_runs: Array[Dictionary] = gs.runs.duplicate()
	var keep_best: int = gs.high_score
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_string("[score]\n\nbest=1234\n")
	f.close()
	gs.runs = [] as Array[Dictionary]
	gs.high_score = 0
	gs._load_high_score()
	_expect("legacy save still yields its best", gs.high_score, 1234)
	_expect("legacy best seeds the table", gs.runs.size(), 1)
	_expect("legacy best keeps its score", int(gs.runs[0]["score"]), 1234)
	gs.runs = keep_runs
	gs.high_score = keep_best
