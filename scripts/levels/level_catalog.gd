extends Resource
class_name LevelCatalog
## The campaign, as data instead of code.
##
## This used to be a hardcoded preload array in main.gd plus a TEST_STAGE_INDEX
## magic number -- duplicated again in start_screen.gd -- so adding or
## reordering a level meant editing several scripts and keeping the index
## arithmetic in sync by hand. Now it is a resource: drop a scene into the
## `levels` array in the Inspector and it is part of the campaign.
##
## Indices run over `levels` first and then `extras`, so index 0..N-1 are the
## campaign in play order and N onwards are the cheat-only stages. Keeping them
## in one index space is what lets the warp keys, main.gd's start_game() and
## the headless tools all keep addressing levels by a single number.

## Campaign levels, in play order. The teleporter walks this list.
@export var levels: Array[PackedScene] = []

## Reachable only by cheat, never by finishing a level: the model test stage.
## Kept out of `levels` so _advance_level() cannot wander into it.
@export var extras: Array[PackedScene] = []


## Number of levels the campaign actually plays through; the upper bound for
## advancing. Replaces the old TEST_STAGE_INDEX constant.
func campaign_count() -> int:
	return levels.size()


func total_count() -> int:
	return levels.size() + extras.size()


func scene_at(index: int) -> PackedScene:
	if index < 0 or index >= total_count():
		return null
	return levels[index] if index < levels.size() else extras[index - levels.size()]


func is_campaign(index: int) -> bool:
	return index >= 0 and index < levels.size()


## Maps a level scene's res:// path back to its index, for the standalone-run
## handoff in LevelRoot. Returns -1 when the scene is not in the catalog.
func index_of_path(path: String) -> int:
	for i in total_count():
		var scene := scene_at(i)
		if scene != null and scene.resource_path == path:
			return i
	return -1
