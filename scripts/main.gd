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
	preload("res://scenes/levels/level_07.tscn"),
	preload("res://scenes/levels/level_test.tscn"),
]
## Model test stage (0 on the title screen). Outside the campaign flow:
## _advance_level refuses to advance into it, and it has no switch/teleporter
## of its own, so it can never advance or complete.
const TEST_STAGE_INDEX := 7
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")

## Grace between touching the gold and accepting the end-screen confirm, so
## a shot fired (or key mashed) at the winning moment can't skip the payoff.
const WIN_CONFIRM_GRACE_MS := 900

var _level: Node3D
var _player: PlayerController
var _level_index := 0
var _restart_index := 0
var _game_active := false
var _options_from_pause := false
var _fps_accum := 0.0
var _win_pending := false
var _win_ready_ms := 0

@onready var _world: Node3D = %World
@onready var _start_screen: Control = %StartScreen
@onready var _end_screen: Control = %EndScreen
@onready var _hud: Control = %Hud
@onready var _pause_screen: Control = %PauseScreen
@onready var _intermission: Control = %Intermission
@onready var _options_screen: Control = %OptionsScreen
@onready var _viewport_container: SubViewportContainer = $ViewportContainer
@onready var _debug_stats: Label = %DebugStats


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameState.player_died.connect(_on_player_died)
	GameState.level_completed.connect(_on_level_completed)
	GameState.game_won.connect(_on_game_won)
	_start_screen.start_requested.connect(start_game)
	_start_screen.options_requested.connect(_open_options.bind(false))
	_end_screen.restart_requested.connect(_on_restart)
	_pause_screen.resume_requested.connect(_set_paused.bind(false))
	_pause_screen.restart_requested.connect(_on_pause_restart)
	_pause_screen.options_requested.connect(_open_options.bind(true))
	_pause_screen.quit_requested.connect(_on_pause_quit)
	_intermission.continue_requested.connect(_on_intermission_continue)
	_options_screen.closed.connect(_on_options_closed)
	Settings.changed.connect(_apply_video_settings)
	_apply_video_settings()
	_start_screen.show_best(GameState.high_score)
	_show_only(_start_screen)


## Refreshes the debug stats overlay a few times a second (readable, not
## flickering) while it is toggled on. Main is PROCESS_MODE_ALWAYS, so this
## ticks in menus and while paused too.
func _process(delta: float) -> void:
	if not _debug_stats.visible:
		return
	_fps_accum += delta
	if _fps_accum >= 0.25:
		_fps_accum = 0.0
		_debug_stats.text = _debug_text()


func _debug_text() -> String:
	var fps := int(Engine.get_frames_per_second())
	var lines := PackedStringArray([
		"FPS %d  (%.1f ms)" % [fps, 1000.0 / maxf(fps, 1)],
		"DRAW %d  PRIMS %s" % [
			int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
			_short(int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))],
		"NODES %d" % int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
	])
	# Player pos/yaw is the handy bit for level checking (place things at coords).
	if _game_active and is_instance_valid(_player):
		var p := _player.global_position
		lines.append("POS %.1f  %.1f  %.1f" % [p.x, p.y, p.z])
		lines.append("YAW %d°" % wrapi(roundi(rad_to_deg(_player.rotation.y)), 0, 360))
	return "\n".join(lines)


## Compact large counts, e.g. 12345 -> "12.3k".
func _short(n: int) -> String:
	return "%.1fk" % (n / 1000.0) if n >= 1000 else str(n)


func _unhandled_input(event: InputEvent) -> void:
	# Esc during play opens the pause screen (which then owns Esc until it
	# closes; see its own input handler).
	if event.is_action_pressed("ui_cancel") and _game_active and not get_tree().paused:
		get_viewport().set_input_as_handled()
		_set_paused(true)
	elif event is InputEventKey and event.pressed and not event.echo \
			and event.physical_keycode >= KEY_F1 and event.physical_keycode <= KEY_F7:
		# Level-warp cheat for testing: F1-F7 jump to that level from
		# anywhere (gameplay, pause, screens) with a fresh loadout.
		get_viewport().set_input_as_handled()
		_warp(event.physical_keycode - KEY_F1)
	elif event is InputEventKey and event.pressed and not event.echo \
			and event.physical_keycode == KEY_F8:
		# Debug stats overlay toggle, for level and performance checking.
		get_viewport().set_input_as_handled()
		_debug_stats.visible = not _debug_stats.visible
	elif _win_pending and Time.get_ticks_msec() >= _win_ready_ms \
			and _is_win_confirm(event):
		# The savor beat ends on a deliberate click/key, not a timer.
		get_viewport().set_input_as_handled()
		Input.action_release("fire")
		_win_pending = false
		_end_game(true)


