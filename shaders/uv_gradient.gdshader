shader_type spatial;

uniform sampler2D albedo_texture;
uniform vec2 uv_scale = vec2(1.0);
uniform vec2 uv_speed = vec2(0.0);
uniform vec3 color_bottom : source_color = vec3(0.0);
uniform vec3 color_top : source_color = vec3(1.0);
uniform float smoothstep_min = 0.0;
uniform float smoothstep_max = 1.0;
uniform float emissive_intensity = 1.0;
uniform float roughness = 0.0;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	float texture_sample = texture(albedo_texture, UV * uv_scale + TIME * uv_speed).r;
	float gradient = smoothstep(smoothstep_min, smoothstep_max, UV.y);
	vec3 gradient_color = mix(color_bottom, color_top, gradient);
	ALBEDO = gradient_color + texture_sample;
	EMISSION = gradient_color * emissive_intensity;
	ROUGHNESS = roughness;
	SPECULAR = 0.0;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
