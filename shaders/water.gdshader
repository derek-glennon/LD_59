shader_type spatial;

uniform vec3 water_color_bottom : source_color = vec3(1.0);
uniform vec3 water_color_top : source_color = vec3(1.0);

varying vec3 world_position;

uniform sampler2D _DEPTH_TEXTURE : hint_depth_texture, repeat_disable, filter_nearest;
float get_depth(vec2 screen_uv) {
	float depth = textureLod(_DEPTH_TEXTURE, screen_uv, 0.0).r;
	return depth;
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float depth = get_depth(SCREEN_UV);
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_depth = -view.z;
	
	float object_depth = FRAGCOORD.z;
	vec3 object_ndc = vec3(SCREEN_UV * 2.0 - 1.0, object_depth);
	vec4 object_view = INV_PROJECTION_MATRIX * vec4(object_ndc, 1.0);
	object_view.xyz /= object_view.w;
	float linear_object_depth = -object_view.z;
	
	float depth_mask = linear_depth - linear_object_depth;
	float edge = step(depth_mask, 0.1);
	
	float waves = sin(depth_mask * 70.0 + TIME * 2.0);
	waves = step(waves, 0.1) * edge;
	
	vec4 world = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
    vec3 world_pos = world.xyz / world.w;
	
	float thickness = 1.0 - world_pos.y;
	thickness = max(0.0, thickness);
	float grayscale = clamp(thickness / 2.0, 0.0, 1.0);
	
	vec3 water_color = mix(water_color_bottom, water_color_top, grayscale);
	
	ALBEDO = vec3(water_color + waves);
	ALPHA = 0.8;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
