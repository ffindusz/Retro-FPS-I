class_name AmbientProp
extends Node3D
## Decorative prop wrapper for imported models (assets/models/*.glb): plays
## one looping ambient clip from the model's own AnimationPlayer. Purely
## visual — collision, if any, is the wrapper scene's own primitive shape.

@export var animation := "Idle"


func _ready() -> void:
	var ap: AnimationPlayer = find_child("AnimationPlayer", true, false)
	if ap != null and ap.has_animation(animation):
		ap.play(animation)
