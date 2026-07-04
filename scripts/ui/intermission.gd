extends Control
## Between-level stats screen shown while the tree is paused. Any key or
## click (except Esc) continues to the next level.

signal continue_requested

var _accept_after_ms := 0

@onready var _title: Label = $Layout/TitleLabel
@onready var _stats: Label = $Layout/StatsLabel


func show_stats(level_number: int, stats_text: String) -> void:
	_accept_after_ms = Time.get_ticks_msec() + 500
	_title.text = "LEVEL %d CLEAR" % level_number
	_stats.text = stats_text


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or Time.get_ticks_msec() < _accept_after_ms:
		return
	if event is InputEventKey and event.physical_keycode == KEY_ESCAPE:
		return
	var confirm: bool = (event is InputEventMouseButton and event.pressed) \
			or (event is InputEventKey and event.pressed and not event.echo)
	if confirm:
		get_viewport().set_input_as_handled()
		continue_requested.emit()
