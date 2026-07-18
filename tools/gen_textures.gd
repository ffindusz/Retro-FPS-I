extends SceneTree
## One-off generator for the Doom/Quake-style 128x128 tiling textures.
## Run from the project root:
##   Godot_v4.7-stable_win64_console.exe --headless --path . -s tools/gen_textures.gd
## Deterministic (fixed seeds) so regeneration produces identical files.

const SIZE := 128


func _init() -> void:
	_gen_wall()
	_gen_floor()
	_gen_metal()
	_gen_crate()
	_gen_barrel_wood()
	_gen_rock()
	_gen_lava()
	_gen_stone()
	_gen_ice()
	_gen_swirl()
	_gen_burst_sheet()
	_gen_muzzle_flash()
	print("Textures written to res://assets/textures/")
	quit()


## Tiling value noise: bilinear interpolation over a coarse random lattice.
func _make_noise(rng: RandomNumberGenerator, cells: int) -> PackedFloat32Array:
	var grid := PackedFloat32Array()
	grid.resize(cells * cells)
	for i in cells * cells:
		grid[i] = rng.randf()
	return grid


func _noise_at(grid: PackedFloat32Array, cells: int, u: float, v: float) -> float:
	var x := u * cells
	var y := v * cells
	var x0 := int(floor(x)) % cells
	var y0 := int(floor(y)) % cells
	var x1 := (x0 + 1) % cells
	var y1 := (y0 + 1) % cells
	var fx: float = x - floor(x)
	var fy: float = y - floor(y)
	var a: float = lerpf(grid[y0 * cells + x0], grid[y0 * cells + x1], fx)
	var b: float = lerpf(grid[y1 * cells + x0], grid[y1 * cells + x1], fx)
	return lerpf(a, b, fy)


func _put(img: Image, x: int, y: int, r: float, g: float, b: float) -> void:
	img.set_pixel(x, y, Color8(
			clampi(int(r), 0, 255), clampi(int(g), 0, 255), clampi(int(b), 0, 255)))


## Doom-brown brick: 64x32 staggered bricks, per-brick tint, inner bevel,
## heavy grime.
func _gen_wall() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2002
	var grime := _make_noise(rng, 8)
	var grime2 := _make_noise(rng, 16)
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	for y in SIZE:
		var row := y / 32
		var offset := (row % 2) * 32
		for x in SIZE:
			var bx := (x + offset) % SIZE
			var in_mortar := (y % 32 < 3) or (bx % 64 < 3)
			var g1 := _noise_at(grime, 8, float(x) / SIZE, float(y) / SIZE)
			var g2 := _noise_at(grime2, 16, float(x) / SIZE, float(y) / SIZE)
			var shade := 0.72 + 0.33 * (g1 * 0.7 + g2 * 0.3)
			if in_mortar:
				var m := (46.0 + rng.randf_range(-6, 6)) * shade
				_put(img, x, y, m, m * 0.92, m * 0.85)
				continue
			# Per-brick tint keyed on brick coordinates.
			var brick_id := (bx / 64) + row * 31
			var tint := float((brick_id * 2654435761) % 37) - 18.0
			# Inner bevel: light top/left lip, dark bottom/right.
			var lx := bx % 64
			var ly := y % 32
			var bevel := 1.0
			if ly <= 4 or lx <= 5:
				bevel = 1.22
			elif ly >= 29 or lx >= 61:
				bevel = 0.74
			var grain := rng.randf_range(-9, 9)
			var base := (134.0 + tint + grain) * shade * bevel
			_put(img, x, y, base, base * 0.62, base * 0.46)
	img.save_png("res://assets/textures/wall_brick.png")


