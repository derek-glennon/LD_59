shader_type spatial;

uniform sampler2D albedo_texture;
uniform vec2 uv_scale = vec2(1.0);
uniform vec2 uv_speed = vec2(0.0);
uniform bool has_overlay = false;
uniform sampler2D overlay_texture;
uniform vec2 overlay_uv_scale = vec2(1.0);
uniform vec3 color_bottom : source_color = vec3(0.0);
uniform vec3 color_top : source_color = vec3(1.0);
uniform float smoothstep_min = 0.0;
uniform float smoothstep_max = 1.0;
uniform float emissive_intensity = 1.0;
uniform float roughness = 0.0;
uniform sampler2D noise_texture;
uniform vec2 noise_uv_scale = vec2(1.0);
uniform vec2 noise_uv_speed = vec2(0.0);
uniform float noise_intensity = 1.0;

uniform float sine_wavelength = 1.0;
uniform float sine_speed = 1.0;
uniform float sine_amplitude = 1.0;


float random (vec2 uv) {
    return fract(sin(dot(uv.xy,
        vec2(12.9898,78.233))) * 43758.5453123);
}

void vertex() {
	float noise = texture(noise_texture, UV * noise_uv_scale + TIME * noise_uv_speed).r;
	float final_amp = mix(sine_amplitude, sine_amplitude * 7.0, 1.0 - UV.y);
	float sine = sin(UV.y * sine_wavelength + TIME * sine_speed) * final_amp;
	VERTEX.x += sine * noise_intensity;
}

void fragment() {
	float texture_sample = texture(albedo_texture, UV * uv_scale + TIME * uv_speed).r;
	float overlay = 0.0;
	if (has_overlay)
	{
		overlay = texture(overlay_texture, UV * overlay_uv_scale).r;
	}
	float gradient = smoothstep(smoothstep_min, smoothstep_max, UV.y);
	vec3 gradient_color = mix(color_bottom, color_top, gradient);
	ALBEDO = gradient_color + texture_sample + overlay;
	EMISSION = (gradient_color + overlay + texture_sample) * emissive_intensity;
	ROUGHNESS = roughness;
	SPECULAR = 0.0;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
