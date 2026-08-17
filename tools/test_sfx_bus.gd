extends "res://tools/test_base.gd"
## Audio-mix regression check: proves Fx.spawn_sound (positional SFX) reaches
## the SFX bus. Boots level 1, fires a pickup sound near the player via the
## real Fx.spawn_sound path, and samples the SFX/Music bus peak levels --
## catching "plays but never mixes" bugs (e.g. the SubViewport missing its
## audio_listener_enable_3d, which silenced every 3D sound; test_audio.gd
## can't catch that, it plays raw streams on the root viewport).
## Run WITHOUT --headless (headless uses the dummy audio driver):
##   Godot_v4.7-stable_win64_console.exe --path . -s tools/test_sfx_bus.gd

const PLAYER_PATH := "ViewportContainer/GameViewport/World/Player"

var _t0 := 0
var _spawned := false
var _sfx_peak := -200.0
var _music_peak := -200.0


func _initialize() -> void:
	change_scene_to_file("res://scenes/main.tscn")


func _process(_delta: float) -> bool:
	if current_scene == null:
		return false
	if not _started:
		_started = true
		current_scene.start_game(0)
		return false
	var player := current_scene.get_node_or_null(PLAYER_PATH)
	if player == null:
		return false
	if _t0 == 0:
		_t0 = Time.get_ticks_msec()
		return false
	var t := Time.get_ticks_msec() - _t0
	if t >= 500 and not _spawned:
		_spawned = true
		var fx := load("res://scripts/fx.gd")
		fx.spawn_sound(player, player.global_position + Vector3(0, 1, -1),
				load("res://assets/audio/pickup.wav"), 0.0)
	if _spawned:
		var sfx := AudioServer.get_bus_index("SFX")
		var mus := AudioServer.get_bus_index("Music")
		_sfx_peak = maxf(_sfx_peak, AudioServer.get_bus_peak_volume_left_db(sfx, 0))
		_music_peak = maxf(_music_peak, AudioServer.get_bus_peak_volume_left_db(mus, 0))
	if t > 1600:
		# -50 dB is the "actually mixed" threshold: a bus that never received
		# the sound sits at the -200 floor.
		_expect_greater("SFX bus peak during spawn_sound (dB)", _sfx_peak, -50.0)
		_expect_greater("Music bus peak (dB)", _music_peak, -50.0)
		return _finish()
	return false
