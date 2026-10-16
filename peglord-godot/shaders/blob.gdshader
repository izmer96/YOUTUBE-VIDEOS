shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;
// Soft contact shadow under a sprite.
uniform float strength = 0.55;
void fragment() {
	float d = length((UV - 0.5) * 2.0);
	ALBEDO = vec3(0.02, 0.01, 0.0);
	ALPHA = strength * (1.0 - smoothstep(0.35, 1.0, d));
}
