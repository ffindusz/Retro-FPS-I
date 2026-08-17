extends SceneTree
## One-shot maintenance tool: rewrites every scene in Godot's own canonical
## format by driving the editor's real open+save, then does the same for the
## shared materials.
##
## Why this exists: every scene here was authored by hand-editing text, so none
## carry the uid= fields Godot 4.4+ writes, and none carry per-node unique_id.
## The files load fine, but the FIRST save from the editor rewrites all of that
## at once, turning a one-box change into a several-hundred-line diff. Doing it
## deliberately, once, in a commit of its own, makes every later GUI edit small.
##
## MUST run with --editor: this drives EditorInterface, and the plain
## ResourceSaver path available to a normal run writes a DIFFERENT format
## (no uid, no unique_id, and it drops load_steps).
##
##   Godot_v4.7-stable_win64_console.exe --headless --editor -s tools/normalize_scenes.gd
##
## Do not be tempted to "simplify" this into instantiate(GEN_EDIT_STATE_MAIN) +
## PackedScene.pack() + ResourceSaver.save(). That looks equivalent and is not:
## it INLINES exported PackedScene references (weapon_staff's
## projectile_scene stops pointing at projectile_staff_fireball.tscn and
## becomes a private copy). The editor's own save keeps them as ExtResource.
##
## Verify with tools/dump_scenes.gd before and after: the text is expected to
## change completely, the scenes it describes are not.
##
## ONLY=<substring>  restrict to matching paths (trial one scene first)
## MATERIALS=1       also re-save assets/materials/*.tres. Off by default:
##                   re-saving a material can give it a new uid, which would
##                   invalidate the uid every referring scene has recorded.

## Frames given to the editor to settle before the first open, and per scene
## between open_scene_from_path() and save_scene(). Both are deferred inside
## the editor, so this cannot be collapsed to a single frame.
const SETTLE_FRAMES := 30
## Overridable with WAIT: a scene with many instanced sub-scenes can need
## noticeably longer to become the edited scene.
var FRAMES_PER_SCENE := 20

var _paths: PackedStringArray
var _frames := 0
var _saved := 0
var _failed := 0
var _materials_done := false


func _initialize() -> void:
	var only := OS.get_environment("ONLY")
	var wait := OS.get_environment("WAIT")
	if wait != "":
		FRAMES_PER_SCENE = int(wait)
	_paths = PackedStringArray()
	_collect("res://scenes", ".tscn", _paths)
	_paths.sort()
	if only != "":
		var filtered := PackedStringArray()
		for path in _paths:
			if path.contains(only):
				filtered.append(path)
		_paths = filtered
	print("normalizing %d scene(s)" % _paths.size())


func _process(_delta: float) -> bool:
	var ei := Engine.get_singleton("EditorInterface")
	_frames += 1
	if _frames < SETTLE_FRAMES:
		return false

	var t := _frames - SETTLE_FRAMES
	var index := t / FRAMES_PER_SCENE
	var phase := t % FRAMES_PER_SCENE

	if index >= _paths.size():
		if not _materials_done:
			_materials_done = true
			# Opt-in: this pass used to run on every invocation, including
			# ONLY= runs aimed at a single scene, and re-saving a material can
			# mint it a NEW uid (it silently did that to mat_gunmetal.tres).
			# For a material scenes actually reference, that invalidates the
			# uid recorded in every referring file. The materials already have
			# their uids, so this is only needed for a newly added one.
			if OS.get_environment("MATERIALS") != "":
				_save_materials()
		print("saved %d scene(s), %d failure(s)" % [_saved, _failed])
		quit(1 if _failed > 0 else 0)
		return true

	var path := _paths[index]
	if phase == 0:
		ei.open_scene_from_path(path)
	elif phase == FRAMES_PER_SCENE - 1:
		var root: Node = ei.get_edited_scene_root()
		# Guard against saving the previously open tab if this one did not
		# become current in time -- that would write the wrong file.
		if root == null or root.scene_file_path != path:
			printerr("did not become the edited scene: %s (got %s)"
					% [path, root.scene_file_path if root else "<null>"])
			_failed += 1
			return false
		var err: int = ei.save_scene()
		if err != OK:
			printerr("save failed (%d): %s" % [err, path])
			_failed += 1
			return false
		_saved += 1
		print("saved ", path)
	return false


## Materials have no editor "open" step; a plain load/save inside the editor
## picks up the uid the same way.
func _save_materials() -> void:
	var mats := PackedStringArray()
	_collect("res://assets/materials", ".tres", mats)
	mats.sort()
	for path in mats:
		var res := load(path)
		if res == null:
			printerr("load failed: ", path)
			_failed += 1
			continue
		res.take_over_path(path)
		var err := ResourceSaver.save(res, path)
		if err != OK:
			printerr("save failed (%d): %s" % [err, path])
			_failed += 1
			continue
		print("saved ", path)


func _collect(dir_path: String, suffix: String, into: PackedStringArray) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		var full := dir_path.path_join(name)
		if dir.current_is_dir():
			_collect(full, suffix, into)
		elif name.ends_with(suffix):
			into.append(full)
		name = dir.get_next()
	dir.list_dir_end()
