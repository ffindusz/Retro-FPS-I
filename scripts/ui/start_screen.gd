extends AnyKeyScreen
## Title screen: any key or click starts the game at level 1; the number
## keys 1-6 are the level-select cheat for testing, and 0 loads the model
## test stage.

signal start_requested(level_index: int)

## Matches Main.TEST_STAGE_INDEX (the extra entry after the 6 campaign
## levels in Main.LEVEL_SCENES).
const TEST_STAGE_INDEX := 6


func _on_special_key(event: InputEvent) -> bool:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return false
	if event.physical_keycode >= KEY_1 and event.physical_keycode <= KEY_6:
		get_viewport().set_input_as_handled()
		start_requested.emit(event.physical_keycode - KEY_1)
		return true
	if event.physical_keycode == KEY_0:
		get_viewport().set_input_as_handled()
		start_requested.emit(TEST_STAGE_INDEX)
		return true
	return false


func _on_confirm() -> void:
	start_requested.emit(0)
