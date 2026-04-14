shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_alpha_prepass, fog_disabled;

uniform vec4 glow_color : source_color = vec4(0.0, 0.8, 1.0, 1.0);
uniform float alpha = 0.3;
uniform float glow_strength = 2.5;
uniform float scanline_density = 120.0;
uniform float grid_density = 18.0;
uniform float pulse_speed = 1.0;

void fragment() {
	vec2 uv = UV;
	float scan = 0.65 + 0.35 * sin((uv.y + TIME * pulse_speed) * scanline_density);
	float line_u = 1.0 - smoothstep(0.47, 0.5, abs(fract(uv.x * grid_density) - 0.5));
	float line_v = 1.0 - smoothstep(0.47, 0.5, abs(fract(uv.y * grid_density) - 0.5));
	float grid = max(line_u, line_v);
	float fresnel = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 2.4);

	ALBEDO = glow_color.rgb * 0.12;
	EMISSION = glow_color.rgb * (0.35 + fresnel * 1.5 + grid * 0.35) * glow_strength * scan;
	ALPHA = alpha * (0.5 + fresnel * 0.5);
}
