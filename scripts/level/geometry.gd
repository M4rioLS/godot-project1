extends Node3D

@export var enable_layers := [1, 2]  # Layers to enable (main_world and minimap_world)

func _ready():
	_set_layers_recursive(self)

func _set_layers_recursive(node: Node):
	for child in node.get_children():
		if child is MeshInstance3D:
			_apply_layers(child)
		# Continue recursively through all children
		_set_layers_recursive(child)

func _apply_layers(mesh: MeshInstance3D):
	# Convert layer numbers to bitmask (e.g. [1,2] becomes 0b11)
	var layer_mask = 0
	for layer in enable_layers:
		layer_mask |= 1 << (layer - 1)
	mesh.layers = layer_mask
