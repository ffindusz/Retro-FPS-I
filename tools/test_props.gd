extends "res://tools/test_base.gd"
## Debug helper: external-model prop check in level 1.
## - prop wrapper scenes are placed and load (torches, smashed furniture)
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
		"Pillar", "PillarDecorated", "CratesStacked", "TableBrokenLong", "TableBroken",
		"Chair", "Stool", "Shelves", "BoxStacked", "Bed", "BarrelLarge", "BarrelStack"]


func _tick(_delta: float) -> bool:
	var world := current_scene.get_node(WORLD_PATH)
	match _step:
		0:
			_next(400)
		1:
			var props: Node3D = world.get_node_or_null("Level01/Props")
			var torch := props.get_node_or_null("TorchCorr3West")
			var wreck := props.get_node_or_null("TableBrokenArena")
			_expect_true("torch props placed",
					torch != null and props.get_node_or_null("TorchCorr3East") != null)
			_expect_true("smashed-table prop placed", wreck != null)
			var flicker: AnimationPlayer = torch.get_node("Flicker")
			_expect_true("torch flicker running", flicker.is_playing())
			_expect("torch flicker clip", flicker.current_animation, "flicker")
			# A static prop (no AnimationPlayer): just verify its imported
			# mesh carries a PS1 ShaderMaterial, i.e. import_prop.gd ran.
			var meshes := wreck.find_children("*", "MeshInstance3D", true, false)
			var mat := (meshes[0] as MeshInstance3D).mesh.surface_get_material(0)
			_expect("imported furniture material", mat.get_class(), "ShaderMaterial")
			current_scene.start_game(7)
			_next(500)
		2:
			var displays: Node3D = world.get_node_or_null("LevelTest/Displays")
			for display_name: String in STAGE_CLIPS:
				var ap: AnimationPlayer = displays.get_node(display_name) \
						.find_child("AnimationPlayer", true, false)
				_expect_true("%s animating" % display_name, ap.is_playing())
				_expect("%s clip" % display_name, ap.current_animation,
						STAGE_CLIPS[display_name])
			var stage_props: Node3D = world.get_node_or_null("LevelTest/Props")
			var missing := []
			for prop_name in STAGE_PROPS:
				if stage_props.get_node_or_null(prop_name) == null:
					missing.append(prop_name)
			_expect("stage props missing", missing, [])
			var pillar_mesh: MeshInstance3D = stage_props.get_node("Pillar") \
					.find_child("pillar", true, false)
			_expect("pillar material",
					pillar_mesh.mesh.surface_get_material(0).get_class(),
					"ShaderMaterial")
			var unlit_flicker: AnimationPlayer = \
					stage_props.get_node("TorchUnlit").get_node("Flicker")
			_expect_true("torch_unlit flicker running", unlit_flicker.is_playing())
			return _finish()
	return false
