shader_type canvas_item;

uniform vec4 top_color : source_color = vec4(0.06, 0.1, 0.18, 1.0);
uniform vec4 mid_color : source_color = vec4(0.04, 0.08, 0.14, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.02, 0.04, 0.08, 1.0);
uniform float highlight_strength = 0.2;
uniform float noise_strength = 0.02;
uniform float vignette_strength = 0.18;

void fragment() {
	float t = clamp(UV.y, 0.0, 1.0);
	float mix_top = smoothstep(0.0, 0.5, t);
	float mix_bottom = smoothstep(0.45, 1.0, t);
	vec4 base = mix(top_color, mid_color, mix_top);
	base = mix(base, bottom_color, mix_bottom);

	float highlight = exp(-t * 8.0);
	base.rgb += highlight * highlight_strength;

	float n = fract(sin(dot(UV * vec2(512.0, 256.0), vec2(12.9898, 78.233))) * 43758.5453);
	base.rgb += (n - 0.5) * noise_strength;

	float d = distance(UV, vec2(0.5));
	float vignette = smoothstep(0.45, 0.8, d);
	base.rgb *= 1.0 - (vignette * vignette_strength);

	base *= COLOR;
	COLOR = base;
}
