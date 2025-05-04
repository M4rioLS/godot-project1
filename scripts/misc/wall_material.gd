extends MeshInstance3D

#renders as solid blue for minimap
func _ready():
	# Only affect minimap camera view
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.DARK_BLUE
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	set_layer_mask_value(2, true)  # Only visible to minimap layer
	set_layer_mask_value(1, false)  # Only visible to minimap layer
	set_surface_override_material(0, mat)
