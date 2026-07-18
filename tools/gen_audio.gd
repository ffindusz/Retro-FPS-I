extends SceneTree
## One-off generator for placeholder SFX (mono 16-bit 22050 Hz WAVs).
## Deterministic (fixed seed). Run from the project root:
##   Godot_v4.7-stable_win64_console.exe --headless --path . -s tools/gen_audio.gd

const RATE := 22050

var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.seed = 4004
	# The gun sounds were replaced by the Heretic-style weapon sounds saved
	# after the music (wand_zap etc.), but their generators still run
	# (unsaved) to burn their share of the RNG stream so everything below
	# regenerates byte-identical. _gen_plasma consumed no RNG and is gone.
	_gen_pistol()
	_gen_shotgun()
	_gen_launcher()
	_save("explosion", _gen_explosion())
	_save("click", _gen_click())
	_save("hurt", _gen_hurt())
	# The generic enemy hit/die blips were replaced by the skeleton bone
	# sounds saved after cast (bone_hit/bone_die), but their generators still
	# run (unsaved) to burn their share of the RNG stream.
	_gen_enemy_hit()
	_gen_enemy_die()
	_save("boss_roar", _gen_boss_roar())
	# New generators go LAST so earlier outputs stay byte-identical (the
	# shared RNG stream is consumed in _init order).
	_save("switch", _gen_switch())
	_save("teleport", _gen_teleport())
	_save("pickup", _gen_pickup())
	_save("heal", _gen_heal())
	_save("step", _gen_step())
	_save("land", _gen_land())
	# Barrels are decorative now and barrel_boom.wav was deleted, but the
	# generator still runs (unsaved) to burn its share of the RNG stream so
	# the wavs generated after it regenerate byte-identical.
	_gen_barrel_boom()
	# Music: by far the slowest. It uses a PRIVATE RNG, so it neither
	# consumes nor disturbs the shared stream — every other wav stays
	# byte-identical no matter how the track changes.
	_save("music_ambient", _gen_music(), 11025)
	# Order below is load-bearing for the shared RNG stream: keep these in
	# the order they were added so each regenerates byte-identical.
	_save("player_die", _gen_player_die())
	_save("wand_zap", _gen_wand_zap())
	_save("crossbow", _gen_crossbow())
	_save("staff_fire", _gen_staff_fire())
	_save("tome_pulse", _gen_tome_pulse())  # pure tones: no RNG consumed
	_save("swing", _gen_swing())
	_save("cast", _gen_cast())
	_save("bone_rattle", _gen_bone_rattle())
	_save("bone_hit", _gen_bone_hit())
	_save("bone_die", _gen_bone_die())
	_save("crystal_arm", _gen_crystal_arm())  # pure tones: no RNG consumed
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


## Wand: bright arcane zap — a steep falling shimmer with a sparkle tail.
func _gen_wand_zap() -> PackedFloat32Array:
	var dur := 0.14
	var out := PackedFloat32Array()
	for i in int(dur * RATE):
		var t := float(i) / RATE
		var freq := 1500.0 - 6200.0 * t
		var s := sin(TAU * freq * t) * 0.55 + sin(TAU * freq * 1.5 * t) * 0.25
		s += _rng.randf_range(-0.12, 0.12) * (1.0 - t / dur)
		out.append(s * _env(t, dur, 1.4))
	return out


## Crossbow: string snap into a woody thunk.
func _gen_crossbow() -> PackedFloat32Array:
	var dur := 0.3
	var out := PackedFloat32Array()
	var low := 0.0
	for i in int(dur * RATE):
		var t := float(i) / RATE
		var snap := _rng.randf_range(-1.0, 1.0) * maxf(1.0 - t / 0.02, 0.0)
		var twang := sin(TAU * 340.0 * t) * 0.4 * exp(-t * 30.0) \
				+ sin(TAU * 170.0 * t) * 0.5 * exp(-t * 18.0)
		low = lerpf(low, _rng.randf_range(-1.0, 1.0), 0.28)
		var thunk := low * 0.9 * _env(t, dur, 2.6)
		out.append(clampf(snap * 0.8 + twang + thunk, -1.0, 1.0))
	return out


