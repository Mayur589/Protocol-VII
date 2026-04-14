shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D world_map : source_color;

uniform vec3 ocean_color : source_color = vec3(0.04, 0.11, 0.18);
uniform vec3 land_color : source_color = vec3(0.19, 0.40, 0.52);
uniform vec3 emission_color : source_color = vec3(0.16, 0.72, 1.0);

uniform float continent_threshold : hint_range(0.0, 1.0, 0.001) = 0.55;
uniform float continent_softness : hint_range(0.001, 0.25, 0.001) = 0.08;
uniform float roughness_ocean : hint_range(0.0, 1.0, 0.01) = 0.52;
uniform float roughness_land : hint_range(0.0, 1.0, 0.01) = 0.62;
uniform float metallic_level : hint_range(0.0, 1.0, 0.01) = 0.18;

uniform float emission_strength : hint_range(0.0, 3.0, 0.01) = 0.45;
uniform float fresnel_glow_strength : hint_range(0.0, 3.0, 0.01) = 0.75;
uniform float scanline_density : hint_range(10.0, 320.0, 1.0) = 165.0;
uniform float scanline_speed : hint_range(0.0, 3.0, 0.01) = 0.45;
uniform float grid_strength : hint_range(0.0, 2.0, 0.01) = 0.35;

float continent_mask(vec3 map_rgb) {
	float luma = dot(map_rgb, vec3(0.299, 0.587, 0.114));
	float edge0 = continent_threshold - continent_softness;
	float edge1 = continent_threshold + continent_softness;
	return smoothstep(edge0, edge1, luma);
}

void fragment() {
	vec2 map_uv = vec2(fract(UV.x + 0.5), UV.y);
	vec3 map_tex = texture(world_map, map_uv).rgb;
	float land = continent_mask(map_tex);

	float lat_line = 1.0 - smoothstep(0.95, 0.995, abs(sin(UV.y * PI * 80.0)));
	float lon_line = 1.0 - smoothstep(0.95, 0.995, abs(sin(UV.x * PI * 160.0)));
	float grid = clamp(lat_line + lon_line, 0.0, 1.0);

	vec3 base = mix(ocean_color, land_color, land);
	ALBEDO = base;
	METALLIC = metallic_level;
	ROUGHNESS = mix(roughness_ocean, roughness_land, land);
	SPECULAR = 0.5;

	float ndotv = max(dot(normalize(NORMAL), normalize(VIEW)), 0.0);
	float fresnel = pow(1.0 - ndotv, 3.0);
	float scan = 0.72 + 0.28 * sin((UV.y + TIME * scanline_speed) * scanline_density);
	float continent_glow = land * (0.12 + grid * grid_strength);
	float edge_glow = fresnel * fresnel_glow_strength;
	float pulse = 0.9 + 0.1 * sin(TIME * 1.5);

	EMISSION = emission_color * emission_strength * (continent_glow + edge_glow) * scan * pulse;
}
