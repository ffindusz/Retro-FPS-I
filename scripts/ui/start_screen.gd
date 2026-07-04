extends Control
## Title screen: any key or click starts the game.

signal start_requested


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	# Esc is the pause key; it should never count as "any key".
	if event is InputEventKey and event.physical_keycode == KEY_ESCAPE:
		return
	var confirm: bool = (event is InputEventMouseButton and event.pressed) \
			or (event is InputEventKey and event.pressed and not event.echo)
	if confirm:
		get_viewport().set_input_as_handled()
		start_requested.emit()