## Fire staff: a breathy launch whoosh with an ember-crackle tail and a
## low fireball body.
func _gen_staff_fire() -> PackedFloat32Array:
	var dur := 0.5
	var out := PackedFloat32Array()
	var low := 0.0
	for i in int(dur * RATE):
		var t := float(i) / RATE
		low = lerpf(low, _rng.randf_range(-1.0, 1.0), 0.18)
		var whoosh := low * 1.3 * sin(PI * t / dur)
		var crackle := 0.0
		if _rng.randf() < 0.18:
			crackle = _rng.randf_range(-0.5, 0.5) * (t / dur)
		var body := sin(TAU * (110.0 - 50.0 * t) * t) * 0.35 * _env(t, dur, 1.5)
		out.append(clampf(whoosh + crackle + body, -1.0, 1.0))
	return out


## Tome: a soft two-tone arcane chime, gentle enough for the rapid fire.
func _gen_tome_pulse() -> PackedFloat32Array:
	var dur := 0.09
	var out := PackedFloat32Array()
	for i in int(dur * RATE):
		var t := float(i) / RATE
		var s := sin(TAU * 620.0 * t) * 0.4 + sin(TAU * 930.0 * t) * 0.3 \
				+ sin(TAU * 1240.0 * t) * 0.15
		out.append(s * _env(t, dur, 1.2))
	return out


## Melee swing: a short airy whoosh (enemy punch, hit or miss).
func _gen_swing() -> PackedFloat32Array:
	var dur := 0.18
	var out := PackedFloat32Array()
	var low := 0.0
	for i in int(dur * RATE):
		var t := float(i) / RATE
		# Filter opens over the swing so the whoosh sweeps bright.
		low = lerpf(low, _rng.randf_range(-1.0, 1.0), 0.25 + 0.35 * t / dur)
		out.append(low * 0.9 * sin(PI * t / dur))
	return out


## Enemy spellcast: a rising arcane shimmer with a breathy release
## (mage bolts, boss fireball volleys).
func _gen_cast() -> PackedFloat32Array:
	var dur := 0.3
	var out := PackedFloat32Array()
	var low := 0.0
	for i in int(dur * RATE):
		var t := float(i) / RATE
		var freq := 500.0 + 900.0 * t
		var shimmer := sin(TAU * freq * t) * 0.4 + sin(TAU * freq * 1.5 * t) * 0.2
		low = lerpf(low, _rng.randf_range(-1.0, 1.0), 0.2)
		out.append(clampf((shimmer + low * 0.4) * _env(t, dur, 1.1), -1.0, 1.0))
	return out


## Mixes a damped woody knock (bone click) into `buf` at `start` seconds:
## a fast-decaying resonant sine with a noise transient on top. The shared
## primitive for the skeleton vocalizations below.
func _add_click(buf: PackedFloat32Array, start: float, freq: float, amp: float) -> void:
	var dur := 0.03
	var s0 := int(start * RATE)
	for i in int(dur * RATE):
		var idx := s0 + i
		if idx >= buf.size():
			return
		var t := float(i) / RATE
		var s := sin(TAU * freq * t) * exp(-t * 160.0)
		s += _rng.randf_range(-0.3, 0.3) * exp(-t * 400.0)
		buf[idx] = clampf(buf[idx] + s * amp, -1.0, 1.0)


## Skeleton awaken: a dry bone rattle that quickens as the bones stir, over
## a faint rising moan.
func _gen_bone_rattle() -> PackedFloat32Array:
	var dur := 0.55
	var out := PackedFloat32Array()
	out.resize(int(dur * RATE))
	var t := 0.06
	var gap := 0.085
	while t < dur - 0.05:
		_add_click(out, t, _rng.randf_range(700.0, 1500.0), _rng.randf_range(0.25, 0.45))
		t += gap
		gap = maxf(gap * 0.82, 0.018)
	for i in out.size():
		var tt := float(i) / RATE
		var moan := sin(TAU * (95.0 + 60.0 * tt / dur) * tt) * 0.16 * sin(PI * tt / dur)
		out[i] = clampf(out[i] + moan, -1.0, 1.0)
	return out


