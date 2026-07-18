extends Control
## Keyboard-driven options overlay, opened with O from the title or pause
## screen: W/S (or arrows) pick a row, A/D (or arrows) adjust it, Esc goes
## back. Values live in the Settings autoload; every change is applied and
## saved immediately, so backing out never loses anything.
##
## Listens in _input for the same reason as AnyKeyScreen: the game's
## SubViewportContainer consumes GUI input, and over the pause screen the
## tree is paused (this screen inherits Main's PROCESS_MODE_ALWAYS).

signal closed

const COLOR_SELECTED := Color(0.95, 0.8, 0.35)
const COLOR_NORMAL := Color(0.62, 0.65, 0.75)
const BAR_CELLS := 10
const VOLUME_STEP := 0.1
const SENSITIVITY_STEP := 0.1

const ROW_SENSITIVITY := 0
const ROW_MUSIC := 1
const ROW_SFX := 2
const ROW_DITHER := 3

var _selected := 0

@onready var _rows: Array[Node] = [
	$Layout/RowSensitivity, $Layout/RowMusic, $Layout/RowSfx, $Layout/RowDither,
]
@onready var _click_sound: AudioStreamPlayer = $ClickSound


func open() -> void:
	_selected = 0
	visible = true
	_refresh()


func close() -> void:
	if not visible:
		return
	Settings.save_settings()
	visible = false
	closed.emit()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if not (event is InputEventKey and event.pressed):
		return
	# Adjust keys deliberately accept echo events so holding them sweeps a
	# slider; navigation and close ignore repeats.
	match (event as InputEventKey).physical_keycode:
		KEY_ESCAPE:
			if not event.echo:
				get_viewport().set_input_as_handled()
				close()
		KEY_UP, KEY_W:
			if not event.echo:
				get_viewport().set_input_as_handled()
				_move(-1)
		KEY_DOWN, KEY_S:
			if not event.echo:
				get_viewport().set_input_as_handled()
				_move(1)
		KEY_LEFT, KEY_A:
			get_viewport().set_input_as_handled()
			_adjust(-1)
		KEY_RIGHT, KEY_D:
			get_viewport().set_input_as_handled()
			_adjust(1)


func _move(dir: int) -> void:
	_selected = wrapi(_selected + dir, 0, _rows.size())
	_click_sound.play()
	_refresh()


func _adjust(dir: int) -> void:
	match _selected:
		ROW_SENSITIVITY:
			Settings.sensitivity = clampf(
					snappedf(Settings.sensitivity + SENSITIVITY_STEP * dir, SENSITIVITY_STEP),
					Settings.SENSITIVITY_MIN, Settings.SENSITIVITY_MAX)
		ROW_MUSIC:
			Settings.music_volume = clampf(
					snappedf(Settings.music_volume + VOLUME_STEP * dir, VOLUME_STEP), 0.0, 1.0)
		ROW_SFX:
			Settings.sfx_volume = clampf(
					snappedf(Settings.sfx_volume + VOLUME_STEP * dir, VOLUME_STEP), 0.0, 1.0)
		ROW_DITHER:
			Settings.dither = not Settings.dither
	Settings.apply()
	Settings.save_settings()
	# On the SFX bus, so this doubles as the volume preview blip.
	_click_sound.play()
	_refresh()


func _refresh() -> void:
	_set_row(ROW_SENSITIVITY, "%s %d%%" % [
			_bar(inverse_lerp(Settings.SENSITIVITY_MIN, Settings.SENSITIVITY_MAX,
					Settings.sensitivity)),
			roundi(Settings.sensitivity * 100.0)])
	_set_row(ROW_MUSIC, "%s %d%%"
			% [_bar(Settings.music_volume), roundi(Settings.music_volume * 100.0)])
	_set_row(ROW_SFX, "%s %d%%"
			% [_bar(Settings.sfx_volume), roundi(Settings.sfx_volume * 100.0)])
	_set_row(ROW_DITHER, "ON" if Settings.dither else "OFF")


func _set_row(index: int, value_text: String) -> void:
	var row := _rows[index]
	(row.get_node("Value") as Label).text = value_text
	var color := COLOR_SELECTED if index == _selected else COLOR_NORMAL
	for label_name: String in ["Key", "Value"]:
		(row.get_node(label_name) as Label).add_theme_color_override("font_color", color)


func _bar(fraction: float) -> String:
	var filled := roundi(clampf(fraction, 0.0, 1.0) * BAR_CELLS)
	return "[%s%s]" % ["#".repeat(filled), "-".repeat(BAR_CELLS - filled)]
