extends SceneTree
## Shared harness for the tools/test_*.gd headless smoke tests: default
## main-scene boot (change_scene_to_file + start_game), the "wait for a
## real-time deadline, then run this step" gate, key-injection, and a
## dedup'd-print helper almost every test needs.
##
## Subclasses `extends "res://tools/test_base.gd"` and override _tick(delta)
## instead of _process(delta) directly; _tick is only called once
## current_scene exists, the game has been auto-started (unless
## _skip_auto_start() is overridden), and _wait_until has elapsed.

const WORLD_PATH := "ViewportContainer/GameViewport/World"
const GAME_STATE_PATH := "GameState"

var _started := false
var _step := 0
var _wait_until := 0

var _reported := {}


func _initialize() -> void:
	change_scene_to_file("res://scenes/main.tscn")


func _process(delta: float) -> bool:
	if current_scene == null:
		return false
	if not _started:
		_started = true
		if _skip_auto_start():
			return _tick(delta)
		current_scene.start_game(_boot_level_index())
		return false
	_every_frame(delta)
	if Time.get_ticks_msec() < _wait_until:
		return false
	return _tick(delta)


## Override to run this test's per-tick logic. Return true to end the run.
func _tick(_delta: float) -> bool:
	return false


## Override to sample state every frame, even while waiting on _wait_until
## (e.g. tracking a peak value that could be reached mid-wait).
func _every_frame(_delta: float) -> void:
	pass


## Override to boot into a level other than the first.
func _boot_level_index() -> int:
	return 0


## Override to true for tests that drive the title screen themselves
## (e.g. the level-select cheat) instead of auto-starting via start_game().
func _skip_auto_start() -> bool:
	return false


## Advances _step and sets the next real-time wait deadline.
func _next(wait_ms: int) -> void:
	_step += 1
	_wait_until = Time.get_ticks_msec() + wait_ms


func _key(code: Key) -> void:
	var press := InputEventKey.new()
	press.keycode = code
	press.physical_keycode = code
	press.pressed = true
	Input.parse_input_event(press)
	var release := InputEventKey.new()
	release.keycode = code
	release.physical_keycode = code
	release.pressed = false
	Input.parse_input_event(release)


## Prints msg the first time this key is seen; a no-op on repeat ticks.
func _report_once(key: String, msg: String) -> void:
	if _reported.has(key):
		return
	_reported[key] = true
	print(msg)
