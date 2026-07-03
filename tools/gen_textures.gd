extends SceneTree
## One-off generator for the placeholder 64x64 tiling textures.
## Run from the project root:
##   Godot_v4.7-stable_win64_console.exe --headless -s tools/gen_textures.gd
## Deterministic (fixed seeds) so regeneration produces identical files.

const SIZE := 64


func _init() -> void:
	_gen_floor()
	_gen_wall()
	_gen_metal()
	print("Textures written to res://assets/textures/")
	quit()


func _gen_floor() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1001
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	for y in SIZE:
		for x in SIZE:
			var v := 105 + rng.randi_range(-8, 8)
			var c := Color8(v, v, v + 5)
			# Grout lines every 32px make a 2x2 tile pattern.
			if x % 32 < 2 or y % 32 < 2:
				c = Color8(68, 68, 74)
			img.set_pixel(x, y, c)
	img.save_png("res://assets/textures/floor_tile.png")


func _gen_wall() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2002
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	for y in SIZE:
		var row := y / 16
		var offset := (row % 2) * 16  # stagger alternate brick rows
		for x in SIZE:
			var bx := (x + offset) % SIZE
			# Per-brick tint so bricks are distinguishable.
			var brick_id := (bx / 32) + row * 7
			var tint := (brick_id * 2654435761) % 24
			var v := 120 + tint + rng.randi_range(-7, 7)
			var c := Color8(v + 20, v - 25, v - 45)
			if y % 16 < 2 or bx % 32 < 2:
				c = Color8(58, 52, 48)  # mortar
			img.set_pixel(x, y, c)
	img.save_png("res://assets/textures/wall_brick.png")


func _gen_metal() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3003
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	for y in SIZE:
		for x in SIZE:
			var v := 92 + rng.randi_range(-5, 5)
			var c := Color8(v, v + 4, v + 9)
			# Plate seams every 32px.
			if x % 32 < 1 or y % 32 < 1:
				c = Color8(55, 58, 64)
			# Rivets near each plate corner.
			var rx := x % 32
			var ry := y % 32
			if (absi(rx - 4) <= 1 and absi(ry - 4) <= 1) \
					or (absi(rx - 28) <= 1 and absi(ry - 4) <= 1) \
					or (absi(rx - 4) <= 1 and absi(ry - 28) <= 1) \
					or (absi(rx - 28) <= 1 and absi(ry - 28) <= 1):
				c = Color8(140, 145, 152)
			img.set_pixel(x, y, c)
	img.save_png("res://assets/textures/metal_plate.png")
