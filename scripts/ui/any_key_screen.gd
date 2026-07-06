class_name AnyKeyScreen
extends Control
## Base for full-screen "press any key/click to continue" overlays (start,
## end, intermission). Esc never counts as "any key" since it's the pause
## key. Subclasses react via _on_confirm() and, optionally, _on_special_key()
## for a key that should short-circuit before the generic any-key check
## (e.g. start_screen's 1-6 level-select cheat); set _accept_after_ms for a
## grace period after showing (so a panic-click doesn't instantly confirm).

var _accept_after_ms := 0


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or Time.get_ticks_msec() < _accept_after_ms:
		return
	if event is InputEventKey and event.physical_keycode == KEY_ESCAPE:
		return
	if _on_special_key(event):
		return
	var confirm: bool = (event is InputEventMouseButton and event.pressed) \
			or (event is InputEventKey and event.pressed and not event.echo)
	if confirm:
		get_viewport().set_input_as_handled()
		_on_confirm()


## Override to intercept a specific key before the generic any-key check.
## Return true if the event was handled (and should not also confirm).
func _on_special_key(_event: InputEvent) -> bool:
	return false


## Override to react to the any-key/click confirm.
func _on_confirm() -> void:
	pass
