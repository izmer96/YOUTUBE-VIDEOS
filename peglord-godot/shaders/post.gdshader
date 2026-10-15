shader_type canvas_item;
// HD-2D finish: tilt-shift blur on the top and bottom of the frame, soft bloom, warm grade and vignette.
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float focus_center = 0.52;
uniform float focus_width = 0.20;
uniform float blur_amount = 3.2;
uniform float bloom = 0.35;
uniform float bloom_threshold = 0.72;
uniform float vignette = 0.42;
uniform float saturation = 1.08;
uniform vec3 lift = vec3(0.012, 0.006, 0.0);

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 px = SCREEN_PIXEL_SIZE;
	float d = abs(uv.y - focus_center) - focus_width;
	float b = clamp(d / 0.25, 0.0, 1.0) * blur_amount;
	vec3 col = texture(screen_tex, uv).rgb;
	vec3 acc = col;
	vec3 glow = vec3(0.0);
	float w = 1.0;
	// 12-tap golden-angle disc
	for (int i = 0; i < 12; i++) {
		float fi = float(i);
		float r = sqrt((fi + 0.5) / 12.0);
		float ang = fi * 2.39996;
		vec2 o = vec2(cos(ang), sin(ang)) * r;
		vec3 s = texture(screen_tex, uv + o * px * b * 2.2).rgb;
		acc += s; w += 1.0;
		vec3 g = texture(screen_tex, uv + o * px * 14.0).rgb;
		glow += max(g - vec3(bloom_threshold), vec3(0.0));
	}
	col = (b > 0.05) ? acc / w : col;
	col += glow / 12.0 * bloom * 2.0;
	float l = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(l), col, saturation);
	col += lift;
	vec2 vc = uv - 0.5;
	col *= 1.0 - vignette * smoothstep(0.25, 0.85, length(vc * vec2(1.0, 0.85)));
	COLOR = vec4(col, 1.0);
}
