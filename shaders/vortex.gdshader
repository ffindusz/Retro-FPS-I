shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never,
		shadows_disabled, specular_disabled;

// Swirling portal built from two counter-rotating samples of the generated
// spiral texture (assets/textures/swirl.png). Additive, so black is
// invisible; tints color the two layers separately for depth.
uniform sampler2D swirl_tex : source_color, filter_linear_mipmap, repeat_disable;
uniform vec3 tint_a : source_color = vec3(0.2, 1.0, 0.9);
uniform vec3 tint_b : source_color = vec3(0.45, 0.3, 1.0);
uniform float speed = 1.2;
uniform float intensity = 1.0;
uniform bool billboard = false;

void vertex() {
	if (billboard) {
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0],
				INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
		MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(
				vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
				vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
				vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
				vec4(0.0, 0.0, 0.0, 1.0));
		MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	}
}

vec2 spin(vec2 c, float t) {
	float s = sin(t);
	float k = cos(t);
	return mat2(vec2(k, -s), vec2(s, k)) * c;
}

void fragment() {
	vec2 c = UV - 0.5;
	float r = length(c) * 2.0;
	float t = TIME * speed;
	float v1 = texture(swirl_tex, spin(c, t) + 0.5).r;
	float v2 = texture(swirl_tex, spin(c * 1.35, -t * 0.63) + 0.5).r;
	float mask = 1.0 - smoothstep(0.85, 1.0, r);
	ALBEDO = (tint_a * v1 + tint_b * v2 * 0.7) * mask * intensity;
}
