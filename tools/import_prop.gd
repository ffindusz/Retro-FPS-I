@tool
extends EditorScenePostImport
## Post-import hook for external models (assets/models/**.glb): swaps every
## imported PBR StandardMaterial3D for the project's PS1 ShaderMaterial
## (ps1_vertex_snap), carrying over the albedo texture and color. Without
## this, glTF imports render shiny/perspective-correct and break the look.
##
## Wire it up per model in the .glb's .import file under [params]:
##   import_script/path="res://tools/import_prop.gd"
## then re-run:  Godot_v4.7-stable_win64_console.exe --headless --path . --import

const PS1_SHADER := preload("res://shaders/ps1_vertex_snap.gdshader")


func _post_import(scene: Node) -> Object:
	_convert(scene, {})
	return scene


func _convert(node: Node, cache: Dictionary) -> void:
	var mi := node as MeshInstance3D
	if mi != null and mi.mesh != null:
		for i in mi.mesh.get_surface_count():
			var src := mi.mesh.surface_get_material(i)
			mi.mesh.surface_set_material(i, _ps1_material(src, cache))
	for child in node.get_children():
		_convert(child, cache)


## One converted material per source material, so surfaces sharing a PBR
## material keep sharing the PS1 one.
func _ps1_material(src: Material, cache: Dictionary) -> ShaderMaterial:
	var key := src.get_rid() if src != null else RID()
	if cache.has(key):
		return cache[key]
	var mat := ShaderMaterial.new()
	mat.shader = PS1_SHADER
	# Same baseline as the shipped assets/materials/*.tres.
	mat.set_shader_parameter("affine_strength", 0.0)
	mat.set_shader_parameter("snap_resolution", 240.0)
	mat.set_shader_parameter("world_uv", 0.0)
	mat.set_shader_parameter("uv_scale", Vector2(1, 1))
	if src is BaseMaterial3D:
		mat.set_shader_parameter("albedo_color", src.albedo_color)
		if src.albedo_texture != null:
			mat.set_shader_parameter("albedo_texture", src.albedo_texture)
	cache[key] = mat
	return mat
