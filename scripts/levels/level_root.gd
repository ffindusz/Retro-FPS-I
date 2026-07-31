@tool
extends Node3D
class_name LevelRoot
## Root script for every level scene. Two jobs:
##
## 1. Lets a level be play-tested on its own. Pressing F6 on
##    scenes/levels/level_0X.tscn used to "run" but not be playable -- a level
##    holds no camera, no player, no WorldEnvironment and no Sun (those live in
##    scenes/main.tscn), so you got a black screen and enemies that never woke
##    because nothing was in the "player" group. Instead of duplicating that
##    rig here, a standalone run hands off to main.tscn and asks it to boot
##    this level, so F6 looks exactly like the real game.
## 2. Holds per-level metadata that used to be synthesized from the level
##    index in main.gd.

## Banner shown on arrival. Left empty, main.gd falls back to "LEVEL n"
## (or "TEST STAGE"), which is what every level did before this existed.
@export var display_name: String = ""

## Set by a standalone (F6) run just before it swaps to main.tscn, and claimed
## there by take_pending_scene_path(). Static so it survives the scene change
## that frees this node.
static var _pending_scene_path := ""


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if get_tree().current_scene != self:
		return  # Normal path: instanced into main.tscn's %World by main.gd.
	_pending_scene_path = scene_file_path
	# Deferred: changing scenes frees this node, so it must not happen while
	# the tree is still walking our own _ready().
	get_tree().change_scene_to_file.call_deferred("res://scenes/main.tscn")


## Returns the level scene path a standalone run asked for (empty if this is a
## normal boot), clearing it so a later return to the title screen doesn't warp
## back into the level again.
static func take_pending_scene_path() -> String:
	var path := _pending_scene_path
	_pending_scene_path = ""
	return path


func _get_configuration_warnings() -> PackedStringArray:
	if get_node_or_null("Spawns/PlayerSpawn") == null:
		# main.gd:_place_player_at_spawn() looks this up by exact path; without
		# it the player spawns at the world origin, usually inside geometry.
		return PackedStringArray([
			"No Spawns/PlayerSpawn node: main.gd cannot place the player."])
	return PackedStringArray()
