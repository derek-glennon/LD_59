#[compute]
#version 450

#include "includes/scene_data.glsl"
#include "includes/scene_data_helpers.glsl"

layout(local_size_x = 16, local_size_y = 16, local_size_z = 1) in;

layout(rgba16f, set = 0, binding = 1) uniform image2D color_image;
layout(set = 1, binding = 0) uniform sampler2D palette_1;
layout(set = 1, binding = 1) uniform sampler2D palette_2;

const float bayerMatrix8x8[64] = float[64](
    0.0/ 64.0, 48.0/ 64.0, 12.0/ 64.0, 60.0/ 64.0,  3.0/ 64.0, 51.0/ 64.0, 15.0/ 64.0, 63.0/ 64.0,
  32.0/ 64.0, 16.0/ 64.0, 44.0/ 64.0, 28.0/ 64.0, 35.0/ 64.0, 19.0/ 64.0, 47.0/ 64.0, 31.0/ 64.0,
    8.0/ 64.0, 56.0/ 64.0,  4.0/ 64.0, 52.0/ 64.0, 11.0/ 64.0, 59.0/ 64.0,  7.0/ 64.0, 55.0/ 64.0,
  40.0/ 64.0, 24.0/ 64.0, 36.0/ 64.0, 20.0/ 64.0, 43.0/ 64.0, 27.0/ 64.0, 39.0/ 64.0, 23.0/ 64.0,
    2.0/ 64.0, 50.0/ 64.0, 14.0/ 64.0, 62.0/ 64.0,  1.0/ 64.0, 49.0/ 64.0, 13.0/ 64.0, 61.0/ 64.0,
  34.0/ 64.0, 18.0/ 64.0, 46.0/ 64.0, 30.0/ 64.0, 33.0/ 64.0, 17.0/ 64.0, 45.0/ 64.0, 29.0/ 64.0,
  10.0/ 64.0, 58.0/ 64.0,  6.0/ 64.0, 54.0/ 64.0,  9.0/ 64.0, 57.0/ 64.0,  5.0/ 64.0, 53.0/ 64.0,
  42.0/ 64.0, 26.0/ 64.0, 38.0/ 64.0, 22.0/ 64.0, 41.0/ 64.0, 25.0/ 64.0, 37.0/ 64.0, 21.0 / 64.0
);

vec3 dither(vec2 uv, float lum, sampler2D palette) {
  vec3 color = vec3(lum);

  int x = int(uv.x * scene.data.viewport_size.x) % 8;
  int y = int(uv.y * scene.data.viewport_size.y) % 8;
  float threshold = bayerMatrix8x8[y * 8 + x] - 0.88;

  color.rgb += threshold * 0.2;
  color.r = floor(color.r * (4.0 - 1.0) + 0.5) / (4.0 - 1.0);
  color.g = floor(color.g * (4.0 - 1.0) + 0.5) / (4.0 - 1.0);
  color.b = floor(color.b * (4.0 - 1.0) + 0.5) / (4.0 - 1.0);

  vec3 paletteColor = texture(palette, vec2(color.r)).rgb;

  return paletteColor;
}

float roundToDecimalPlace(float value, int decimalPlaces) {
    // Calculate the power of 10 needed to shift the decimal point
    float scale = pow(10.0, float(decimalPlaces));
    
    // Shift, round, and shift back
    return round(value * scale) / scale;
}

void main() {

	ivec2 image_coord = ivec2(gl_GlobalInvocationID.xy);
    vec4 viewport_color = imageLoad(color_image, image_coord);    
    vec2 screen_uv = coord_to_uv(image_coord);

    // Roughness Flag
    // 1 - Water
    // 2 - Sand
    vec4 normal = get_normal_roughness_color(image_coord);
    float rounded_roughness = roundToDecimalPlace(normal.a, 2);
    float roughness_flag = trunc(rounded_roughness * 10.0);
    float lum = dot(vec3(0.2126, 0.7152, 0.0722), viewport_color.rgb);
    vec3 dither_color = dither(screen_uv, lum, palette_1);
    if (roughness_flag == 2)
    {
        dither_color = dither(screen_uv, lum, palette_2);
    }

    vec4 final_color = vec4(dither_color, viewport_color.a);

	imageStore(color_image, image_coord, final_color);
}
