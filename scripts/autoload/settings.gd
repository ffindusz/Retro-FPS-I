extends Node
## Autoload for persistent user settings: mouse sensitivity, music/SFX
## volume (via the Music/SFX audio buses in default_bus_layout.tres), and
## the PS1 dither post filter. Loaded from user://settings.cfg on boot;
## the options screen writes values, then calls apply() + save_settings().
## Video settings can't be applied from here (the post material lives in
## main.tscn), so main.gd listens for `changed`.

signal changed

const CONFIG_PATH := "user://settings.cfg"

const SENSITIVITY_MIN := 0.2
const SENSITIVITY_MAX := 3.0

## Multiplier on top of the player controller's base mouse sensitivity.
var sensitivity := 1.0
var music_volume := 1.0
var sfx_volume := 1.0
var dither := true


func _ready() -> void:
	load_settings()


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) == OK:
		sensitivity = clampf(float(cfg.get_value("input", "sensitivity", 1.0)),
				SENSITIVITY_MIN, SENSITIVITY_MAX)
		music_volume = clampf(float(cfg.get_value("audio", "music_volume", 1.0)), 0.0, 1.0)
		sfx_volume = clampf(float(cfg.get_value("audio", "sfx_volume", 1.0)), 0.0, 1.0)
		dither = bool(cfg.get_value("video", "dither", true))
	apply()


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("input", "sensitivity", sensitivity)
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.set_value("video", "dither", dither)
	cfg.save(CONFIG_PATH)


func apply() -> void:
	_apply_bus("Music", music_volume)
	_apply_bus("SFX", sfx_volume)
	changed.emit()


func _apply_bus(bus_name: String, volume: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	# Mute outright at zero: linear_to_db(0) is -inf, which the mixer
	# dislikes, and a hard mute is what "0%" means anyway.
	AudioServer.set_bus_mute(idx, volume <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(volume, 0.001)))
