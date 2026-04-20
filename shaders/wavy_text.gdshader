shader_type canvas_item;

uniform float sine_wavelength = 10.0;
uniform float sine_amplitude = 5.0;
uniform float sine_speed = 2.0;

void vertex() {
	VERTEX.y += sin(UV.x * sine_wavelength + TIME * sine_speed) * sine_amplitude;
}

void fragment() {
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
