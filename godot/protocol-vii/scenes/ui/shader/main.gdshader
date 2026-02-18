shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// --- SETTINGS ---
uniform float scanline_count : hint_range(0, 1080) = 50.0;
uniform float vignette_strength : hint_range(0.0, 5.0) = 1.0; 
uniform float scanline_opacity : hint_range(0.0, 1.0) = 0.15; 

void fragment() {
	// Use the screen coordinates directly (FLAT)
	vec2 uv = SCREEN_UV;

	// 1. Get screen color
	vec4 screen_color = texture(SCREEN_TEXTURE, uv);
	
	// 2. Generate Scanlines
	float s = sin(uv.y * scanline_count * 3.14159 * 2.0);
	s = (s * 0.5 + 0.5); // Range 0.0 to 1.0

	// 3. Apply the "Hint" Logic (Mix White with Scanline based on Opacity)
	float line_effect = mix(1.0, s, scanline_opacity);

	// 4. Vignette (Dark Corners)
	vec2 v_uv = uv * (1.0 - uv.yx);
	float vig = v_uv.x * v_uv.y * 15.0;
	vig = pow(vig, vignette_strength);
	
	// 5. Combine
	vec4 final_color = screen_color;
	final_color.rgb *= line_effect; // Apply subtle lines
	final_color.rgb *= vig;         // Apply corners
	
	COLOR = final_color;
}