## Tech floor: 64px plates with bevel, seams, corner bolts, oil stains.
func _gen_floor() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1001
	var grime := _make_noise(rng, 8)
	var stains := _make_noise(rng, 4)
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	for y in SIZE:
		for x in SIZE:
			var lx := x % 64
			var ly := y % 64
			var g := _noise_at(grime, 8, float(x) / SIZE, float(y) / SIZE)
			var st := _noise_at(stains, 4, float(x) / SIZE, float(y) / SIZE)
			var shade := 0.78 + 0.3 * g
			if st > 0.68:
				shade *= 1.0 - (st - 0.68) * 1.6  # dark oil stain blotches
			if lx < 2 or ly < 2:
				var s := 38.0 * shade
				_put(img, x, y, s, s, s * 1.05)
				continue
			var bevel := 1.0
			if lx <= 4 or ly <= 4:
				bevel = 1.18
			elif lx >= 60 or ly >= 60:
				bevel = 0.76
			# Corner bolts, inset from each plate corner.
			var bolt := (absi(lx - 8) <= 1 and absi(ly - 8) <= 1) \
					or (absi(lx - 56) <= 1 and absi(ly - 8) <= 1) \
					or (absi(lx - 8) <= 1 and absi(ly - 56) <= 1) \
					or (absi(lx - 56) <= 1 and absi(ly - 56) <= 1)
			var base := (94.0 + rng.randf_range(-6, 6)) * shade * bevel
			if bolt:
				base *= 1.45
			_put(img, x, y, base * 0.99, base * 0.97, base * 0.92)
	img.save_png("res://assets/textures/floor_tile.png")


## Brushed metal: vertical streaks, 64px plates with seams + rivets, rust.
func _gen_metal() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3003
	var rust := _make_noise(rng, 6)
	# Column brightness for the brushed look: smoothed random walk that
	# returns to its start so the texture tiles horizontally.
	var streak := PackedFloat32Array()
	streak.resize(SIZE)
	for x in SIZE:
		var w := 1.0 - absf(x - SIZE / 2.0) / (SIZE / 2.0)
		streak[x] = sin(x * 0.7) * 3.0 + sin(x * 0.23) * 5.0 * w
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	for y in SIZE:
		for x in SIZE:
			var lx := x % 64
			var ly := y % 64
			var ru := _noise_at(rust, 6, float(x) / SIZE, float(y) / SIZE)
			if lx < 2 or ly < 2:
				_put(img, x, y, 42, 44, 50)
				continue
			var bevel := 1.0
			if lx <= 4 or ly <= 4:
				bevel = 1.15
			elif lx >= 60 or ly >= 60:
				bevel = 0.8
			# Rivet dots along the plate seams.
			var rivet := (ly >= 5 and ly <= 7 or ly >= 57 and ly <= 59) \
					and (lx % 16 >= 7 and lx % 16 <= 9)
			var base := (104.0 + streak[x] + rng.randf_range(-4, 4)) * bevel
			var r := base * 0.97
			var g := base
			var b := base * 1.08
			if rivet:
				r *= 1.35; g *= 1.35; b *= 1.3
			if ru > 0.72:
				var k := (ru - 0.72) * 2.8
				r = lerpf(r, 110.0, k)
				g = lerpf(g, 62.0, k)
				b = lerpf(b, 38.0, k)
			_put(img, x, y, r, g, b)
	img.save_png("res://assets/textures/metal_plate.png")


## Ice: pale blue sheet with darker crack veins and sparkle specks.
func _gen_ice() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9009
	var depth := _make_noise(rng, 5)
	var vein := _make_noise(rng, 11)
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	for y in SIZE:
		for x in SIZE:
			var u := float(x) / SIZE
			var v := float(y) / SIZE
			var d := _noise_at(depth, 5, u, v)
			var base := 168.0 + 42.0 * d + rng.randf_range(-4, 4)
			var r := base * 0.8
			var g := base * 0.92
			var b := base * 1.04
			if absf(_noise_at(vein, 11, u, v) - 0.5) < 0.03:
				r = 82.0
				g = 118.0
				b = 168.0
			elif rng.randf() < 0.004:
				r = 240.0
				g = 248.0
				b = 255.0
			_put(img, x, y, r, g, b)
	img.save_png("res://assets/textures/ice.png")


