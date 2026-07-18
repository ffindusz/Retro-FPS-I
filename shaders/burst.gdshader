shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never,
		shadows_disabled, specular_disabled;

// Billboarded frame player for the generated impact burst spritesheet
// (assets/textures/burst_sheet.png, 4x2 grid). Additive, so the sheet's
// black background is transparent; `tint` colors the grayscale burst.
// Fx.spawn tweens `frame` 0 -> 8 over the effect's lifetime.
uniform sampler2D sheet : source_color, filter_linear_mipmap, repeat_disable;
uniform vec3 tint : source_color = vec3(1.0);
uniform float frame = 0.0;

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0],
			INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(
			vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
			vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
			vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
			vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	float f = clamp(floor(frame), 0.0, 7.0);
	vec2 uv = (UV + vec2(mod(f, 4.0), floor(f / 4.0))) / vec2(4.0, 2.0);
	ALBEDO = texture(sheet, uv).rgb * tint;
}
