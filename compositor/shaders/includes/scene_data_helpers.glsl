// Set 0: Scene
layout(set = 0, binding = 0, std140) uniform SceneDataBlock {
	SceneData data;
	SceneData prev_data;
} scene;

// Color image uniform (binding = 1) should be defined separately with restrict
// writeonly/readonly params.
layout(set = 0, binding = 2) uniform sampler2D depth_sampler;
layout(set = 0, binding = 3) uniform sampler2D normal_roughness_sampler;

// Converts coord obtained from gl_GlobalInvocationID
// to normalize [0.0-1.0] for use in texture() sampling functions.
highp vec2 coord_to_uv(ivec2 p_coord) {
	return (vec2(p_coord) + 0.5)/scene.data.viewport_size;
}

// Converts from normalized [0.0 - 1.0] to gl_GlobalInvocationID space
ivec2 uv_to_coord(highp vec2 uv) {
	return ivec2((uv * scene.data.viewport_size) - 0.5);
}

// Uncompress the normal roughness texture values.
// Godot automatically applies this conversion for Spatial shaders.
// see: https://github.com/godotengine/godot-docs/issues/9591
highp vec4 unpack_normal_roughness(vec4 p_normal_roughness) {
	float roughness = p_normal_roughness.w;
	if (roughness > 0.5) {
		roughness = 1.0 - roughness;
	}
	roughness /= (127.0 / 255.0);
	return vec4(normalize(p_normal_roughness.xyz * 2.0 - 1.0) * 0.5 + 0.5, roughness);
}


highp vec4 get_normal_roughness_color(ivec2 p_coord) {
	return unpack_normal_roughness(texelFetch(normal_roughness_sampler, p_coord, 0));
}


highp float get_raw_depth(ivec2 p_coord) {
	return texelFetch(depth_sampler, p_coord, 0).r;
}


highp float raw_to_linear_depth(ivec2 p_coord, highp float p_raw_depth) {
	highp vec2 uv = coord_to_uv(p_coord);
	highp vec3 ndc = vec3((uv * 2.0) - 1.0, p_raw_depth);
	highp vec4 view = scene.data.inv_projection_matrix * vec4(ndc, 1.0);
	return -(view.xyz / view.w).z;
}


highp float get_linear_depth(ivec2 p_coord) {
    return raw_to_linear_depth(p_coord, get_raw_depth(p_coord));
}

highp float get_linear_depth_offset(ivec2 p_coord, ivec2 displ) {
	highp vec2 uv = coord_to_uv(p_coord + displ);
	highp vec3 ndc = vec3((uv * 2.0) - 1.0, get_raw_depth(p_coord + displ));
	highp vec4 view = scene.data.inv_projection_matrix * vec4(ndc, 1.0);
	return -(view.xyz / view.w).z;
}


const mat3 sobel_y = mat3(
	vec3(1.0, 0.0, -1.0),
	vec3(2.0, 0.0, -2.0),
	vec3(1.0, 0.0, -1.0)
);

const mat3 sobel_x = mat3(
	vec3(1.0, 2.0, 1.0),
	vec3(0.0, 0.0, 0.0),
	vec3(-1.0, -2.0, -1.0)
);

float edge_value_normal(ivec2 uv, ivec2 pixel_size, mat3 sobel) {
	float result = 0.0;
	vec3 normal = get_normal_roughness_color(uv).rgb;
	vec3 n = get_normal_roughness_color(uv + ivec2(0.0, -pixel_size.y)).rgb;
	vec3 s = get_normal_roughness_color(uv + ivec2(0.0, pixel_size.y)).rgb;
	vec3 e = get_normal_roughness_color(uv + ivec2(pixel_size.x, 0.0)).rgb;
	vec3 w = get_normal_roughness_color(uv + ivec2(-pixel_size.x, 0.0)).rgb;
	vec3 nw = get_normal_roughness_color(uv + ivec2(-pixel_size.x, -pixel_size.y)).rgb;
	vec3 ne = get_normal_roughness_color(uv + ivec2(pixel_size.x, -pixel_size.y)).rgb;
	vec3 sw = get_normal_roughness_color(uv + ivec2(-pixel_size.x, pixel_size.y)).rgb;
	vec3 se = get_normal_roughness_color(uv + ivec2(pixel_size.x, pixel_size.y)).rgb;
	
	mat3 error_mat = mat3(
		vec3(length(normal - nw), length(normal - n), length(normal - ne)),
		vec3(length(normal - w), 0.0, length(normal - e)),
		vec3(length(normal - sw), length(normal - s), length(normal - se))
	);
	
	result += dot(sobel[0], error_mat[0]);
	result += dot(sobel[1], error_mat[1]);
	result += dot(sobel[2], error_mat[2]);
	return abs(result);
}


float edge_value_depth(ivec2 uv, ivec2 pixel_size, mat3 sobel, mat4 inv_projection_matrix){
	float result = 0.0;
	float depth = get_linear_depth(uv);
	float n = get_linear_depth(uv + ivec2(0.0, -pixel_size.y));
	float s = get_linear_depth(uv + ivec2(0.0, pixel_size.y));
	float e = get_linear_depth(uv + ivec2(pixel_size.x, 0.0));
	float w = get_linear_depth(uv + ivec2(-pixel_size.x, 0.0));
	float ne = get_linear_depth(uv + ivec2(pixel_size.x, -pixel_size.y));
	float nw = get_linear_depth(uv + ivec2(-pixel_size.x, -pixel_size.y));
	float se = get_linear_depth(uv + ivec2(pixel_size.x, pixel_size.y));
	float sw = get_linear_depth(uv + ivec2(-pixel_size.x, pixel_size.y));
	
	mat3 error_mat = mat3(
		vec3((depth - nw)/depth, (depth - n)/depth, (depth - ne)/depth),
		vec3((depth - w)/depth, 0.0, (depth - e)/depth),
		vec3((depth - sw)/depth, (depth - s)/depth, (depth - se)/depth)
	);
	
	result += dot(sobel[0], error_mat[0]);
	result += dot(sobel[1], error_mat[1]);
	result += dot(sobel[2], error_mat[2]);
	return abs(result);
}

