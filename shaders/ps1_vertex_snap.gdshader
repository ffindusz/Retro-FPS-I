shader_type spatial;
render_mode cull_back, specular_disabled;

// PS1-style material: vertex snapping + affine texture mapping.
// Apply to world geometry, enemies, and props for the retro look.

uniform vec4 albedo_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D albedo_texture : source_color, hint_default_white, filter_nearest_mipmap, repeat_enable;
uniform vec2 uv_scale = vec2(1.0, 1.0);
// Vertical resolution of the virtual snapping grid. Lower = more wobble.
// Matches the 320x240 SubViewport in main.tscn; keep them in sync if either
// changes, or the wobble grid stops lining up with the actual pixel grid.
uniform float snap_resolution = 240.0;
// 0 = normal perspective-correct UVs, 1 = full PS1 affine warping. Every
// shipped material (assets/materials/*.tres) currently overrides this to
// 0.0 — the wobble read as more legible without it — so this default of 1.0
// only takes effect for a ShaderMaterial that doesn't set the parameter.
uniform float affine_strength : hint_range(0.0, 1.0) = 1.0;
// 1 = ignore mesh UVs and project world-space planar UVs per face.
// Used on CSG level geometry so texel density is uniform (1 tile per
// 1/uv_scale meters) regardless of how CSG generates its UVs.
uniform float world_uv : hint_range(0.0, 1.0) = 0.0;

varying vec2 uv_persp;
varying vec2 uv_affine;
varying float w_affine;

void vertex() {
	vec2 base_uv = UV;
	if (world_uv > 0.5) {
		// Per-vertex planar projection along the dominant face axis. CSG
		// faces have constant normals, so this stays seam-free per face.
		vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
		vec3 n = abs(MODEL_NORMAL_MATRIX * NORMAL);
		if (n.y >= n.x && n.y >= n.z) {
			base_uv = wp.xz;
		} else if (n.x >= n.z) {
			base_uv = vec2(wp.z, -wp.y);
		} else {
			base_uv = vec2(wp.x, -wp.y);
		}
	}
	base_uv *= uv_scale;

	vec4 clip = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	// PS1 vertex snapping: the console's GTE produced fixed-point screen
	// coordinates, so vertices popped between discrete pixel positions.
	// Emulate by rounding normalized device coords (clip.xy / w) to a
	// low-res grid, then converting back to clip space.
	vec2 grid = vec2(snap_resolution * (VIEWPORT_SIZE.x / VIEWPORT_SIZE.y), snap_resolution);
	// Only snap vertices in front of the camera: dividing by a negative w
	// (vertex behind the near plane) inverts the NDC coords and the rounding
	// then corrupts any large polygon that crosses the camera plane, punching
	// holes in nearby walls/ceilings. Clipping happens after this, so
	// unsnapped behind-camera vertices are harmless.
	if (clip.w > 0.0) {
		clip.xy = round(clip.xy / clip.w * grid) / grid * clip.w;
	}
	POSITION = clip;

	// Affine texture mapping: the PS1 interpolated UVs linearly in screen
	// space (no perspective correction), causing the classic texture warp.
	// Trick: pre-multiply UV by clip w here; the GPU then interpolates
	// (UV*w) and (w) perspective-correctly, and dividing them back in the
	// fragment shader exactly reproduces screen-space linear interpolation.
	uv_persp = base_uv;
	uv_affine = base_uv * clip.w;
	w_affine = clip.w;
}

void fragment() {
	vec2 uv = mix(uv_persp, uv_affine / w_affine, affine_strength);
	vec4 tex = texture(albedo_texture, uv);
	ALBEDO = tex.rgb * albedo_color.rgb;
}
