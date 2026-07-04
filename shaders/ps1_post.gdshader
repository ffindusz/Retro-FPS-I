shader_type canvas_item;

// Post-process for the SubViewportContainer: quantizes the low-res frame
// to a limited palette with ordered (Bayer 4x4) dithering, mimicking the
// PS1's 15-bit output + dither hardware. Runs on the 320x240 source pixels
// (nearest-upscaled afterwards), so dither dots are chunky like the console.

uniform float color_levels : hint_range(4.0, 64.0) = 32.0;
uniform float dither_strength : hint_range(0.0, 2.0) = 1.0;

const float BAYER[16] = {
	0.0, 8.0, 2.0, 10.0,
	12.0, 4.0, 14.0, 6.0,
	3.0, 11.0, 1.0, 9.0,
	15.0, 7.0, 13.0, 5.0
};

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	// Integer coords of the SOURCE (320x240) pixel so every upscaled block
	// shares one dither value.
	vec2 px = floor(UV / TEXTURE_PIXEL_SIZE);
	int idx = int(mod(px.y, 4.0)) * 4 + int(mod(px.x, 4.0));
	float d = (BAYER[idx] + 0.5) / 16.0 - 0.5;
	c.rgb = floor(c.rgb * color_levels + 0.5 + d * dither_strength) / color_levels;
	COLOR = c;
}
