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
