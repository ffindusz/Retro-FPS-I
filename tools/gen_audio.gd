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
	_save("pickup", _gen_pickup())
	_save("heal", _gen_heal())
	_save("step", _gen_step())
	_save("land", _gen_land())
	_save("plasma", _gen_plasma())  # pure tones: no RNG consumed
	# Barrels are decorative now and barrel_boom.wav was deleted, but the
	# generator still runs (unsaved) to burn its share of the RNG stream so
	# music_ambient.wav regenerates byte-identical.
	_gen_barrel_boom()
	# Music last: it is by far the slowest and consumes the RNG stream after
	# everything else, keeping all earlier outputs byte-identical.
	_save("music_ambient", _gen_music(), 11025)
	# Added after music (not before) so the music's RNG stream — and with it
	# every wav above — regenerates byte-identical.
	_save("player_die", _gen_player_die())
	print("SFX written to res://assets/audio/")
	quit()


func _save(sfx_name: String, samples: PackedFloat32Array, rate := RATE) -> void:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		var v := int(clampf(samples[i], -1.0, 1.0) * 32000.0)
		data.encode_s16(i * 2, v)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
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


## Former barrel explosion (sharp metallic clang into a deep boom). No longer
## saved — kept only as an RNG burn so later outputs stay byte-identical.
func _gen_barrel_boom() -> PackedFloat32Array:
	var dur := 0.55
	var out := PackedFloat32Array()
	var low := 0.0
	for i in int(dur * RATE):
		var t := float(i) / RATE
		# bright metallic crack for the first ~30 ms
		var crack := _rng.randf_range(-1.0, 1.0) * maxf(1.0 - t / 0.03, 0.0)
		# decaying metallic ring
		var ring := sin(TAU * 640.0 * t) * 0.35 * exp(-t * 14.0)
		# deep rumble body
		low = lerpf(low, _rng.randf_range(-1.0, 1.0), 0.09)
		var boom := (low * 2.0 + sin(TAU * (65.0 - 30.0 * t) * t) * 0.6) * _env(t, dur, 1.7)
		out.append(clampf(crack * 0.9 + ring + boom, -1.0, 1.0))
	return out


## Player death: a long falling groan sinking into a dull final rumble,
## clearly heavier than the short hurt yelp.
func _gen_player_die() -> PackedFloat32Array:
	var dur := 1.1
	var out := PackedFloat32Array()
	var low := 0.0
	for i in int(dur * RATE):
		var t := float(i) / RATE
		var freq := 210.0 - 130.0 * t
		var groan := sin(TAU * freq * t) * 0.5 + sin(TAU * freq * 0.5 * t) * 0.3
		low = lerpf(low, _rng.randf_range(-1.0, 1.0), 0.06)
		var rumble := low * 0.9 * minf(t * 3.0, 1.0)
		out.append(clampf(groan * _env(t, dur, 1.3) + rumble * _env(t, dur, 2.2), -1.0, 1.0))
	return out


## Plasma rifle: quick descending zap.
func _gen_plasma() -> PackedFloat32Array:
	var dur := 0.08
	var out := PackedFloat32Array()
	for i in int(dur * RATE):
		var t := float(i) / RATE
		var freq := 1250.0 - 8000.0 * t
		var s := sin(TAU * freq * t) * 0.55 + signf(sin(TAU * freq * 0.5 * t)) * 0.2
		out.append(s * _env(t, dur, 1.3))
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


## Ammo pickup: quick two-tone "chik-chunk".
func _gen_pickup() -> PackedFloat32Array:
	var dur := 0.14
	var out := PackedFloat32Array()
	for i in int(dur * RATE):
		var t := float(i) / RATE
		var freq := 520.0 if t < 0.06 else 780.0
		out.append(signf(sin(TAU * freq * t)) * 0.35 * _env(t, dur, 1.0))
	return out


