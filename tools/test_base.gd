extends SceneTree
## Shared harness for the tools/test_*.gd headless smoke tests: default
## main-scene boot (change_scene_to_file + start_game), the "wait for a
## real-time deadline, then run this step" gate, key/mouse injection, and the
## assertion helpers (see "Assertions" below) every test reports through.
##
## Subclasses `extends "res://tools/test_base.gd"` and override _tick(delta)
## instead of _process(delta) directly; _tick is only called once
## current_scene exists, the game has been auto-started (unless
## _skip_auto_start() is overridden), and _wait_until has elapsed. End the run
## with `return _finish()` so the tally is printed and the exit code is set.
##
## NOTE: this file is the abstract harness, not a test -- its default _tick
## never returns true, so running it directly (or globbing tools/test_*.gd
## without skipping it) spins forever.

const WORLD_PATH := "ViewportContainer/GameViewport/World"
const GAME_STATE_PATH := "GameState"

## EnemyBase.State mirrored as plain ints. Naming the class directly would pull
## enemy_base.gd -- and the GameState autoload it references -- into this -s
## script's compile pass, which runs before autoloads are registered and fails
## with "Identifier not found: GameState". Same reason the tests reach GameState
## through root.get_node(GAME_STATE_PATH) instead of the singleton.
const STATE_IDLE := 0
const STATE_NOTICE := 1
const STATE_CHASE := 2
const STATE_ATTACK := 3
const STATE_DEAD := 4

var _started := false
var _step := 0
var _wait_until := 0

## Scratch set for tests that gate a one-shot block inside a per-frame _tick
## (e.g. "check this once, the first frame past t=2s").
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


## Override to run this test's per-tick logic. Return true to end the run --
## in practice `return _finish()`, which reports and sets the exit code.
func _tick(_delta: float) -> bool:
	return false


# --- Assertions -------------------------------------------------------------
#
# Every check prints a PASS/FAIL line and is tallied. _finish() then quits with
# exit code 1 if anything failed, so a regression fails the run instead of
# scrolling past in the log. Tests that end without calling _finish() (e.g. one
# that hangs and gets killed) never report success, which is the safe default.

var _checks := 0
var _failures: Array[String] = []


func _record(label: String, ok: bool, detail: String) -> void:
	_checks += 1
	if ok:
		print("  PASS  %s: %s" % [label, detail])
		return
	_failures.append(label)
	print("  FAIL  %s: %s" % [label, detail])


## Exact equality (ints, strings, bools, enum values).
func _expect(label: String, actual: Variant, expected: Variant) -> void:
	_record(label, actual == expected,
			"%s (expected %s)" % [str(actual), str(expected)])


func _expect_true(label: String, actual: bool) -> void:
	_record(label, actual, "%s (expected true)" % str(actual))


func _expect_false(label: String, actual: bool) -> void:
	_record(label, not actual, "%s (expected false)" % str(actual))


## Float equality within tolerance -- physics and tween results never land on
## an exact value.
func _expect_near(label: String, actual: float, expected: float,
		tolerance := 0.01) -> void:
	_record(label, absf(actual - expected) <= tolerance,
			"%.3f (expected %.3f +/- %.3f)" % [actual, expected, tolerance])


func _expect_less(label: String, actual: float, limit: float) -> void:
	_record(label, actual < limit, "%.3f (expected < %.3f)" % [actual, limit])


func _expect_greater(label: String, actual: float, limit: float) -> void:
	_record(label, actual > limit, "%.3f (expected > %.3f)" % [actual, limit])


## Inclusive range, for values with legitimate slack (e.g. an FSM that may sit
## in either of two adjacent states by the time it is sampled).
func _expect_between(label: String, actual: float, low: float,
		high: float) -> void:
	_record(label, actual >= low and actual <= high,
			"%s (expected %s..%s)" % [str(actual), str(low), str(high)])


## Prints the tally and sets the process exit code: 0 all-clear, 1 if any check
## failed. Returns true so callers can `return _finish()` from _tick.
func _finish() -> bool:
	if _failures.is_empty():
		print("RESULT: PASS (%d checks)" % _checks)
		quit(0)
	else:
		print("RESULT: FAIL (%d of %d checks) -> %s"
				% [_failures.size(), _checks, ", ".join(_failures)])
		quit(1)
	return true


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


## One half of a left click, for tests that need the button held across
## steps; use _click() for a plain click.
func _mouse_button(pressed: bool, pos := Vector2(200, 150)) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.position = pos
	ev.pressed = pressed
	Input.parse_input_event(ev)


func _click(pos := Vector2(200, 150)) -> void:
	_mouse_button(true, pos)
	_mouse_button(false, pos)
