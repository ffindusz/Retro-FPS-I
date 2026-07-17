extends SceneTree
## Debug helper: inspects imported external models (assets/models/*.glb).
## Prints the node tree, mesh AABBs (scale check), surface material types
## (expect ShaderMaterial after tools/import_prop.gd), and animation clips.
##   Godot_v4.7-stable_win64_console.exe --headless --path . -s tools/probe_model.gd

const MODELS := [
	"res://assets/models/torch_mounted/torch_mounted.glb",
	"res://assets/models/skeleton_minion/skeleton_minion.glb",
]


func _init() -> void:
	for path in MODELS:
		print("=== ", path)
		var scene: PackedScene = load(path)
		if scene == null:
			print("  FAILED TO LOAD")
			continue
		_dump(scene.instantiate(), 1)
	quit()


func _dump(node: Node, depth: int) -> void:
	var line := "  ".repeat(depth) + node.name + " (" + node.get_class() + ")"
	var mi := node as MeshInstance3D
	if mi != null and mi.mesh != null:
		var aabb := mi.mesh.get_aabb()
		line += " aabb=%s size=%s" % [aabb.position, aabb.size]
		for i in mi.mesh.get_surface_count():
			var m := mi.mesh.surface_get_material(i)
			var desc := "null" if m == null else m.get_class()
			if m is ShaderMaterial:
				var tex: Texture2D = m.get_shader_parameter("albedo_texture")
				desc += "(tex=%s)" % ("yes " + str(tex.get_size()) if tex != null else "NO")
			line += " surf%d=%s" % [i, desc]
	var ap := node as AnimationPlayer
	if ap != null:
		var names := []
		for anim_name in ap.get_animation_list():
			names.append("%s(%.1fs)" % [anim_name, ap.get_animation(anim_name).length])
		line += " anims=" + str(names)
	print(line)
	for child in node.get_children():
		_dump(child, depth + 1)