// Used to construct nearby world positions for noise values instead of the pixel's depth value
// Using the outline's world position value caused a difference in noise scale between sides of the object
float get_nearby_min_depth(ivec2 uv, ivec2 offset)
{
	highp vec2 sample_uv = coord_to_uv(uv);
	highp vec2 sample_uv_n = coord_to_uv(uv + ivec2(0.0, -offset.y));
	highp vec2 sample_uv_s = coord_to_uv(uv + ivec2(0.0, offset.y));
	highp vec2 sample_uv_e = coord_to_uv(uv + ivec2(offset.x, 0.0));
	highp vec2 sample_uv_w = coord_to_uv(uv + ivec2(-offset.x, 0.0));

	float depth = textureLod(depth_sampler, sample_uv, 0.0).r;
	float n = textureLod(depth_sampler, sample_uv_n, 0.0).r;
	float s = textureLod(depth_sampler, sample_uv_s, 0.0).r;
	float e = textureLod(depth_sampler, sample_uv_e, 0.0).r;
	float w = textureLod(depth_sampler, sample_uv_w, 0.0).r;

	return max(max(max(max(depth, n), s), e), w);
}

// Had to do this in godot 4.6 because they changed inv_view_matrix to a 3x4
// This broke how I was getting world_position from depth and world_normal
// Maybe there is a smarter way to get correct values for those and still use 3x4
// but I don't feel like messing with it
mat4 get_inv_view_matrix()
{
	return transpose(mat4(scene.data.inv_view_matrix[0],
			scene.data.inv_view_matrix[1],
			scene.data.inv_view_matrix[2],
			vec4(0.0, 0.0, 0.0, 1.0)));
}

vec3 get_world_normal(vec3 normal)
{
	vec3 view_normal = 2.0 * normal.xyz - 1.0;
	vec3 world_normal = (get_inv_view_matrix() * vec4(view_normal.xyz, 0.0)).xyz;
	return world_normal;
}

vec2 get_NdotL_and_roughness(ivec2 uv, vec3 light_dir)
{
	vec4 normal = get_normal_roughness_color(uv);
	vec3 world_normal = get_world_normal(normal.xyz);
	float NdotL = dot(normalize(world_normal.xyz), normalize(light_dir));
	return vec2(NdotL, normal.a);
}

vec2 get_nearby_max_NdotL_and_max_roughness(ivec2 uv, ivec2 offset, vec3 light_dir)
{
	ivec2 sample_uv_n = (uv + ivec2(0.0, -offset.y));
	ivec2 sample_uv_s = (uv + ivec2(0.0, offset.y));
	ivec2 sample_uv_e = (uv + ivec2(offset.x, 0.0));
	ivec2 sample_uv_w = (uv + ivec2(-offset.x, 0.0));

	vec2 origin = get_NdotL_and_roughness(uv, light_dir);
	vec2 n = get_NdotL_and_roughness(sample_uv_n, light_dir);
	vec2 s = get_NdotL_and_roughness(sample_uv_s, light_dir);
	vec2 e = get_NdotL_and_roughness(sample_uv_e, light_dir);
	vec2 w = get_NdotL_and_roughness(sample_uv_w, light_dir);

	float NdotL = max(max(max(max(origin.x, n.x), s.x), e.x), w.x);
	float roughness = max(max(max(max(origin.y, n.y), s.y), e.y), w.y);
	
	return vec2(NdotL, roughness);
}

ivec2 get_nearby_min_coords(ivec2 uv, ivec2 offset)
{
	ivec2 result = uv;

	highp vec2 sample_uv = coord_to_uv(uv);
	highp vec2 sample_uv_n = coord_to_uv(uv + ivec2(0.0, -offset.y));
	highp vec2 sample_uv_s = coord_to_uv(uv + ivec2(0.0, offset.y));
	highp vec2 sample_uv_e = coord_to_uv(uv + ivec2(offset.x, 0.0));
	highp vec2 sample_uv_w = coord_to_uv(uv + ivec2(-offset.x, 0.0));

	float depth = textureLod(depth_sampler, sample_uv, 0.0).r;
	float n = textureLod(depth_sampler, sample_uv_n, 0.0).r;
	float s = textureLod(depth_sampler, sample_uv_s, 0.0).r;
	float e = textureLod(depth_sampler, sample_uv_e, 0.0).r;
	float w = textureLod(depth_sampler, sample_uv_w, 0.0).r;

	float min_depth = max(max(max(max(depth, n), s), e), w);

	if (min_depth == n)
	{
		result = uv + ivec2(0.0, -offset.y);
	}
	
	if (min_depth == s)
	{
		result = uv + ivec2(0.0, offset.y);
	}

	if (min_depth == e)
	{
		result = uv + ivec2(offset.x, 0.0);
	}

	if (min_depth == w)
	{
		result = uv + ivec2(-offset.x, 0.0);
	}

	return result;
}

float map(float value, float min1, float max1, float min2, float max2) {
  return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}


