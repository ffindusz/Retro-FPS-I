extends "res://tools/test_base.gd"
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


## Overrides the harness boot: this test only loads a resource, so it never
## changes scene and current_scene stays null. That also means the inherited
## _process would idle forever, hence the override below.
func _initialize() -> void:
	_snapshot_save()  # this test does not call super(); protect the save anyway
	var catalog: Resource = load(CATALOG_PATH)
	if catalog == null:
		_expect_true("catalog loads (%s)" % CATALOG_PATH, false)
		return

	var campaign: int = catalog.campaign_count()
	var total: int = catalog.total_count()
	_expect("campaign levels", campaign, 7)
	# 7 campaign + 2 extras: the model test stage and the endgame monument.
	_expect("total entries", total, 9)

	# The monument is reached by the portal beside the treasure, not by
	# playing forward, so it must be an extra that main can still address.
	var monument: int = catalog.monument_index()
	_expect_true("monument is registered", monument >= 0)
	_expect_false("monument is not part of the campaign",
			catalog.is_campaign(monument))

	# The campaign must come first and be contiguous, or the teleporter walks
	# into an extra stage.
	_expect("first campaign scene", catalog.scene_at(0).resource_path, FIRST_LEVEL)
	_expect("last campaign scene", catalog.scene_at(campaign - 1).resource_path,
			LAST_LEVEL)
	_expect_true("is_campaign(last)", catalog.is_campaign(campaign - 1))
	_expect_false("is_campaign(first extra)", catalog.is_campaign(campaign))
	_expect("first extra is the test stage",
			catalog.scene_at(campaign).resource_path, TEST_STAGE)

	# Round trip: what LevelRoot relies on for a standalone (F6) run.
	for i in total:
		var path: String = catalog.scene_at(i).resource_path
		_expect("index_of_path round trip [%d]" % i, catalog.index_of_path(path), i)
	_expect("unknown path", catalog.index_of_path("res://scenes/levels/nope.tscn"), -1)

	# Out of range must be null, not a crash or a wrapped index.
	_expect("scene_at(-1)", catalog.scene_at(-1), null)
	_expect("scene_at(total)", catalog.scene_at(total), null)


## Every check already ran in _initialize; report on the first frame. Reporting
## from _initialize instead would mean quitting before the tree starts running.
func _process(_delta: float) -> bool:
	return _finish()
