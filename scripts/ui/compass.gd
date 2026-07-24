extends Control
## Horizontal compass strip for the top of the HUD. A fixed center pointer marks
## the way the player faces; cardinal letters scroll past it as they turn.
## Fed the player's body yaw (radians) each frame via set_heading().

## Degrees of arc visible to each side of the center pointer.
const HALF_FOV := 70.0
## Minor tick spacing, in degrees.
const TICK_EVERY := 15.0
## Compass bearing (deg, N=0) -> label. Cardinals are drawn larger.
const MARKS := {
	0.0: "N", 45.0: "NE", 90.0: "E", 135.0: "SE",
	180.0: "S", 225.0: "SW", 270.0: "W", 315.0: "NW",
}

const CARDINAL_COL := Color(0.96, 0.94, 0.86, 0.9)
const INTER_COL := Color(0.68, 0.71, 0.8, 0.65)
const TICK_COL := Color(0.6, 0.63, 0.72, 0.5)
const POINTER_COL := Color(1, 0.82, 0.32, 1)
const CARDINAL_SIZE := 20
const INTER_SIZE := 14

var _bearing := 0.0  ## Player facing as a compass bearing (deg, N=0).

@onready var _font: Font = get_theme_default_font()


## World forward is -Z (North) at yaw 0. Godot yaw turns counter-clockwise while
## compass bearings run clockwise, so the bearing is the negated yaw.
func set_heading(yaw_radians: float) -> void:
	var b := fposmod(360.0 - rad_to_deg(yaw_radians), 360.0)
	if not is_equal_approx(b, _bearing):
		_bearing = b
		queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	var cx := w * 0.5
	var half_w := w * 0.5

	# Subtle backing so letters stay legible over any scenery.
	draw_rect(Rect2(0.0, h - 14.0, w, 14.0), Color(0, 0, 0, 0.28))

	# Minor ticks across the visible arc.
	var a := floorf((_bearing - HALF_FOV) / TICK_EVERY) * TICK_EVERY
	while a <= _bearing + HALF_FOV:
		var d := wrapf(a - _bearing, -180.0, 180.0)
		if absf(d) <= HALF_FOV:
			var tx := cx + (d / HALF_FOV) * half_w
			draw_line(Vector2(tx, h - 8.0), Vector2(tx, h - 2.0), TICK_COL, 1.0)
		a += TICK_EVERY

	# Cardinal + intercardinal labels with a major tick under each.
	for bearing: float in MARKS:
		var d := wrapf(bearing - _bearing, -180.0, 180.0)
		if absf(d) > HALF_FOV:
			continue
		var x := cx + (d / HALF_FOV) * half_w
		var label: String = MARKS[bearing]
		var is_cardinal := int(bearing) % 90 == 0
		var col := CARDINAL_COL if is_cardinal else INTER_COL
		var fsize := CARDINAL_SIZE if is_cardinal else INTER_SIZE
		var ts := _font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize)
		draw_string(_font, Vector2(x - ts.x * 0.5, h - 18.0), label,
				HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, col)
		draw_line(Vector2(x, h - 9.0), Vector2(x, h - 1.0), col, 1.0)

	# Fixed center pointer: a downward wedge over the strip.
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 6.0, 0.0), Vector2(cx + 6.0, 0.0), Vector2(cx, 9.0)]),
		POINTER_COL)
