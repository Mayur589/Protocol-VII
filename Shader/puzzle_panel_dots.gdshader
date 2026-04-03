shader_type canvas_item;

uniform vec4 base_color : source_color = vec4(0.01, 0.03, 0.02, 1.0);
uniform vec4 dot_color : source_color = vec4(0.16, 0.32, 0.22, 0.55);
uniform vec4 dot_color_2 : source_color = vec4(0.08, 0.18, 0.12, 0.4);
uniform float dot_scale = 140.0;
uniform float dot_scale_2 = 90.0;
uniform float dot_radius = 0.17;
uniform float dot_radius_2 = 0.12;
uniform float dot_softness = 0.06;
uniform float density = 0.55;
uniform float density_2 = 0.35;
uniform float jitter = 0.6;
uniform float cluster_scale = 2.2;
uniform float cluster_strength = 0.75;

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);

	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));

	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 3; i++) {
		v += a * value_noise(p);
		p *= 2.0;
		a *= 0.5;
	}
	return v;
}

float dot_mask(vec2 uv, float scale, float radius, float density_level, float jitter_amount, float seed, float cluster_field) {
	vec2 grid = uv * scale;
	vec2 cell = floor(grid);
	vec2 f = fract(grid);

	float local_density = clamp(density_level + (cluster_field - 0.5) * cluster_strength, 0.02, 0.98);
	float r = hash21(cell + seed);
	if (r > local_density) {
		return 0.0;
	}

	vec2 j = vec2(hash21(cell + seed + 23.17), hash21(cell + seed + 91.71)) - 0.5;
	f -= j * jitter_amount;

	float d = length(f - 0.5);
	return smoothstep(radius + dot_softness, radius - dot_softness, d);
}

void fragment() {
	vec2 uv = UV;
	float cluster_a = fbm(uv * cluster_scale * 3.0);
	float cluster_b = fbm(uv * cluster_scale * 6.0 + 9.7);

	float mask_a = dot_mask(uv, dot_scale, dot_radius, density, jitter, 0.0, cluster_a);
	float mask_b = dot_mask(uv, dot_scale_2, dot_radius_2, density_2, jitter * 0.7, 7.3, cluster_b);

	vec4 base = base_color;
	base.rgb = mix(base.rgb, dot_color.rgb, mask_a * dot_color.a);
	base.rgb = mix(base.rgb, dot_color_2.rgb, mask_b * dot_color_2.a);

	base *= COLOR;
	COLOR = base;
}
