extends "res://tools/test_base.gd"
## Debug helper: treasure/score check in level 5 (the gold stash nook).
## - the level's gold total is counted (5 gems)
## - stepping onto a gem collects it: score climbs, per-level tally climbs,
##   the gem frees, and stats_line reports GOLD
## - gold always collects (no "already full" refusal like health/ammo)
##   Godot_v4.7-stable_win64_console.exe --headless --path . -s tools/test_gold.gd

const GEM1 := Vector3(-27.3, 0.3, 3.2)   # GoldNook1
const GEM2 := Vector3(-27.6, 0.3, 4.6)   # GoldNook2


func _boot_level_index() -> int:
	return 4  # level_05


func _tick(_delta: float) -> bool:
	var world := current_scene.get_node(WORLD_PATH)
	var player: CharacterBody3D = world.get_node_or_null("Player")
	var gs: Node = root.get_node(GAME_STATE_PATH)
	match _step:
		0:
			print("level 5 gold total: total_gold=%d score=%d (expect 5 0)"
					% [gs.total_gold, gs.score])
			player.global_position = GEM1
			player.velocity = Vector3.ZERO
			_next(400)
		1:
			print("after 1 gem: score=%d gold_found=%d (expect 100 1)"
					% [gs.score, gs.gold_found])
			print("gem freed: %s (expect true)"
					% (world.get_node_or_null("Level05/Pickups/GoldNook1") == null))
			player.global_position = GEM2
			player.velocity = Vector3.ZERO
			_next(400)
		2:
			print("after 2 gems: score=%d gold_found=%d/%d (expect 200 2/5)"
					% [gs.score, gs.gold_found, gs.total_gold])
			print("stats_line: %s" % gs.stats_line())
			print("gold test done")
			return true
	return false
