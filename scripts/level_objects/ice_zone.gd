extends Area3D
## Marks an icy region: tells the player to switch to slide physics while
## inside (see PlayerController.enter_ice/exit_ice).


func _ready() -> void:
	body_entered.connect(func(body: Node3D) -> void:
		if body.has_method("enter_ice"):
			body.enter_ice())
	body_exited.connect(func(body: Node3D) -> void:
		if body.has_method("exit_ice"):
			body.exit_ice())
