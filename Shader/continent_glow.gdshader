shader_type canvas_item;

uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 glow_color : source_color = vec4(0.25, 1.0, 0.55, 1.0);
uniform float glow_strength = 0.0;
uniform float glow_radius = 2.0;
uniform float glow_softness = 0.5;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float alpha = tex.a;

	vec2 px = TEXTURE_PIXEL_SIZE * glow_radius;
	float blur = 0.0;
	blur += texture(TEXTURE, UV + vec2(px.x, 0.0)).a;
	blur += texture(TEXTURE, UV - vec2(px.x, 0.0)).a;
	blur += texture(TEXTURE, UV + vec2(0.0, px.y)).a;
	blur += texture(TEXTURE, UV - vec2(0.0, px.y)).a;
	blur += texture(TEXTURE, UV + vec2(px.x, px.y)).a;
	blur += texture(TEXTURE, UV + vec2(-px.x, px.y)).a;
	blur += texture(TEXTURE, UV + vec2(px.x, -px.y)).a;
	blur += texture(TEXTURE, UV + vec2(-px.x, -px.y)).a;
	blur /= 8.0;

	float edge = abs(blur - alpha);
	float glow = smoothstep(0.0, glow_softness, edge) * glow_strength;
	vec3 base = tex.rgb * tint_color.rgb;
	vec3 glow_rgb = glow_color.rgb * glow;
	float out_alpha = max(alpha * tint_color.a, glow);

	COLOR = vec4(base + glow_rgb, clamp(out_alpha, 0.0, 1.0));
}