## Skeleton pain: a sharp double bone-knock.
func _gen_bone_hit() -> PackedFloat32Array:
	var dur := 0.14
	var out := PackedFloat32Array()
	out.resize(int(dur * RATE))
	_add_click(out, 0.0, 1050.0, 0.9)
	_add_click(out, 0.045, 780.0, 0.7)
	return out


## Skeleton death: a collapsing clatter — knocks thinning out and falling in
## pitch as the pile settles, over a soft floor thud.
func _gen_bone_die() -> PackedFloat32Array:
	var dur := 0.7
	var out := PackedFloat32Array()
	out.resize(int(dur * RATE))
	var t := 0.0
	var gap := 0.022
	while t < 0.5:
		var freq := _rng.randf_range(500.0, 1300.0) * (1.0 - 0.4 * t / 0.5)
		_add_click(out, t, freq, _rng.randf_range(0.5, 0.9) * (1.0 - 0.6 * t / 0.5))
		t += gap
		gap *= 1.28
	var thud_start := int(0.16 * RATE)
	for i in int(0.3 * RATE):
		var tt := float(i) / RATE
		var idx := thud_start + i
		if idx >= out.size():
			break
		out[idx] = clampf(out[idx] + sin(TAU * 85.0 * tt) * 0.5 * _env(tt, 0.3, 1.8), -1.0, 1.0)
	return out


## Player pain: falling sine.
func _gen_hurt() -> PackedFloat32Array:
	var dur := 0.18
	var out := PackedFloat32Array()
	for i in int(dur * RATE):
		var t := float(i) / RATE
		out.append(sin(TAU * (440.0 - 1300.0 * t) * t) * 0.7 * _env(t, dur, 1.2))
	return out


## Former enemy hit blip (replaced by bone_hit). No longer saved — kept only
## as an RNG burn so later outputs stay byte-identical.
func _gen_enemy_hit() -> PackedFloat32Array:
	var dur := 0.07
	var out := PackedFloat32Array()
	for i in int(dur * RATE):
		var t := float(i) / RATE
		out.append(signf(sin(TAU * 300.0 * t)) * 0.4 * _env(t, dur, 1.2))
	return out


## Former enemy death groan (replaced by bone_die). No longer saved — kept
## only as an RNG burn so later outputs stay byte-identical.
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


