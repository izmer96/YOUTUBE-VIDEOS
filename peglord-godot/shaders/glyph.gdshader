shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;
// Additive glowing quad for spell effects (rings, slashes, sparks).
uniform vec4 color : source_color = vec4(1.0);
uniform float energy = 2.0;
uniform int kind = 0; // 0 ring, 1 slash arc, 2 soft disc, 3 rune circle
uniform float progress = 0.0;
void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	float a = 0.0;
	if (kind == 0) {
		a = smoothstep(0.12, 0.0, abs(r - 0.85));
	} else if (kind == 1) {
		float ang = atan(p.y, p.x);
		float band = smoothstep(0.16, 0.0, abs(r - 0.75)) * smoothstep(-1.6, 0.4, ang) * smoothstep(1.9, 0.6, ang);
		a = band;
	} else if (kind == 2) {
		a = pow(max(0.0, 1.0 - r), 2.0);
	} else {
		float ring = smoothstep(0.06, 0.0, abs(r - 0.9)) + smoothstep(0.04, 0.0, abs(r - 0.7));
		float ang = atan(p.y, p.x) + TIME * 1.5;
		float ticks = step(0.8, fract(ang * 6.0 / 6.2832 * 2.0)) * step(0.72, r) * step(r, 0.88);
		float star = smoothstep(0.04, 0.0, abs(abs(p.x * 0.866 + p.y * 0.5) - 0.62)) * step(r, 0.9);
		star += smoothstep(0.04, 0.0, abs(abs(p.x * 0.866 - p.y * 0.5) - 0.62)) * step(r, 0.9);
		star += smoothstep(0.04, 0.0, abs(abs(p.y) - 0.62)) * step(r, 0.9);
		a = clamp(ring + ticks + star * 0.6, 0.0, 1.0);
	}
	a *= (1.0 - progress);
	ALBEDO = color.rgb * energy * a;
	ALPHA = a;
}
