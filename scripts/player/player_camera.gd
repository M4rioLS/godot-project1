extends Camera3D
# In your main camera script
func _ready():
	#cull_mask = 1  # Only see main_world layer
	cull_mask = 1 << 0 # Only render main_world (layer 1)
