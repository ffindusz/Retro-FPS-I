shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never,
		shadows_disabled, specular_disabled;

// Billboarded looping flame for projectiles (boss fireballs, plasma bolts).
// Cycles the generated flame spritesheet (assets/textures/flame_sheet.png,
// 4x2 grid, black = transparent) at `fps`; `tint` colors the grayscale
// flame per projectile. Same billboard math as burst.gdshader.
uniform sampler2D sheet : source_color, filter_linear_mipmap, repeat_disable;
uniform vec3 tint : source_color = vec3(1.0, 0.55, 0.2);
uniform float fps = 10.0;

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
	float f = mod(floor(TIME * fps), 8.0);
	vec2 uv = (UV + vec2(mod(f, 4.0), floor(f / 4.0))) / vec2(4.0, 2.0);
	ALBEDO = texture(sheet, uv).rgb * tint;
}
