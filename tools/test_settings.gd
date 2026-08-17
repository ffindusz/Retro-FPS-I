extends "res://tools/test_base.gd"
## Smoke test: options screen + settings persistence.
## O on the title swaps in the options screen, A/D adjust the selected row,
## values reach the Music/SFX buses and the post shader, and persist to
## user://settings.cfg; O in the pause menu opens the same screen and Esc
## returns to pause. The machine's real settings.cfg is backed up in step 0
## and restored at the end.
##   Godot_v4.7-stable_win64_console.exe --headless --path . -s tools/test_settings.gd

const SETTINGS_PATH := "user://settings.cfg"

var _backup := PackedByteArray()
var _had_backup := false


func _skip_auto_start() -> bool:
	return true


func _tick(_delta: float) -> bool:
	var options := current_scene.get_node("OptionsScreen")
	var start := current_scene.get_node("StartScreen")
	var pause := current_scene.get_node("PauseScreen")
	var settings: Node = root.get_node("Settings")
	match _step:
		0:
			_had_backup = FileAccess.file_exists(SETTINGS_PATH)
			if _had_backup:
				_backup = FileAccess.get_file_as_bytes(SETTINGS_PATH)
			# Known starting state regardless of this machine's config.
			settings.sensitivity = 1.0
			settings.music_volume = 1.0
			settings.sfx_volume = 1.0
			settings.dither = true
			settings.apply()
			_key(KEY_O)
			_next(300)
		1:
			_expect_true("O on title opens options", options.visible)
			_expect_false("O on title hides the title", start.visible)
			_key(KEY_D)  # sensitivity row starts selected: +10%
			_next(200)
		2:
			_expect_near("sensitivity after D", settings.sensitivity, 1.10)
			_key(KEY_S)  # down to music row
			_key(KEY_A)
			_key(KEY_A)
			_key(KEY_A)
			_next(300)
		3:
			var music_db := AudioServer.get_bus_volume_db(
					AudioServer.get_bus_index("Music"))
			_expect_near("music volume after 3xA", settings.music_volume, 0.7)
			_expect_near("music bus reflects the volume", music_db, -3.1, 0.2)
			_key(KEY_S)  # down to sfx row
			_key(KEY_A)  # sfx to 0.9
			_key(KEY_S)  # down to dither row
			_key(KEY_D)  # toggle off
			_next(300)
		4:
			var mat: ShaderMaterial = current_scene.get_node("ViewportContainer").material
			_expect_false("dither toggled off", settings.dither)
			_expect_near("post shader dither_strength",
					float(mat.get_shader_parameter("dither_strength")), 0.0)
			_expect_near("post shader color_levels",
					float(mat.get_shader_parameter("color_levels")), 256.0)
			_key(KEY_ESCAPE)
			_next(400)
		5:
			_expect_false("ESC closes options", options.visible)
			_expect_true("ESC returns to the title", start.visible)
			var cfg := ConfigFile.new()
			_expect("settings.cfg written", cfg.load(SETTINGS_PATH), OK)
			_expect_near("persisted sensitivity",
					float(cfg.get_value("input", "sensitivity", -1.0)), 1.10)
			_expect_near("persisted music volume",
					float(cfg.get_value("audio", "music_volume", -1.0)), 0.7)
			_expect_near("persisted sfx volume",
					float(cfg.get_value("audio", "sfx_volume", -1.0)), 0.9)
			_expect_false("persisted dither",
					bool(cfg.get_value("video", "dither", true)))
			current_scene.start_game(0)
			_next(1000)
		6:
			_key(KEY_ESCAPE)  # open pause
			_next(400)
		7:
			_expect_true("pause overlay shown", pause.visible)
			_key(KEY_O)
			_next(300)
		8:
			_expect_true("O in pause opens options", options.visible)
			_expect_false("O in pause hides the pause screen", pause.visible)
			_expect_true("tree stays paused under options", paused)
			_key(KEY_ESCAPE)
			_next(300)
		9:
			_expect_false("ESC closes options", options.visible)
			_expect_true("ESC returns to the pause screen", pause.visible)
			_expect_true("tree still paused after closing options", paused)
			_restore_backup()
			return _finish()
	return false


func _restore_backup() -> void:
	if _had_backup:
		var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
		f.store_buffer(_backup)
		f.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_PATH))