## Dark fantasy music: a 40 s seamless 16-bar loop in E Phrygian — chord
## pads (Em / F / Dm / G) crossfading at bar boundaries under a pulsing
## eighth-note bass, a sparse haunting lead, and tom-and-rattle percussion.
## Pad oscillators and LFOs are quantized to whole cycles per loop so the
## seam is click-free; every event-based voice closes its envelope before
## the loop point. Uses a PRIVATE RNG so the shared stream (and with it
## every other wav) stays byte-identical. 11025 Hz for lo-fi warmth.
func _gen_music() -> PackedFloat32Array:
	var rate := 11025
	var beat := 60.0 / 96.0  # 96 BPM
	var bar := beat * 4.0
	var bars := 16
	var dur := bar * bars  # 40.0 s
	var rng := RandomNumberGenerator.new()
	rng.seed = 1349
	# Quantize a frequency to complete whole cycles over the loop.
	var q := func(f: float) -> float: return roundf(f * dur) / dur
	var triads := [
		[82.41, 98.0, 123.47],   # Em
		[87.31, 110.0, 130.81],  # F
		[73.42, 87.31, 110.0],   # Dm
		[98.0, 123.47, 146.83],  # G
	]
	var bass_hz := [41.2, 43.65, 36.71, 49.0]
	# Chord per bar. The last two Em bars resolve into bar 0's Em, so the
	# seam crossfade blends identical pads.
	var prog := [0, 0, 1, 1, 0, 0, 2, 2, 0, 0, 1, 1, 3, 1, 0, 0]
	# Pad components per chord type: [freq, amp, lfo_freq, lfo_phase], a
	# straight layer + a detuned layer per triad note.
	var comps := []
	for c in 4:
		var list := []
		for k in 3:
			var f: float = triads[c][k]
			list.append([q.call(f), 0.14, q.call(0.13 + 0.03 * k), float(k) * 2.1])
			list.append([q.call(f * 1.007), 0.09, q.call(0.11 + 0.02 * k), float(k) * 1.3])
		comps.append(list)
	var n := int(dur * rate)
	var out := PackedFloat32Array()
	out.resize(n)
	# Continuous pad, smoothstep-crossfaded over the last 0.5 s of each bar
	# (wrapping 15 -> 0) so chord changes and the loop seam never click.
	var fade := 0.5
	for i in n:
		var t := float(i) / rate
		var b := int(t / bar)
		var tb := t - float(b) * bar
		b = b % bars
		var f := clampf((tb - (bar - fade)) / fade, 0.0, 1.0)
		f = f * f * (3.0 - 2.0 * f)
		var cur: int = prog[b]
		var nxt: int = prog[(b + 1) % bars]
		if f <= 0.0 or cur == nxt:
			out[i] = _pad(comps[cur], t)
		else:
			out[i] = _pad(comps[cur], t) * (1.0 - f) + _pad(comps[nxt], t) * f
	# Bass: eighth-note root pulses, accented on the downbeats.
	for b in bars:
		var root: float = bass_hz[prog[b]]
		for e in 8:
			var amp := 0.30 if e % 2 == 0 else 0.19
			_add_pluck(out, rate, float(b) * bar + float(e) * beat * 0.5, root, amp)
	# Lead: [start_beat, length_beats, freq]. Two eight-bar phrases — a low
	# brooding statement, then a higher answer that peaks on the G bar.
	var a3 := 220.0
	var b3 := 246.94
	var c4 := 261.63
	var d4 := 293.66
	var e4 := 329.63
	var f4 := 349.23
	var g4 := 392.0
	var melody := [
		[4, 3, e4], [7, 1, f4],
		[8, 2, e4], [10, 2, c4], [12, 3, a3],
		[20, 2, b3], [22, 2, c4],
		[24, 3, d4], [27, 1, c4], [28, 2, a3], [30, 2, b3],
		[32, 3, e4], [35, 1, g4], [36, 2, f4], [38, 2, e4],
		[40, 3, f4], [43, 1, e4], [44, 2, c4], [46, 2, d4],
		[48, 2, g4], [50, 2, d4],
		[52, 2, f4], [54, 2, c4],
		[56, 4, e4], [60, 3, b3],
	]
	for ev: Array in melody:
		_add_lead(out, rate, float(ev[0]) * beat, float(ev[1]) * beat * 0.92, ev[2], 0.14)
	# Percussion: low toms on beats 1 and 3, a pickup ending each 4-bar
	# phrase, and offbeat rattle ticks through the loop's back half.
	for b in bars:
		var t0 := float(b) * bar
		_add_tom(out, rate, t0, 0.40)
		_add_tom(out, rate, t0 + 2.0 * beat, 0.30)
		if b % 4 == 3:
			_add_tom(out, rate, t0 + 3.5 * beat, 0.22)
		if b >= 8:
			_add_tick(out, rate, rng, t0 + 1.5 * beat, 0.10)
			_add_tick(out, rate, rng, t0 + 3.5 * beat, 0.10)
	for i in n:
		out[i] = clampf(out[i] * 0.55, -1.0, 1.0)
	return out


