extends "res://tools/test_base.gd"
## Debug helper: every level's treasure total. Boots each campaign level in
## turn and checks GameState.total_gold (loose gems + shootable chests, all in
## the "gold" group counted by main.gd) matches the intended layout -- which
## also confirms every level still loads with the added pickups.
##   Godot_v4.7-stable_win64_console.exe --headless --path . -s tools/test_treasure.gd

# Per level 1..7: nook/vault gems + chests. Level 5 is the showcase (10).
const EXPECTED := [3, 3, 3, 3, 10, 4, 3]

var _lvl := 0
var _loaded := false


func _skip_auto_start() -> bool:
	return true  # drive start_game per level ourselves


func _tick(_delta: float) -> bool:
	var gs: Node = root.get_node(GAME_STATE_PATH)
	if not _loaded:
		current_scene.start_game(_lvl)
		_loaded = true
		_next(300)
		return false
	print("level %d gold total: total_gold=%d (expect %d)"
			% [_lvl + 1, gs.total_gold, EXPECTED[_lvl]])
	_lvl += 1
	if _lvl >= EXPECTED.size():
		print("treasure test done")
		return true
	_loaded = false
	_next(300)
	return false
