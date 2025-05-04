shader_type spatial;

uniform int cull_mask : hint_range(0, 1048576) = 1;

void fragment() {
    ALBEDO = vec3(0.0, 0.0, 1.0); // Base color (red)
    ALPHA = (int(CAMERA_VISIBLE_LAYERS) & cull_mask) == cull_mask ? 1.0 : 0.125;
    
    // For red materials, change ALBEDO to vec3(1.0, 0.0, 0.0)
}
void vertex() {
	// Called for every vertex the material is visible on.
}
//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
