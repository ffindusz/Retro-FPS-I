extends AnyKeyScreen
## Title screen: any key or click starts the game at level 1; the number
## keys 1-6 are the level-select cheat for testing.

signal start_requested(level_index: int)


func _on_special_key(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed and not event.echo \
			and event.physical_keycode >= KEY_1 and event.physical_keycode <= KEY_6:
		get_viewport().set_input_as_handled()
		start_requested.emit(event.physical_keycode - KEY_1)
		return true
	return false


func _on_confirm() -> void:
	start_requested.emit(0)
