extends SceneTree
## Debug helper: dumps a canonical text description of every scene under
## scenes/ -- node paths, classes, instanced sub-scenes, scripts and every
## stored property value. Diffing two dumps proves whether a change to the
## .tscn FILES changed the scenes they actually describe.
##
## Written for the editor-format normalization pass, where the files are
## rewritten wholesale (uids injected, ext_resource ids renumbered, properties
## reordered) and the whole claim is "the text moved, the scene did not".
## Screenshots can't settle that -- torch flicker, particles and enemy AI make
## them differ run to run -- but this dump is deterministic.
##
## Run headless, before and after, then diff the two files:
##   Godot_v4.7-stable_win64_console.exe --headless --path . -s tools/dump_scenes.gd
## Output: tmp_shots/scene_dump.txt (override with DUMP_OUT).

const SCAN_DIRS := ["res://scenes"]

## Properties whose values are noise for this comparison: they are derived from
## the node's position in the tree rather than stored in the .tscn.
const SKIP_PROPS := ["owner", "multiplayer", "script"]


func _initialize() -> void:
	var out := PackedStringArray()
	for path in _scene_paths():
		out.append("=== " + path)
		var packed := load(path) as PackedScene
		if packed == null:
			out.append("  <FAILED TO LOAD>")
			continue
		# Never added to the tree: _ready() must not run, both to avoid side
		# effects and because these scenes expect a live game around them.
		var root := packed.instantiate()
		_dump(root, root, out)
		root.free()

	var dest := OS.get_environment("DUMP_OUT")
	if dest == "":
		dest = "res://tmp_shots/scene_dump.txt"
	DirAccess.make_dir_recursive_absolute(dest.get_base_dir())
	var f := FileAccess.open(dest, FileAccess.WRITE)
	if f == null:
		printerr("could not write ", dest)
		quit(1)
		return
	f.store_string("\n".join(out) + "\n")
	f.close()
	print("dumped %d lines for %d scenes -> %s"
			% [out.size(), _scene_paths().size(), dest])
	quit()


func _scene_paths() -> PackedStringArray:
	var paths := PackedStringArray()
	for dir in SCAN_DIRS:
		_collect(dir, paths)
	paths.sort()
	return paths


func _collect(dir_path: String, into: PackedStringArray) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		var full := dir_path.path_join(name)
		if dir.current_is_dir():
			_collect(full, into)
		elif name.ends_with(".tscn"):
			into.append(full)
		name = dir.get_next()
	dir.list_dir_end()


func _dump(node: Node, root: Node, out: PackedStringArray) -> void:
	var head := "  %s [%s]" % [root.get_path_to(node), node.get_class()]
	if node.scene_file_path != "" and node != root:
		head += " instance=" + node.scene_file_path
	var scr: Script = node.get_script() as Script
	if scr != null:
		head += " script=" + scr.resource_path
	var groups := PackedStringArray()
	for g in node.get_groups():
		groups.append(String(g))
	if not groups.is_empty():
		groups.sort()
		head += " groups=" + ",".join(groups)
	out.append(head)

	for prop in node.get_property_list():
		if not (prop["usage"] & PROPERTY_USAGE_STORAGE):
			continue
		if SKIP_PROPS.has(prop["name"]):
			continue
		out.append("      %s = %s" % [prop["name"], _fmt(node.get(prop["name"]))])

	for child in node.get_children():
		_dump(child, root, out)


## Stable, precision-capped rendering: raw float formatting would turn
## harmless last-bit differences into false positives.
func _fmt(value: Variant) -> String:
	if value is Resource:
		var res := value as Resource
		return "<%s %s>" % [res.get_class(),
				res.resource_path if res.resource_path != "" else "(inline)"]
	if value is Object:
		return "<%s>" % (value as Object).get_class()
	if value is float:
		return "%.4f" % value
	if value is Vector3:
		var v := value as Vector3
		return "(%.4f, %.4f, %.4f)" % [v.x, v.y, v.z]
	if value is Transform3D:
		var t := value as Transform3D
		return "[%s | %s | %s | %s]" % [_fmt(t.basis.x), _fmt(t.basis.y),
				_fmt(t.basis.z), _fmt(t.origin)]
	if value is Array:
		var parts := PackedStringArray()
		for item in value:
			parts.append(_fmt(item))
		return "[" + ", ".join(parts) + "]"
	return str(value)


func _process(_delta: float) -> bool:
	return true
