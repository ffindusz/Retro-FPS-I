extends "res://tools/test_base.gd"
## Debug helper: external-model prop check in level 1.
## - prop wrapper scenes are placed and load (torches, skeleton)
## - the skeleton's imported AnimationPlayer is looping its ambient clip
## - the torch flicker AnimationPlayer is running
## - imported meshes carry PS1 ShaderMaterials (tools/import_prop.gd ran)
## Then loads the model test stage and checks all four skeleton displays
## are looping their showcase clips.
##   Godot_v4.7-stable_win64_console.exe --headless --path . -s tools/test_props.gd

const STAGE_CLIPS := {
	"DisplayMinion": "Idle",
	"DisplayWarrior": "Idle_Combat",
	"DisplayMage": "Spellcasting",
	"DisplayRogue": "Walking_A",
}


func _tick(_delta: float) -> bool:
	var world := current_scene.get_node(WORLD_PATH)
	match _step:
		0:
			_next(400)
		1:
			var props: Node3D = world.get_node_or_null("Level01/Props")
			var torch := props.get_node_or_null("TorchCorr3West")
			var skeleton := props.get_node_or_null("SkeletonArena")
			print("props placed: torches=%s skeleton=%s (expect true true)"
					% [torch != null and props.get_node_or_null("TorchCorr3East") != null,
					skeleton != null])
			var flicker: AnimationPlayer = torch.get_node("Flicker")
			print("torch flicker: playing=%s anim=%s (expect true flicker)"
					% [flicker.is_playing(), flicker.current_animation])
			var ap: AnimationPlayer = skeleton.find_child("AnimationPlayer", true, false)
			print("skeleton anim: playing=%s anim=%s loop=%s (expect true Idle 1)"
					% [ap.is_playing(), ap.current_animation,
					ap.get_animation("Idle").loop_mode])
			var mesh: MeshInstance3D = skeleton.find_child("Skeleton_Rogue_Body", true, false)
			var mat := mesh.mesh.surface_get_material(0)
			print("imported material: %s (expect ShaderMaterial)" % mat.get_class())
			current_scene.start_game(6)
			_next(500)
		2:
			var displays: Node3D = world.get_node_or_null("LevelTest/Displays")
			for display_name: String in STAGE_CLIPS:
				var ap: AnimationPlayer = displays.get_node(display_name) \
						.find_child("AnimationPlayer", true, false)
				print("%s: playing=%s anim=%s (expect true %s)" % [display_name,
						ap.is_playing(), ap.current_animation, STAGE_CLIPS[display_name]])
			print("props test done")
			return true
	return false
