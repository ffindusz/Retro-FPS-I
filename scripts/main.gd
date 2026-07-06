extends Control
## Entry point and game-flow controller. Hosts the low-res PS1 SubViewport
## and routes: start screen -> level 1 -> (switch + teleporter) -> level 2
## -> level 3 boss -> secret gold room -> win screen. Death restarts the
## level the player died on; the player node persists across level
## transitions so health and ammo carry over.

const LEVEL_SCENES: Array[PackedScene] = [
	preload("res://scenes/levels/level_01.tscn"),
	preload("res://scenes/levels/level_02.tscn"),
	preload("res://scenes/levels/level_03.tscn"),
	preload("res://scenes/levels/level_04.tscn"),
	preload("res://scenes/levels/level_05.tscn"),
	preload("res://scenes/levels/level_06.tscn"),
]
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")

var _level: Node3D
var _player: PlayerController
var _level_index := 0
var _restart_index := 0
var _game_active := false

@onready var _world: Node3D = %World
@onready var _start_screen: Control = %StartScreen
@onready var _end_screen: Control = %EndScreen
@onready var _hud: Control = %Hud
@onready var _pause_screen: Control = %PauseScreen
@onready var _intermission: Control = %Intermission


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameState.player_died.connect(_on_player_died)
	GameState.level_completed.connect(_on_level_completed)
	GameState.game_won.connect(_on_game_won)
	_start_screen.start_requested.connect(start_game)
	_end_screen.restart_requested.connect(_on_restart)
	_pause_screen.resume_requested.connect(_set_paused.bind(false))
	_pause_screen.restart_requested.connect(_on_pause_restart)
	_pause_screen.quit_requested.connect(_on_pause_quit)
	_intermission.continue_requested.connect(_on_intermission_continue)
	_show_only(_start_screen)


func _unhandled_input(event: InputEvent) -> void:
	# Esc during play opens the pause screen (which then owns Esc until it
	# closes; see its own input handler).
	if event.is_action_pressed("ui_cancel") and _game_active and not get_tree().paused:
		get_viewport().set_input_as_handled()
		_set_paused(true)
	elif event is InputEventKey and event.pressed and not event.echo \
			and event.physical_keycode >= KEY_F1 and event.physical_keycode <= KEY_F6:
		# Level-warp cheat for testing: F1-F6 jump to that level from
		# anywhere (gameplay, pause, screens) with a fresh loadout.
		get_viewport().set_input_as_handled()
		_warp(event.physical_keycode - KEY_F1)


func _warp(level_index: int) -> void:
	_set_overlay(_pause_screen, false)
	_intermission.visible = false
	start_game(level_index)


## Pause menu and intermission are full-screen overlays that stack on top of
## active gameplay: showing one pauses the tree and frees the mouse; hiding
## one (to resume gameplay) unpauses and recaptures it.
func _set_overlay(overlay: Control, shown: bool) -> void:
	get_tree().paused = shown
	overlay.visible = shown
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if shown else Input.MOUSE_MODE_CAPTURED


func _set_paused(paused: bool) -> void:
	_set_overlay(_pause_screen, paused)


func _on_pause_restart() -> void:
	_set_overlay(_pause_screen, false)
	start_game(_level_index)


func _on_pause_quit() -> void:
	_set_overlay(_pause_screen, false)
	_game_active = false
	_clear_game()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_show_only(_start_screen)


func start_game(level_index := 0) -> void:
	level_index = clampi(level_index, 0, LEVEL_SCENES.size() - 1)
	_clear_game()
	GameState.reset()
	_level_index = level_index
	_restart_index = level_index
	_load_level()
	_player = PLAYER_SCENE.instantiate() as PlayerController
	_world.add_child(_player)
	_place_player_at_spawn()
	_game_active = true
	_show_only(_hud)
	_hud.bind_player(_player)
	_hud.show_banner("LEVEL %d" % (_level_index + 1))
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _load_level() -> void:
	_level = LEVEL_SCENES[_level_index].instantiate()
	_world.add_child(_level)
	GameState.begin_level_stats(
			_count_in_level("enemies"), _count_in_level("secret_areas"))


func _count_in_level(group: String) -> int:
	# Filter to the fresh level: the outgoing level's nodes are still in
	# their groups until the deferred free runs.
	var count := 0
	for node in get_tree().get_nodes_in_group(group):
		if _level.is_ancestor_of(node):
			count += 1
	return count


func _place_player_at_spawn() -> void:
	var spawn: Node3D = _level.get_node_or_null("Spawns/PlayerSpawn")
	if spawn and is_instance_valid(_player):
		_player.global_position = spawn.global_position
		_player.velocity = Vector3.ZERO
		_player.rotation.y = spawn.global_rotation.y


func _on_level_completed() -> void:
	if _game_active:
		# Deferred: the teleporter fires from a physics callback.
		_show_intermission.call_deferred()


func _show_intermission() -> void:
	if not _game_active:
		return
	_intermission.show_stats(_level_index + 1, GameState.stats_line())
	_set_overlay(_intermission, true)


func _on_intermission_continue() -> void:
	_set_overlay(_intermission, false)
	_advance_level()


func _advance_level() -> void:
	if not _game_active or _level_index + 1 >= LEVEL_SCENES.size():
		return
	_level_index += 1
	_restart_index = _level_index
	if is_instance_valid(_level):
		_level.name = String(_level.name) + "_dying"
		_level.queue_free()
	_load_level()
	_place_player_at_spawn()
	_hud.show_banner("LEVEL %d" % (_level_index + 1))


func _on_player_died() -> void:
	if _game_active:
		_game_active = false
		_end_game(false)


func _on_game_won() -> void:
	if _game_active:
		_game_active = false
		_restart_index = 0
		# Short beat to savor the treasure before the screen.
		get_tree().create_timer(1.0).timeout.connect(_end_game.bind(true))


func _on_restart() -> void:
	start_game(_restart_index)


func _end_game(win: bool) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_end_screen.set_result(win)
	_end_screen.set_stats(GameState.stats_line())
	_show_only(_end_screen)
	_clear_game()


func _clear_game() -> void:
	for node: Node in [_level, _player]:
		if is_instance_valid(node):
			# Rename before the deferred free so a fresh instance created this
			# frame can claim the "Player"/"Level0X" name (tools and debug
			# paths rely on it).
			node.name = String(node.name) + "_dying"
			node.queue_free()
	_level = null
	_player = null


func _show_only(screen: Control) -> void:
	_start_screen.visible = screen == _start_screen
	_end_screen.visible = screen == _end_screen
	_hud.visible = screen == _hud