## Health pickup: soft rising sine.
func _gen_heal() -> PackedFloat32Array:
	var dur := 0.28
	var out := PackedFloat32Array()
	for i in int(dur * RATE):
		var t := float(i) / RATE
		var freq := 300.0 + 900.0 * t
		out.append(sin(TAU * freq * t) * 0.5 * _env(t, dur, 1.1))
	return out


## Footstep: short lowpassed noise scuff.
func _gen_step() -> PackedFloat32Array:
	var dur := 0.09
	var out := PackedFloat32Array()
	var low := 0.0
	for i in int(dur * RATE):
		var t := float(i) / RATE
		low = lerpf(low, _rng.randf_range(-1.0, 1.0), 0.22)
		out.append(low * 1.1 * _env(t, dur, 2.4))
	return out


## Landing thud: deeper noise burst + low sine knock.
func _gen_land() -> PackedFloat32Array:
	var dur := 0.2
	var out := PackedFloat32Array()
	var low := 0.0
	for i in int(dur * RATE):
		var t := float(i) / RATE
		low = lerpf(low, _rng.randf_range(-1.0, 1.0), 0.12)
		var knock := sin(TAU * 70.0 * t) * 0.5
		out.append((low * 1.3 + knock) * _env(t, dur, 2.0))
	return out


## Dark ambient music: a 19.2 s seamless loop of slowly crossfading minor
## chord pads (Am -> F -> Dm -> E) over a pulsing sub bass. Every oscillator
## and LFO frequency is quantized to whole cycles per loop so the seam is
## click-free. Rendered at 11025 Hz for lo-fi warmth (and speed).
func _gen_music() -> PackedFloat32Array:
	var rate := 11025
	var dur := 19.2
	var chord_len := dur / 4.0
	var fade := 1.0
	# Quantize a frequency to complete whole cycles over the loop.
	var q := func(f: float) -> float: return roundf(f * dur) / dur
	var chords_hz := [
		[110.0, 130.81, 164.81],  # Am
		[87.31, 130.81, 174.61],  # F
		[73.42, 110.0, 146.83],   # Dm
		[82.41, 123.47, 164.81],  # E
	]
	# Precompute pad components: [freq, amp, lfo_freq, lfo_phase] per chord.
	var comps := []
	for c in 4:
		var list := []
		for k in 3:
			var f: float = chords_hz[c][k]
			list.append([q.call(f), 0.16, q.call(0.14 + 0.03 * k), float(k) * 2.1])
			list.append([q.call(f * 1.006), 0.10, q.call(0.11 + 0.02 * k), float(k) * 1.3])
		comps.append(list)
	var bass_hz := [q.call(55.0), q.call(43.65), q.call(36.71), q.call(41.2)]
	var n := int(dur * rate)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := float(i) / rate
		var s := 0.0
		for c in 4:
			# Triangular crossfade window centered on this chord's slot,
			# evaluated with wraparound so chord 0 fades in over the loop seam.
			var center := (float(c) + 0.5) * chord_len
			var dt: float = absf(fposmod(t - center + dur / 2.0, dur) - dur / 2.0)
			var gain := clampf((chord_len / 2.0 + fade / 2.0 - dt) / fade, 0.0, 1.0)
			if gain <= 0.0:
				continue
			for comp: Array in comps[c]:
				var trem: float = 0.85 + 0.15 * sin(TAU * comp[2] * t + comp[3])
				s += sin(TAU * comp[0] * t) * comp[1] * trem * gain
		# Sub-bass pulse every 1.2 s, root of the chord the pulse starts in.
		var pulse_t := fposmod(t, 1.2)
		var pulse_start := t - pulse_t
		var chord_idx := int(fposmod(pulse_start, dur) / chord_len) % 4
		var env := exp(-3.0 * pulse_t) * minf(pulse_t / 0.012, 1.0)
		s += sin(TAU * bass_hz[chord_idx] * t) * 0.5 * env
		out[i] = s * 0.5
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
