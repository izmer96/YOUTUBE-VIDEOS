shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix;
// Four-frame pixel fire strip, animated and glowing.
uniform sampler2D tex : filter_nearest, source_color;
uniform float offset = 0.0;
uniform float fps = 9.0;
void fragment() {
	float f = floor(mod(TIME * fps + offset * 1.7, 4.0));
	vec2 uv = vec2((UV.x + f) / 4.0, UV.y);
	vec4 c = texture(tex, uv);
	if (c.a < 0.5) discard;
	ALBEDO = c.rgb * 2.2;
	ALPHA = 1.0;
}
