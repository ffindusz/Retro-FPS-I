extends SceneTree
## One-off generator for placeholder SFX (mono 16-bit 22050 Hz WAVs).
## Deterministic (fixed seed). Run from the project root:
##   Godot_v4.7-stable_win64_console.exe --headless --path . -s tools/gen_audio.gd

const RATE := 22050

var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.seed = 4004
	_save("pistol", _gen_pistol())
	_save("shotgun", _gen_shotgun())
	_save("launcher", _gen_launcher())
	_save("explosion", _gen_explosion())
	_save("click", _gen_click())
	_save("hurt", _gen_hurt())
	_save("enemy_hit", _gen_enemy_hit())
	_save("enemy_die", _gen_enemy_die())
	_save("boss_roar", _gen_boss_roar())
	# New generators go LAST so earlier outputs stay byte-identical (the
	# shared RNG stream is consumed in _init order).
	_save("switch", _gen_switch())
	_save("teleport", _gen_teleport())
	print("SFX written to res://assets/audio/")
	quit()


func _save(sfx_name: String, samples: PackedFloat32Array) -> void:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		var v := int(clampf(samples[i], -1.0, 1.0) * 32000.0)
		data.encode_s16(i * 2, v)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = data
	stream.save_to_wav("res://assets/audio/%s.wav" % sfx_name)


func _env(t: float, dur: float, power := 2.0) -> float:
	return pow(maxf(1.0 - t / dur, 0.0), power)


## Short punchy square-wave blip with a downward pitch kick.
func _gen_pistol() -> PackedFloat32Array:
	var dur := 0.09
	var out := PackedFloat32Array()
	for i in int(dur * RATE):
		var t := float(i) / RATE
		var freq := 900.0 - 3200.0 * t
		var s := signf(sin(TAU * freq * t)) * 0.6 + _rng.randf_range(-0.25, 0.25)
		out.append(s * _env(t, dur, 1.6))
	return out


## Heavier noise boom.
func _gen_shotgun() -> PackedFloat32Array:
	var dur := 0.28
	var out := PackedFloat32Array()
	var low := 0.0
	for i in int(dur * RATE):
		var t := float(i) / RATE
		# crude one-pole lowpass over white noise for a deep blast
		low = lerpf(low, _rng.randf_range(-1.0, 1.0), 0.35)
		out.append((low * 1.6 + _rng.randf_range(-0.2, 0.2)) * _env(t, dur, 2.2))
	return out


## Whoosh: noise plus a falling sine thump.
func _gen_launcher() -> PackedFloat32Array:
	var dur := 0.35
	var out := PackedFloat32Array()
	var low := 0.0
	for i in int(dur * RATE):
		var t := float(i) / RATE
		low = lerpf(low, _rng.randf_range(-1.0, 1.0), 0.12)
		var thump := sin(TAU * (180.0 - 240.0 * t) * t) * 0.5
		out.append((low * 1.1 + thump) * _env(t, dur, 1.4))
	return out


## Long deep rumble.
func _gen_explosion() -> PackedFloat32Array:
	var dur := 0.6
	var out := PackedFloat32Array()
	var low := 0.0
	for i in int(dur * RATE):
		var t := float(i) / RATE
		low = lerpf(low, _rng.randf_range(-1.0, 1.0), 0.08)
		out.append(clampf(low * 2.4, -1.0, 1.0) * _env(t, dur, 1.8))
	return out


## Dry-fire tick.
func _gen_click() -> PackedFloat32Array:
	var dur := 0.04
	var out := PackedFloat32Array()
	for i in int(dur * RATE):
		var t := float(i) / RATE
		out.append(signf(sin(TAU * 1400.0 * t)) * 0.3 * _env(t, dur, 1.0))
	return out


## Player pain: falling sine.
func _gen_hurt() -> PackedFloat32Array:
	var dur := 0.18
	var out := PackedFloat32Array()
	for i in int(dur * RATE):
		var t := float(i) / RATE
		out.append(sin(TAU * (440.0 - 1300.0 * t) * t) * 0.7 * _env(t, dur, 1.2))
	return out


## Enemy hit: tiny mid blip.
func _gen_enemy_hit() -> PackedFloat32Array:
	var dur := 0.07
	var out := PackedFloat32Array()
	for i in int(dur * RATE):
		var t := float(i) / RATE
		out.append(signf(sin(TAU * 300.0 * t)) * 0.4 * _env(t, dur, 1.2))
	return out


## Enemy death: longer falling square groan.
func _gen_enemy_die() -> PackedFloat32Array:
	var dur := 0.35
	var out := PackedFloat32Array()
	for i in int(dur * RATE):
		var t := float(i) / RATE
		var freq := 320.0 - 650.0 * t
		out.append(signf(sin(TAU * freq * t)) * 0.45 * _env(t, dur, 1.4))
	return out


## Switch flip: two-tone rising confirm blip.
func _gen_switch() -> PackedFloat32Array:
	var dur := 0.22
	var out := PackedFloat32Array()
	for i in int(dur * RATE):
		var t := float(i) / RATE
		var freq := 620.0 if t < 0.09 else 930.0
		out.append(signf(sin(TAU * freq * t)) * 0.4 * _env(t, dur, 1.0))
	return out


## Teleport: rising sine sweep with shimmer.
func _gen_teleport() -> PackedFloat32Array:
	var dur := 0.5
	var out := PackedFloat32Array()
	for i in int(dur * RATE):
		var t := float(i) / RATE
		var freq := 180.0 + 1400.0 * t
		var s := sin(TAU * freq * t) * 0.55 + sin(TAU * freq * 1.5 * t) * 0.25
		out.append(s * _env(t, dur, 0.7))
	return out


## Boss enrage roar: detuned saws + noise.
func _gen_boss_roar() -> PackedFloat32Array:
	var dur := 0.7
	var out := PackedFloat32Array()
	for i in int(dur * RATE):
		var t := float(i) / RATE
		var f1 := 110.0 - 40.0 * t
		var f2 := f1 * 1.02
		var saw1: float = 2.0 * fmod(f1 * t, 1.0) - 1.0
		var saw2: float = 2.0 * fmod(f2 * t, 1.0) - 1.0
		var s := (saw1 + saw2) * 0.4 + _rng.randf_range(-0.2, 0.2)
		out.append(s * _env(t, dur, 1.1))
	return out
