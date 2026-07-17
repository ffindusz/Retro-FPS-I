class_name AnyKeyScreen
extends Control
## Base for full-screen "press any key/click to continue" overlays (start,
## end, intermission). Esc never counts as "any key" since it's the pause
## key. Subclasses react via _on_confirm() and, optionally, _on_special_key()
## for a key that should short-circuit before the generic any-key check
## (e.g. start_screen's 1-6 level-select cheat); set _accept_after_ms for a
## grace period after showing (so a panic-click doesn't instantly confirm).
##
## Listens in _input, not _unhandled_input: the game's SubViewportContainer
## consumes mouse clicks in the GUI pass (forwarding them into the game
## viewport), so clicks would never reach _unhandled_input while the world
## renders behind these screens. _input runs before the GUI pass.

var _accept_after_ms := 0


func _input(event: InputEvent) -> void:
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
		if event is InputEventMouseButton:
			# The weapon manager POLLS is_action_pressed("fire"), which the
			# handled flag doesn't reach — without this, the confirming click
			# also fires a shot on the first captured-mouse frame.
			Input.action_release("fire")
		_on_confirm()


## Override to intercept a specific key before the generic any-key check.
## Return true if the event was handled (and should not also confirm).
func _on_special_key(_event: InputEvent) -> bool:
	return false


## Override to react to the any-key/click confirm.
func _on_confirm() -> void:
	pass
