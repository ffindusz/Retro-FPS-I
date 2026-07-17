extends SceneTree
## Debug helper: audio output diagnostic. Prints the audio device state and
## plays the rocket explosion + a few seconds of music. Run WITHOUT --headless
## and LISTEN:
##   Godot_v4.7-stable_win64_console.exe --path . -s tools/test_audio.gd

var _t0 := 0
var _started := false
var _boomed_again := false
var _music: AudioStreamPlayer
var _boom: AudioStreamPlayer


func _initialize() -> void:
	print("driver output device: ", AudioServer.get_output_device())
	print("available devices:    ", AudioServer.get_output_device_list())
	print("master bus: volume_db=%.1f muted=%s" % [
			AudioServer.get_bus_volume_db(0), AudioServer.is_bus_mute(0)])
	_music = AudioStreamPlayer.new()
	_music.stream = load("res://assets/audio/music_ambient.wav")
	_music.volume_db = -6.0
	root.add_child(_music)
	_boom = AudioStreamPlayer.new()
	_boom.stream = load("res://assets/audio/explosion.wav")
	root.add_child(_boom)


func _process(_delta: float) -> bool:
	if not _started:
		# Nodes can only play once the tree is running, not in _initialize.
		_started = true
		_t0 = Time.get_ticks_msec()
		_music.play()
		_boom.play()
		return false
	var t := Time.get_ticks_msec() - _t0
	if t > 2500 and not _boomed_again:
		_boomed_again = true
		_boom.play()
		print("music playing=%s boom playing=%s" % [_music.playing, _boom.playing])
	return t > 6000
