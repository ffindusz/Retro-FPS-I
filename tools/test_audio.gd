extends SceneTree
## Debug helper: audio output diagnostic. Prints the audio device state and
## plays each key gameplay SFX in sequence over the music. Run WITHOUT
## --headless and LISTEN:
##   Godot_v4.7-stable_win64_console.exe --path . -s tools/test_audio.gd

const SEQUENCE := [
	["wand_zap (slot 1)", "res://assets/audio/wand_zap.wav"],
	["crossbow (slot 2)", "res://assets/audio/crossbow.wav"],
	["staff_fire (slot 3)", "res://assets/audio/staff_fire.wav"],
	["tome_pulse (slot 4)", "res://assets/audio/tome_pulse.wav"],
	["swing (enemy melee)", "res://assets/audio/swing.wav"],
	["cast (enemy spell)", "res://assets/audio/cast.wav"],
	["pickup (ammo collect)", "res://assets/audio/pickup.wav"],
	["heal (medkit collect)", "res://assets/audio/heal.wav"],
	["hurt (player hit)", "res://assets/audio/hurt.wav"],
	["player_die (death sting)", "res://assets/audio/player_die.wav"],
	["explosion (fireball)", "res://assets/audio/explosion.wav"],
]
const STEP_MS := 1400
const LEAD_IN_MS := 600

var _t0 := 0
var _started := false
var _index := 0
var _music: AudioStreamPlayer
var _sfx: AudioStreamPlayer


func _initialize() -> void:
	print("driver output device: ", AudioServer.get_output_device())
	print("available devices:    ", AudioServer.get_output_device_list())
	print("master bus: volume_db=%.1f muted=%s" % [
			AudioServer.get_bus_volume_db(0), AudioServer.is_bus_mute(0)])
	_music = AudioStreamPlayer.new()
	_music.stream = load("res://assets/audio/music_ambient.wav")
	_music.volume_db = -6.0
	root.add_child(_music)
	_sfx = AudioStreamPlayer.new()
	root.add_child(_sfx)


func _process(_delta: float) -> bool:
	if not _started:
		# Nodes can only play once the tree is running, not in _initialize.
		_started = true
		_t0 = Time.get_ticks_msec()
		_music.play()
		return false
	var t := Time.get_ticks_msec() - _t0
	if _index < SEQUENCE.size() and t >= LEAD_IN_MS + _index * STEP_MS:
		print("playing: ", SEQUENCE[_index][0])
		_sfx.stream = load(SEQUENCE[_index][1])
		_sfx.play()
		_index += 1
	return t > LEAD_IN_MS + SEQUENCE.size() * STEP_MS + 1200