## Portal vortex: grayscale three-armed spiral with bright core and dark rim,
## rotated at runtime by shaders/vortex.gdshader (tint applied there too).
func _gen_swirl() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7007
	var grain := _make_noise(rng, 12)
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	for y in SIZE:
		for x in SIZE:
			var cx := (float(x) + 0.5) / SIZE - 0.5
			var cy := (float(y) + 0.5) / SIZE - 0.5
			var r := sqrt(cx * cx + cy * cy) * 2.0
			var ang := atan2(cy, cx)
			# Three arms winding tighter toward the center.
			var arms := maxf(0.0, sin(ang * 3.0 + r * 9.0))
			arms = pow(arms, 2.2) * (0.3 + 0.7 * (1.0 - minf(r, 1.0)))
			var core := clampf(1.0 - r * 2.4, 0.0, 1.0)
			var rim := 1.0 - smoothstep(0.78, 1.0, r)
			var g := _noise_at(grain, 12, float(x) / SIZE, float(y) / SIZE)
			var v := clampf((arms + core) * rim * (0.82 + 0.18 * g), 0.0, 1.0) * 255.0
			_put(img, x, y, v, v, v)
	img.save_png("res://assets/textures/swirl.png")


## Impact burst spritesheet: 8 frames (4x2 grid of 64px cells) of an
## expanding spark burst on black. shaders/burst.gdshader plays it
## additively (black = transparent) with a per-effect tint in Fx.spawn.
func _gen_burst_sheet() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5005
	var cell := 64
	# Fixed spark directions shared by all frames so sparks fly straight.
	var spokes := []
	for k in 9:
		spokes.append([rng.randf_range(0.0, TAU), rng.randf_range(0.85, 1.15)])
	var img := Image.create(cell * 4, cell * 2, false, Image.FORMAT_RGB8)
	for frame in 8:
		var p := frame / 7.0
		var ox := (frame % 4) * cell
		var oy := (frame / 4) * cell
		for y in cell:
			for x in cell:
				var cx := (float(x) + 0.5) / cell * 2.0 - 1.0
				var cy := (float(y) + 0.5) / cell * 2.0 - 1.0
				var r := sqrt(cx * cx + cy * cy)
				# Flash core: bright, collapses quickly.
				var core: float = exp(-pow(r / maxf(0.42 * (1.0 - 0.85 * p), 0.05), 2.0)) \
						* (1.0 - p) * 1.4
				# Shock ring expanding outward.
				var ring_r := 0.12 + 0.8 * p
				var ring: float = exp(-pow((r - ring_r) / 0.09, 2.0)) * (1.0 - p) * 0.55
				# Sparks flying outward on the fixed spokes, shrinking as they go.
				var sparks := 0.0
				for s: Array in spokes:
					var dot_r: float = 0.15 + 0.82 * p * s[1]
					var dd: float = sqrt(pow(cx - cos(s[0]) * dot_r, 2.0)
							+ pow(cy - sin(s[0]) * dot_r, 2.0))
					sparks += exp(-pow(dd / (0.09 * (1.0 - 0.55 * p)), 2.0)) * (1.0 - p)
				var v := clampf(core + ring + sparks, 0.0, 1.0) * 255.0
				_put(img, ox + x, oy + y, v, v, v)
	img.save_png("res://assets/textures/burst_sheet.png")


