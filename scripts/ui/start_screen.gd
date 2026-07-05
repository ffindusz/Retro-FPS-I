extends Control
## Title screen: any key or click starts the game at level 1; the number
## keys 1-6 are the level-select cheat for testing.

signal start_requested(level_index: int)


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	# Esc is the pause key; it should never count as "any key".
	if event is InputEventKey and event.physical_keycode == KEY_ESCAPE:
		return
	if event is InputEventKey and event.pressed and not event.echo \
			and event.physical_keycode >= KEY_1 and event.physical_keycode <= KEY_6:
		get_viewport().set_input_as_handled()
		start_requested.emit(event.physical_keycode - KEY_1)
		return
	var confirm: bool = (event is InputEventMouseButton and event.pressed) \
			or (event is InputEventKey and event.pressed and not event.echo)
	if confirm:
		get_viewport().set_input_as_handled()
		start_requested.emit(0)
