shader_type spatial;

uniform float head_background = 0.5;
uniform sampler2D face_texture : source_color;
uniform float roughness = 0.4;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	float face = texture(face_texture, UV).r;
	vec3 face_color = vec3(face);
	vec3 final_color = head_background * (1.0 - face) + face_color;
	ALBEDO = vec3(final_color);
	EMISSION = face_color;
	SPECULAR = 0.0;
	ROUGHNESS = roughness;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