## Muzzle flash: soft star on black for the viewmodel flash quads
## (additive material, black = transparent, tinted per weapon).
func _gen_muzzle_flash() -> void:
	var img := Image.create(64, 64, false, Image.FORMAT_RGB8)
	for y in 64:
		for x in 64:
			var cx := (float(x) + 0.5) / 64.0 * 2.0 - 1.0
			var cy := (float(y) + 0.5) / 64.0 * 2.0 - 1.0
			var r := sqrt(cx * cx + cy * cy)
			var falloff := pow(maxf(1.0 - r, 0.0), 1.3)
			var star: float = exp(-absf(cx * cy) * 26.0) * falloff
			var diag: float = exp(-absf(cx * cx - cy * cy) * 13.0) * falloff * 0.5
			var core: float = exp(-pow(r / 0.28, 2.0))
			var v := clampf(star + diag + core, 0.0, 1.0) * 255.0
			_put(img, x, y, v, v, v)
	img.save_png("res://assets/textures/muzzle_flash.png")


## Citadel stone: pale weathered sandstone blocks with bevel + light grime.
func _gen_stone() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 8008
	var grime := _make_noise(rng, 7)
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	for y in SIZE:
		var row := y / 32
		var offset := (row % 2) * 32
		for x in SIZE:
			var bx := (x + offset) % SIZE
			var g := _noise_at(grime, 7, float(x) / SIZE, float(y) / SIZE)
			var shade := 0.82 + 0.22 * g
			if y % 32 < 2 or bx % 64 < 2:
				var m := 96.0 * shade
				_put(img, x, y, m, m * 0.95, m * 0.88)
				continue
			var block_id := (bx / 64) + row * 13
			var tint := float((block_id * 2654435761) % 21) - 10.0
			var lx := bx % 64
			var ly := y % 32
			var bevel := 1.0
			if ly <= 3 or lx <= 4:
				bevel = 1.12
			elif ly >= 29 or lx >= 60:
				bevel = 0.82
			var base := (182.0 + tint + rng.randf_range(-6, 6)) * shade * bevel
			_put(img, x, y, base, base * 0.94, base * 0.84)
	img.save_png("res://assets/textures/stone.png")


## Cave rock: dark craggy multi-octave noise with crack veins.
func _gen_rock() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 6006
	var big := _make_noise(rng, 6)
	var mid := _make_noise(rng, 14)
	var vein := _make_noise(rng, 10)
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	for y in SIZE:
		for x in SIZE:
			var u := float(x) / SIZE
			var v := float(y) / SIZE
			var n := _noise_at(big, 6, u, v) * 0.6 + _noise_at(mid, 14, u, v) * 0.4
			var base := 52.0 + 52.0 * n + rng.randf_range(-6, 6)
			# Dark crack veins where the vein noise crosses its midline.
			if absf(_noise_at(vein, 10, u, v) - 0.5) < 0.035:
				base *= 0.45
			_put(img, x, y, base, base * 0.9, base * 0.8)
	img.save_png("res://assets/textures/rock.png")


## Lava: bright marbled orange with dark crust veins. Meant for an
## unshaded material, so it reads as glowing.
func _gen_lava() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7007
	var heat := _make_noise(rng, 5)
	var crust := _make_noise(rng, 9)
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	for y in SIZE:
		for x in SIZE:
			var u := float(x) / SIZE
			var v := float(y) / SIZE
			var h := _noise_at(heat, 5, u, v)
			var r := 200.0 + 55.0 * h
			var g := 55.0 + 130.0 * h * h
			var b := 15.0 + 30.0 * h * h * h
			if _noise_at(crust, 9, u, v) > 0.74:
				r = 70.0
				g = 28.0
				b = 14.0
			_put(img, x, y, r + rng.randf_range(-6, 6), g, b)
	img.save_png("res://assets/textures/lava.png")


