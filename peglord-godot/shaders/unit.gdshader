shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_disabled, depth_draw_opaque;
// HD-2D character billboard: stays upright, lit by the scene, with hit flash, tint, outline glow and dissolve.
uniform sampler2D frame : filter_nearest, source_color;
uniform float flip = 0.0;
uniform float flash = 0.0;
uniform vec4 tint : source_color = vec4(1.0);
uniform float glow = 0.0;
uniform vec4 glow_color : source_color = vec4(1.0, 0.85, 0.3, 1.0);
uniform float dissolve = 0.0;
uniform float ambient = 0.42;
uniform vec2 texel = vec2(0.0125, 0.0125);

void vertex() {
	vec3 sc = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	vec3 right = normalize(INV_VIEW_MATRIX[0].xyz * vec3(1.0, 0.0, 1.0));
	vec3 up = vec3(0.0, 1.0, 0.0);
	vec3 fwd = normalize(cross(right, up));
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(right * sc.x, 0.0), vec4(up * sc.y, 0.0), vec4(fwd * sc.z, 0.0), MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }

void fragment() {
	vec2 uv = UV;
	if (flip > 0.5) uv.x = 1.0 - uv.x;
	vec4 c = texture(frame, uv);
	float a = c.a;
	vec3 col = c.rgb * tint.rgb;
	if (a < 0.5 && glow > 0.0) {
		float n = 0.0;
		n += texture(frame, uv + vec2(texel.x, 0.0)).a;
		n += texture(frame, uv - vec2(texel.x, 0.0)).a;
		n += texture(frame, uv + vec2(0.0, texel.y)).a;
		n += texture(frame, uv - vec2(0.0, texel.y)).a;
		if (n > 0.5) { a = 1.0; col = glow_color.rgb; }
	}
	if (a < 0.5) discard;
	vec2 cell = floor(uv / texel);
	if (dissolve > 0.0 && hash(cell) < dissolve) discard;
	ALBEDO = mix(col, vec3(1.0), flash);
	EMISSION = mix(col * ambient, vec3(1.0), flash) + (a > 0.5 && c.a < 0.5 ? glow_color.rgb * glow : vec3(0.0));
	NORMAL = vec3(0.0, 0.0, 1.0);
}
