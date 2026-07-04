extends Control
## Entry point and game-flow controller. Hosts the low-res PS1 SubViewport
## and routes: start screen -> gameplay (level + player instanced into the
## viewport) -> end screen (win/lose) -> restart.

const LEVEL_SCENE := preload("res://scenes/levels/level_01.tscn")
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")

var _level: Node3D
var _player: CharacterBody3D
var _game_active := false

@onready var _world: Node3D = %World
@onready var _start_screen: Control = %StartScreen
@onready var _end_screen: Control = %EndScreen
@onready var _hud: Control = %Hud


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameState.player_died.connect(_on_player_died)
	GameState.boss_died.connect(_on_boss_died)
	_start_screen.start_requested.connect(start_game)
	_end_screen.restart_requested.connect(start_game)
	_show_only(_start_screen)


func start_game() -> void:
	_clear_game()
	GameState.reset()
	_level = LEVEL_SCENE.instantiate()
	_world.add_child(_level)
	_player = PLAYER_SCENE.instantiate()
	_world.add_child(_player)
	var spawn: Node3D = _level.get_node_or_null("Spawns/PlayerSpawn")
	if spawn:
		_player.global_position = spawn.global_position
	_game_active = true
	_show_only(_hud)
	_hud.bind_player(_player)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_player_died() -> void:
	if _game_active:
		_game_active = false
		_end_game(false)


func _on_boss_died() -> void:
	if _game_active:
		_game_active = false
		# Short beat so the boss's death topple is visible before the screen.
		get_tree().create_timer(1.2).timeout.connect(_end_game.bind(true))


func _end_game(win: bool) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_end_screen.set_result(win)
	_show_only(_end_screen)
	_clear_game()


func _clear_game() -> void:
	for node: Node in [_level, _player]:
		if is_instance_valid(node):
			# Rename before the deferred free so a fresh instance created this
			# frame can claim the "Player"/"Level01" name (tools and debug
			# paths rely on it).
			node.name = String(node.name) + "_dying"
			node.queue_free()
	_level = null
	_player = null


func _show_only(screen: Control) -> void:
	_start_screen.visible = screen == _start_screen
	_end_screen.visible = screen == _end_screen
	_hud.visible = screen == _hud