## Wooden crate: vertical planks with grain and knots, two riveted metal
## bands.
func _gen_crate() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5005
	var grain := _make_noise(rng, 32)
	# Deterministic knot placement: one knot on some planks.
	var knot_y := PackedInt32Array()
	for p in 8:
		knot_y.append(rng.randi_range(35, 95) if rng.randf() < 0.5 else -100)
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	for y in SIZE:
		for x in SIZE:
			var plank := x / 16
			var lx := x % 16
			var in_band := (y >= 14 and y <= 27) or (y >= 100 and y <= 113)
			if in_band:
				var edge := (y == 14 or y == 27 or y == 100 or y == 113)
				var rivet := (lx >= 7 and lx <= 9) \
						and ((y >= 19 and y <= 21) or (y >= 105 and y <= 107))
				var m := 74.0 + rng.randf_range(-4, 4)
				if edge:
					m *= 0.6
				if rivet:
					m *= 1.5
				_put(img, x, y, m * 0.95, m, m * 1.1)
				continue
			if lx < 2:
				_put(img, x, y, 43 + rng.randi_range(-4, 4), 31, 21)
				continue
			var tint := float((plank * 2654435761) % 31) - 15.0
			var g := _noise_at(grain, 32, float(x) / SIZE, float(y) / SIZE)
			var streaks := sin(float(y) * 0.35 + float(plank) * 2.1) * 6.0
			var base := 118.0 + tint + streaks + g * 14.0 + rng.randf_range(-5, 5)
			# Knot: dark radial blob.
			var ky := knot_y[plank]
			var d := Vector2(lx - 8, y - ky).length()
			if d < 5.0:
				base *= 0.55 + 0.09 * d
			_put(img, x, y, base, base * 0.68, base * 0.42)
	img.save_png("res://assets/textures/crate.png")


## Barrel staves: narrow vertical oak strips, each shaded round (bright
## middle, dark seams), with two dark iron hoops (no rivets) and contact
## shadows where hoop meets wood. mat_barrel wraps this with uv_scale (2,1),
## so 16 staves circle the cylinder; the hoop rows land near the ends of
## each half of the two-cone barrel mesh.
func _gen_barrel_wood() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 10010
	var grain := _make_noise(rng, 32)
	var weather := _make_noise(rng, 6)
	# Deterministic knot placement: a knot on the occasional stave.
	var knot_y := PackedInt32Array()
	for s in 8:
		knot_y.append(rng.randi_range(38, 92) if rng.randf() < 0.35 else -100)
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	for y in SIZE:
		for x in SIZE:
			var stave := x / 16
			var lx := x % 16
			var in_hoop := (y >= 14 and y <= 27) or (y >= 100 and y <= 113)
			if in_hoop:
				var edge := (y == 14 or y == 27 or y == 100 or y == 113)
				var glint := (y == 16 or y == 102)
				var m := 56.0 + rng.randf_range(-3, 3)
				if edge:
					m *= 0.55
				elif glint:
					m *= 1.45
				_put(img, x, y, m * 0.92, m * 0.95, m * 1.05)
				continue
			var w := _noise_at(weather, 6, float(x) / SIZE, float(y) / SIZE)
			var shade := 0.84 + 0.26 * w
			# Contact shadow where the wood meets a hoop.
			if (y >= 12 and y <= 13) or (y >= 28 and y <= 29) \
					or (y >= 98 and y <= 99) or (y >= 114 and y <= 115):
				shade *= 0.78
			if lx < 2:
				_put(img, x, y,
						(36.0 + rng.randf_range(-3, 3)) * shade, 25.0 * shade, 16.0 * shade)
				continue
			# Rounded stave: bright down the middle, falling off to the seams.
			var curve := 0.78 + 0.34 * sin(PI * (float(lx) + 0.5) / 16.0)
			var tint := float((stave * 2654435761) % 27) - 13.0
			var g := _noise_at(grain, 32, float(x) / SIZE, float(y) / SIZE)
			var base := (102.0 + tint + g * 12.0 + rng.randf_range(-4, 4)) * curve * shade
			var ky := knot_y[stave]
			var d := Vector2(lx - 8, y - ky).length()
			if d < 4.0:
				base *= 0.5 + 0.11 * d
			_put(img, x, y, base, base * 0.62, base * 0.38)
	img.save_png("res://assets/textures/barrel_wood.png")
