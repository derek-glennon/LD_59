shader_type spatial;

uniform vec3 water_color_bottom : source_color = vec3(1.0);
uniform vec3 water_color_top : source_color = vec3(1.0);

uniform sampler2D pattern_texture;
uniform vec2 pattern_uv_scale = vec2(1.0);
uniform vec2 pattern_uv_speed = vec2(0.0);
uniform float pattern_step = 0.5;

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	
	vec3 water_color = water_color_bottom;
	
	vec2 pattern_uv = world_position.xz * pattern_uv_scale + TIME * pattern_uv_speed;
	float pattern = texture(pattern_texture, pattern_uv).r;
	pattern = step(pattern, pattern_step);
	
	ALBEDO = vec3(water_color + pattern);
	ROUGHNESS = 0.1;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
