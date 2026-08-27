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

## Reachable only by cheat, never by finishing a level: the model test stage
## and the endgame monument. Kept out of `levels` so _advance_level() cannot
## wander into either.
@export var extras: Array[PackedScene] = []

## The monument reached by the portal beside the treasure. Must also appear in
## `extras`, which is what gives it an index; this field just names WHICH extra
## it is, so main does not have to guess at "the last one".
@export var monument: PackedScene


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


## Index of the monument in the shared level/extras index space, or -1 when
## it has not been assigned (in which case the endgame portal has nowhere to
## go and main falls back to ending the run outright).
func monument_index() -> int:
	return index_of_path(monument.resource_path) if monument != null else -1


## Maps a level scene's res:// path back to its index, for the standalone-run
## handoff in LevelRoot. Returns -1 when the scene is not in the catalog.
func index_of_path(path: String) -> int:
	for i in total_count():
		var scene := scene_at(i)
		if scene != null and scene.resource_path == path:
			return i
	return -1
