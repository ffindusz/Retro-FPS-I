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
			print("after O on title: options=%s title=%s (expect true false)"
					% [options.visible, start.visible])
			_key(KEY_D)  # sensitivity row starts selected: +10%
			_next(200)
		2:
			print("sensitivity after D: %.2f (expect 1.10)" % settings.sensitivity)
			_key(KEY_S)  # down to music row
			_key(KEY_A)
			_key(KEY_A)
			_key(KEY_A)
			_next(300)
		3:
			var music_db := AudioServer.get_bus_volume_db(
					AudioServer.get_bus_index("Music"))
			print("music after 3xA: %.1f bus_db=%.1f (expect 0.7, ~-3.1)"
					% [settings.music_volume, music_db])
			_key(KEY_S)  # down to sfx row
			_key(KEY_A)  # sfx to 0.9
			_key(KEY_S)  # down to dither row
			_key(KEY_D)  # toggle off
			_next(300)
		4:
			var mat: ShaderMaterial = current_scene.get_node("ViewportContainer").material
			print("dither after toggle: %s strength=%.1f levels=%.0f (expect false 0.0 256)"
					% [settings.dither,
					float(mat.get_shader_parameter("dither_strength")),
					float(mat.get_shader_parameter("color_levels"))])
			_key(KEY_ESCAPE)
			_next(400)
		5:
			print("after ESC: options=%s title=%s (expect false true)"
					% [options.visible, start.visible])
			var cfg := ConfigFile.new()
			var err := cfg.load(SETTINGS_PATH)
			print("cfg reload: err=%d sens=%.2f music=%.1f sfx=%.1f dither=%s (expect 0 1.10 0.7 0.9 false)"
					% [err, float(cfg.get_value("input", "sensitivity", -1.0)),
					float(cfg.get_value("audio", "music_volume", -1.0)),
					float(cfg.get_value("audio", "sfx_volume", -1.0)),
					str(cfg.get_value("video", "dither", true))])
			current_scene.start_game(0)
			_next(1000)
		6:
			_key(KEY_ESCAPE)  # open pause
			_next(400)
		7:
			print("paused: overlay=%s (expect true)" % pause.visible)
			_key(KEY_O)
			_next(300)
		8:
			print("after O in pause: options=%s pause=%s paused=%s (expect true false true)"
					% [options.visible, pause.visible, paused])
			_key(KEY_ESCAPE)
			_next(300)
		9:
			print("after ESC in options: options=%s pause=%s paused=%s (expect false true true)"
					% [options.visible, pause.visible, paused])
			_restore_backup()
			print("settings test done")
			return true
	return false


func _restore_backup() -> void:
	if _had_backup:
		var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
		f.store_buffer(_backup)
		f.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_PATH))
