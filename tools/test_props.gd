extends "res://tools/test_base.gd"
## Debug helper: external-model prop check in level 1.
## - prop wrapper scenes are placed and load (torches, rubble remains)
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

const STAGE_PROPS := ["BannerRed", "BannerBlue", "SwordShield", "TorchUnlit",
		"Pillar", "PillarDecorated", "CratesStacked", "RubbleHalf", "RubbleLarge"]


func _tick(_delta: float) -> bool:
	var world := current_scene.get_node(WORLD_PATH)
	match _step:
		0:
			_next(400)
		1:
			var props: Node3D = world.get_node_or_null("Level01/Props")
			var torch := props.get_node_or_null("TorchCorr3West")
			var remains := props.get_node_or_null("RemainsArena")
			print("props placed: torches=%s remains=%s (expect true true)"
					% [torch != null and props.get_node_or_null("TorchCorr3East") != null,
					remains != null])
			var flicker: AnimationPlayer = torch.get_node("Flicker")
			print("torch flicker: playing=%s anim=%s (expect true flicker)"
					% [flicker.is_playing(), flicker.current_animation])
			# The remains prop is now a static rubble pile (no AnimationPlayer),
			# swapped off the skeleton_rogue model that enemy_rogue uses. Still
			# verify its imported mesh carries a PS1 ShaderMaterial.
			var meshes := remains.find_children("*", "MeshInstance3D", true, false)
			var mat := (meshes[0] as MeshInstance3D).mesh.surface_get_material(0)
			print("imported material: %s (expect ShaderMaterial)" % mat.get_class())
			current_scene.start_game(7)
			_next(500)
		2:
			var displays: Node3D = world.get_node_or_null("LevelTest/Displays")
			for display_name: String in STAGE_CLIPS:
				var ap: AnimationPlayer = displays.get_node(display_name) \
						.find_child("AnimationPlayer", true, false)
				print("%s: playing=%s anim=%s (expect true %s)" % [display_name,
						ap.is_playing(), ap.current_animation, STAGE_CLIPS[display_name]])
			var stage_props: Node3D = world.get_node_or_null("LevelTest/Props")
			var missing := []
			for prop_name in STAGE_PROPS:
				if stage_props.get_node_or_null(prop_name) == null:
					missing.append(prop_name)
			print("stage props: %d placed, missing=%s (expect %d [])"
					% [STAGE_PROPS.size() - missing.size(), missing, STAGE_PROPS.size()])
			var pillar_mesh: MeshInstance3D = stage_props.get_node("Pillar") \
					.find_child("pillar", true, false)
			print("pillar material: %s (expect ShaderMaterial)"
					% pillar_mesh.mesh.surface_get_material(0).get_class())
			var unlit_flicker: AnimationPlayer = \
					stage_props.get_node("TorchUnlit").get_node("Flicker")
			print("torch_unlit flicker: playing=%s (expect true)"
					% unlit_flicker.is_playing())
			print("props test done")
			return true
	return false
