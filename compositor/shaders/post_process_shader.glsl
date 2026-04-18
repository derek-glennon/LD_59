#[compute]
#version 450

#include "includes/scene_data.glsl"
#include "includes/scene_data_helpers.glsl"

layout(local_size_x = 16, local_size_y = 16, local_size_z = 1) in;

layout(rgba16f, set = 0, binding = 1) uniform image2D color_image;

void main() {

	ivec2 image_coord = ivec2(gl_GlobalInvocationID.xy);

    vec2 screen_uv = coord_to_uv(image_coord);

    int horiz_pixels = int(scene.data.viewport_size.x * 0.01);
    int vert_pixels = int(scene.data.viewport_size.y * 0.01);
    int total_pixels = int(horiz_pixels * vert_pixels);

    vec2 pixelated_uvs = vec2(floor(screen_uv * total_pixels) / total_pixels);
    ivec2 image_coord_pixelated = uv_to_coord(pixelated_uvs);

    vec4 viewport_pixelated = imageLoad(color_image, image_coord_pixelated);

    vec3 debug = vec3(image_coord.x, image_coord.y, 0.0);

	imageStore(color_image, image_coord, viewport_pixelated);
}
