extends AnyKeyScreen
## Title screen: any key or click starts the game at level 1; the number keys
## are the level-select cheat for testing (one per campaign level, counting
## from 1), and 0 loads the model test stage.

signal start_requested(level_index: int)
signal options_requested

## Same catalog main.gd plays from, so the digit range and the test stage
## index follow it instead of being restated here.
const CATALOG := preload("res://assets/level_catalog.tres")

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
	# One digit per campaign level, starting at 1. KEY_0 is the test stage, so
	# a campaign of 9 or more levels would need a different scheme.
	if event.physical_keycode >= KEY_1 \
			and event.physical_keycode < mini(KEY_1 + CATALOG.campaign_count(), KEY_0 + 10):
		get_viewport().set_input_as_handled()
		start_requested.emit(event.physical_keycode - KEY_1)
		return true
	if event.physical_keycode == KEY_0 and not CATALOG.extras.is_empty():
		get_viewport().set_input_as_handled()
		start_requested.emit(CATALOG.campaign_count())
		return true
	return false


func _on_confirm() -> void:
	start_requested.emit(0)
