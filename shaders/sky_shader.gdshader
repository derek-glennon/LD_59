shader_type sky;

uniform vec3 bottom_color : source_color = vec3(1.0);
uniform vec3 top_color : source_color = vec3(1.0);

uniform sampler2D cloud_texture;
uniform float cloud_scale = 0.1;
uniform vec3 cloud_direction = vec3(0.0, 0.0, 0.0);
uniform float cloud_step = 0.0;
uniform vec2 cloud_speed = vec2(0.0);
uniform vec3 cloud_tint : source_color = vec3(1.0);

mat3 direction_to_matrix(vec3 direction) {
	vec3 x_axis = normalize(cross(vec3(0.0, 1.0, 0.0), direction));
	vec3 y_axis = normalize(cross(direction, x_axis));
	return mat3(vec3(x_axis.x, y_axis.x, direction.x),
				vec3(x_axis.y, y_axis.y, direction.y),
				vec3(x_axis.z, y_axis.z, direction.z));
}

void sky() {
	float horizon_mask = abs(EYEDIR.y);
	float bottom_mask = smoothstep(0.5, 0.45, SKY_COORDS.y);
	
	vec3 dir = direction_to_matrix(normalize(cloud_direction)) * EYEDIR;
	vec2 cloud_uv = (-(dir.xy / dir.z) * cloud_scale) + vec2(0.5);
	cloud_uv += TIME * cloud_speed;
	
	vec4 cloud_color = texture(cloud_texture, cloud_uv);
	cloud_color.rgb = step(cloud_step, cloud_color.rgb) * cloud_tint;
	float cloud_alpha = cloud_color.r;
	
	vec3 sky_gradient = mix(bottom_color.rgb, top_color.rgb, clamp(EYEDIR.y, 0.0, 1.0));
	vec3 sky_color = mix(sky_gradient, cloud_color.rgb, cloud_alpha * bottom_mask);

	COLOR = vec3(sky_color);
}
