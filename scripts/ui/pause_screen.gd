extends Control
## Pause overlay. Runs while the tree is paused (main is PROCESS_MODE_ALWAYS
## and this screen inherits it); the game world sits frozen behind it.

signal resume_requested
signal restart_requested
signal options_requested
signal quit_requested


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	# Wheel scrolls arrive as mouse-button presses; only real buttons resume.
	if event.is_action_pressed("ui_cancel") \
			or (event is InputEventMouseButton and event.pressed
					and event.button_index <= MOUSE_BUTTON_MIDDLE):
		get_viewport().set_input_as_handled()
		if event is InputEventMouseButton:
			# See AnyKeyScreen: fire is polled, so the resuming click would
			# otherwise shoot on the first unpaused frame.
			Input.action_release("fire")
		resume_requested.emit()
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_R:
				get_viewport().set_input_as_handled()
				restart_requested.emit()
			KEY_O:
				get_viewport().set_input_as_handled()
				options_requested.emit()
			KEY_Q:
				get_viewport().set_input_as_handled()
				quit_requested.emit()
