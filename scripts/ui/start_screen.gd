extends AnyKeyScreen
## Title screen: any key or click starts the game at level 1; the number
## keys 1-7 are the level-select cheat for testing, and 0 loads the model
## test stage.

signal start_requested(level_index: int)
signal options_requested

## Matches Main.TEST_STAGE_INDEX (the extra entry after the 7 campaign
## levels in Main.LEVEL_SCENES).
const TEST_STAGE_INDEX := 7

@onready var _best: Label = $Layout/BestLabel


## Shows the saved best score (blank until one exists). Main refreshes this
## whenever the title returns to view, so it reflects a just-set record.
func show_best(best: int) -> void:
	_best.text = "BEST %d" % best if best > 0 else ""


func _on_special_key(event: InputEvent) -> bool:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return false
	if event.physical_keycode == KEY_O:
		get_viewport().set_input_as_handled()
		options_requested.emit()
		return true
	if event.physical_keycode >= KEY_1 and event.physical_keycode <= KEY_7:
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
