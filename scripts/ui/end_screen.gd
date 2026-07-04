extends Control
## Win/lose screen. Brief input grace period so a panic-click at the moment
## of death doesn't instantly restart.

signal restart_requested

var _accept_after_ms := 0

@onready var _result: Label = $Layout/ResultLabel
@onready var _sub: Label = $Layout/SubLabel


func set_result(win: bool) -> void:
	_accept_after_ms = Time.get_ticks_msec() + 700
	if win:
		_result.text = "YOU WIN"
		_result.label_settings.font_color = Color(0.95, 0.8, 0.35)
		_sub.text = "THE PILE OF GOLD IS YOURS"
	else:
		_result.text = "YOU DIED"
		_result.label_settings.font_color = Color(0.85, 0.2, 0.15)
		_sub.text = "THE FACILITY CLAIMS ANOTHER"


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or Time.get_ticks_msec() < _accept_after_ms:
		return
	# Esc is the pause key; it should never count as "any key".
	if event is InputEventKey and event.physical_keycode == KEY_ESCAPE:
		return
	var confirm: bool = (event is InputEventMouseButton and event.pressed) \
			or (event is InputEventKey and event.pressed and not event.echo)
	if confirm:
		get_viewport().set_input_as_handled()
		restart_requested.emit()
