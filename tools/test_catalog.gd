extends SceneTree
## Checks assets/level_catalog.tres, which replaced the hardcoded preload
## array and TEST_STAGE_INDEX in main.gd. The index space is load-bearing:
## main.gd, the warp cheat, the title-screen digits, LevelRoot's standalone
## handoff and every headless tool address levels by a single number, so a
## reorder that silently shifts it would break all of them at once.
##
## Run headless (no game boot needed, this only loads the resource):
##   Godot_v4.7-stable_win64_console.exe --headless --path . -s tools/test_catalog.gd

const CATALOG_PATH := "res://assets/level_catalog.tres"
const FIRST_LEVEL := "res://scenes/levels/level_01.tscn"
const LAST_LEVEL := "res://scenes/levels/level_07.tscn"
const TEST_STAGE := "res://scenes/levels/level_test.tscn"

var _ok := true


func _initialize() -> void:
	var catalog: Resource = load(CATALOG_PATH)
	if catalog == null:
		print("CATALOG TEST: FAIL (could not load %s)" % CATALOG_PATH)
		quit(1)
		return

	var campaign: int = catalog.campaign_count()
	var total: int = catalog.total_count()
	_check("campaign levels", campaign, 7)
	_check("total entries", total, 8)

	# The campaign must come first and be contiguous, or the teleporter walks
	# into an extra stage.
	_check("first campaign scene", catalog.scene_at(0).resource_path, FIRST_LEVEL)
	_check("last campaign scene", catalog.scene_at(campaign - 1).resource_path, LAST_LEVEL)
	_check("is_campaign(last)", catalog.is_campaign(campaign - 1), true)
	_check("is_campaign(first extra)", catalog.is_campaign(campaign), false)
	_check("first extra is the test stage",
			catalog.scene_at(campaign).resource_path, TEST_STAGE)

	# Round trip: what LevelRoot relies on for a standalone (F6) run.
	for i in total:
		var path: String = catalog.scene_at(i).resource_path
		_check("index_of_path round trip [%d]" % i, catalog.index_of_path(path), i)
	_check("unknown path", catalog.index_of_path("res://scenes/levels/nope.tscn"), -1)

	# Out of range must be null, not a crash or a wrapped index.
	_check("scene_at(-1)", catalog.scene_at(-1), null)
	_check("scene_at(total)", catalog.scene_at(total), null)

	print("CATALOG TEST: %s" % ["PASS" if _ok else "FAIL"])
	quit(0 if _ok else 1)


func _check(label: String, got: Variant, want: Variant) -> void:
	var hit: bool = got == want
	if not hit:
		_ok = false
	print("%s: %s (expect %s)%s" % [label, got, want, "" if hit else "  <-- MISMATCH"])


func _process(_delta: float) -> bool:
	return true
