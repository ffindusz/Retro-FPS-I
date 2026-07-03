shader_type spatial;
render_mode cull_back, specular_disabled;

// PS1-style material: vertex snapping + affine texture mapping.
// Apply to world geometry, enemies, and props for the retro look.

uniform vec4 albedo_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D albedo_texture : source_color, hint_default_white, filter_nearest, repeat_enable;
uniform vec2 uv_scale = vec2(1.0, 1.0);
// Vertical resolution of the virtual snapping grid. Lower = more wobble.
uniform float snap_resolution = 240.0;
// 0 = normal perspective-correct UVs, 1 = full PS1 affine warping.
uniform float affine_strength : hint_range(0.0, 1.0) = 1.0;

varying vec2 uv_affine;
varying float w_affine;

void vertex() {
	vec4 clip = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	// PS1 vertex snapping: the console's GTE produced fixed-point screen
	// coordinates, so vertices popped between discrete pixel positions.
	// Emulate by rounding normalized device coords (clip.xy / w) to a
	// low-res grid, then converting back to clip space.
	vec2 grid = vec2(snap_resolution * (VIEWPORT_SIZE.x / VIEWPORT_SIZE.y), snap_resolution);
	clip.xy = round(clip.xy / clip.w * grid) / grid * clip.w;
	POSITION = clip;

	// Affine texture mapping: the PS1 interpolated UVs linearly in screen
	// space (no perspective correction), causing the classic texture warp.
	// Trick: pre-multiply UV by clip w here; the GPU then interpolates
	// (UV*w) and (w) perspective-correctly, and dividing them back in the
	// fragment shader exactly reproduces screen-space linear interpolation.
	uv_affine = UV * uv_scale * clip.w;
	w_affine = clip.w;
}

void fragment() {
	vec2 uv = mix(UV * uv_scale, uv_affine / w_affine, affine_strength);
	vec4 tex = texture(albedo_texture, uv);
	ALBEDO = tex.rgb * albedo_color.rgb;
}