## Mirrors AnyKeyScreen's idea of "any key": Esc stays the pause/back key
## and wheel scrolls don't count as clicks.
func _is_win_confirm(event: InputEvent) -> bool:
	if event is InputEventKey:
		return event.pressed and not event.echo \
				and event.physical_keycode != KEY_ESCAPE
	return event is InputEventMouseButton and event.pressed \
			and event.button_index <= MOUSE_BUTTON_MIDDLE


func _warp(level_index: int) -> void:
	# close() restores whichever screen options was opened over; the
	# start_game path below then hides everything game-flow-related anyway.
	_options_screen.close()
	_set_overlay(_pause_screen, false)
	_intermission.visible = false
	start_game(level_index)


## The options screen swaps in for its opener (title or pause screen) so the
## opener's own input handling can't fight it, and swaps back on close. The
## tree pause state is left untouched: paused over pause, live over title.
func _open_options(from_pause: bool) -> void:
	_options_from_pause = from_pause
	(_pause_screen if from_pause else _start_screen).visible = false
	_options_screen.open()


func _on_options_closed() -> void:
	(_pause_screen if _options_from_pause else _start_screen).visible = true


## Applies the video half of Settings; the audio half lives on the buses and
## is applied by the Settings autoload itself.
func _apply_video_settings() -> void:
	var mat := _viewport_container.material as ShaderMaterial
	mat.set_shader_parameter("dither_strength", 1.0 if Settings.dither else 0.0)
	mat.set_shader_parameter("color_levels", 32.0 if Settings.dither else 256.0)


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
	_start_screen.show_best(GameState.high_score)
	_show_only(_start_screen)


func start_game(level_index := 0) -> void:
	level_index = clampi(level_index, 0, LEVEL_SCENES.size() - 1)
	_win_pending = false
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
	_hud.show_banner(_level_banner())
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _load_level() -> void:
	_level = LEVEL_SCENES[_level_index].instantiate()
	_world.add_child(_level)
	GameState.begin_level_stats(
			_count_in_level("enemies"), _count_in_level("secret_areas"),
			_count_in_level("gold"))


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
	# Bounded by TEST_STAGE_INDEX, not LEVEL_SCENES.size(): the test stage
	# rides along in the scene list but is never part of the campaign.
	if not _game_active or _level_index + 1 >= TEST_STAGE_INDEX:
		return
	_level_index += 1
	_restart_index = _level_index
	if is_instance_valid(_level):
		_level.name = String(_level.name) + "_dying"
		_level.queue_free()
	_clear_projectiles()
	_load_level()
	_place_player_at_spawn()
	_hud.show_banner(_level_banner())


func _level_banner() -> String:
	if _level_index == TEST_STAGE_INDEX:
		return "TEST STAGE"
	return "LEVEL %d" % (_level_index + 1)


func _on_player_died() -> void:
	if _game_active:
		_game_active = false
		# Non-positional: the player node is about to be freed with the
		# level, and the sting belongs to the death screen, not the world.
		$DeathSting.play()
		_end_game(false)


func _on_game_won() -> void:
	if _game_active:
		_game_active = false
		_restart_index = 0
		# Savor the treasure: the world stays live around the opened chest
		# and the credits screen waits for a deliberate click/key (handled in
		# _unhandled_input) instead of a timer. A hint appears once the
		# confirm grace has passed.
		_win_pending = true
		_win_ready_ms = Time.get_ticks_msec() + WIN_CONFIRM_GRACE_MS
		GameState.announce("THE TREASURE IS YOURS")
		get_tree().create_timer(WIN_CONFIRM_GRACE_MS / 1000.0).timeout.connect(
				func() -> void:
					if _win_pending:
						_hud.show_banner("CLICK OR PRESS ANY KEY"))


func _on_restart() -> void:
	start_game(_restart_index)


func _end_game(win: bool) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var new_best := GameState.finalize_run()
	_end_screen.set_result(win)
	_end_screen.set_stats(GameState.stats_line())
	_end_screen.set_score(GameState.score, GameState.high_score, new_best)
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
	_clear_projectiles()
	_level = null
	_player = null


func _clear_projectiles() -> void:
	# Player rockets are parented to the game viewport (not the level), so
	# without this a rocket in flight would survive level teardown and keep
	# flying — and exploding — into the next level or the menus.
	for projectile in get_tree().get_nodes_in_group("projectiles"):
		projectile.queue_free()


func _show_only(screen: Control) -> void:
	_start_screen.visible = screen == _start_screen
	_end_screen.visible = screen == _end_screen
	_hud.visible = screen == _hud