## One pad voice: tremolo'd sines from a precomputed component list.
func _pad(list: Array, t: float) -> float:
	var s := 0.0
	for comp: Array in list:
		var trem: float = 0.85 + 0.15 * sin(TAU * comp[2] * t + comp[3])
		s += sin(TAU * comp[0] * t) * comp[1] * trem
	return s


## Mixes a plucked bass note into `buf`: saw+sine with an exp-decay envelope.
func _add_pluck(buf: PackedFloat32Array, rate: int, start: float,
		freq: float, amp: float) -> void:
	var dur := 0.28
	var s0 := int(start * rate)
	for i in int(dur * rate):
		var idx := s0 + i
		if idx >= buf.size():
			return
		var t := float(i) / rate
		var s: float = (2.0 * fmod(freq * t, 1.0) - 1.0) * 0.6 + sin(TAU * freq * t) * 0.5
		buf[idx] += s * amp * minf(t / 0.01, 1.0) * exp(-t * 9.0)


## Mixes a lead note into `buf`: sine+saw blend with delay vibrato and a
## trapezoid envelope that closes inside the note length.
func _add_lead(buf: PackedFloat32Array, rate: int, start: float, dur: float,
		freq: float, amp: float) -> void:
	var s0 := int(start * rate)
	for i in int(dur * rate):
		var idx := s0 + i
		if idx >= buf.size():
			return
		var t := float(i) / rate
		var ph := TAU * freq * t + 0.35 * sin(TAU * 5.2 * t) * minf(t / 0.4, 1.0)
		var s := sin(ph) * 0.8 + (2.0 * fmod(freq * t, 1.0) - 1.0) * 0.25
		var env := minf(t / 0.06, 1.0) * clampf((dur - t) / 0.18, 0.0, 1.0)
		buf[idx] += s * amp * env


## Mixes a low tom hit into `buf`: a pitch-dropping sine thump.
func _add_tom(buf: PackedFloat32Array, rate: int, start: float, amp: float) -> void:
	var dur := 0.22
	var s0 := int(start * rate)
	for i in int(dur * rate):
		var idx := s0 + i
		if idx >= buf.size():
			return
		var t := float(i) / rate
		buf[idx] += sin(TAU * (62.0 - 40.0 * t) * t) * amp * minf(t / 0.005, 1.0) * exp(-t * 16.0)


## Mixes a dry rattle tick into `buf` (noise burst). `rng` is the music's
## private stream — never the shared _rng.
func _add_tick(buf: PackedFloat32Array, rate: int, rng: RandomNumberGenerator,
		start: float, amp: float) -> void:
	var dur := 0.03
	var s0 := int(start * rate)
	for i in int(dur * rate):
		var idx := s0 + i
		if idx >= buf.size():
			return
		var t := float(i) / rate
		buf[idx] += rng.randf_range(-1.0, 1.0) * amp * exp(-t * 180.0)


## Crystal arming (the emerald awakens): struck-crystal chime — detuned
## partial pairs beat against each other for shimmer — over a low hum that
## swells in beneath and fades with the ring-out. Pure tones: no RNG.
func _gen_crystal_arm() -> PackedFloat32Array:
	var dur := 1.5
	var out := PackedFloat32Array()
	# [freq, amplitude, decay power] — higher partials ring shorter.
	var partials := [
		[660.0, 0.30, 1.6], [663.5, 0.20, 1.6],
		[990.0, 0.20, 2.2], [1567.0, 0.14, 3.0], [2217.0, 0.09, 4.0],
	]
	for i in int(dur * RATE):
		var t := float(i) / RATE
		var s := 0.0
		for p: Array in partials:
			s += sin(TAU * p[0] * t) * p[1] * _env(t, dur, p[2])
		var shimmer := 0.88 + 0.12 * sin(TAU * 5.5 * t)
		var hum := (sin(TAU * 110.0 * t) * 0.16 + sin(TAU * 165.0 * t) * 0.10) \
				* minf(t / 0.5, 1.0) * _env(t, dur, 1.2)
		out.append((s * shimmer + hum) * minf(t / 0.04, 1.0))
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
