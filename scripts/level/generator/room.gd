extends Node3D
class_name Room3D

@export var room_size := Vector3(10, 5, 10)  # X, Y, Z dimensions
var grid_position := Vector3.ZERO
var player = preload("res://scenes/player/player.tscn")
@export var doors := {
	"north": false,
	"south": false,
	"east": false,
	"west": false
}

func _ready():
	#DEBUG
	var debug_mesh = ImmediateMesh.new()
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.RED
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = debug_mesh
	mesh_instance.material_override = mat
	add_child(mesh_instance)
	
	debug_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	debug_mesh.surface_add_vertex(Vector3.ZERO)
	debug_mesh.surface_add_vertex(Vector3(2, 0, 0))
	debug_mesh.surface_add_vertex(Vector3.ZERO)
	debug_mesh.surface_add_vertex(Vector3(0, 2, 0))
	debug_mesh.surface_add_vertex(Vector3.ZERO)
	debug_mesh.surface_add_vertex(Vector3(0, 0, 2))
	debug_mesh.surface_end()
	
	var instance = player.instantiate()
	add_child(instance)

func setup(pos: Vector3, connections: Array[String]):
	grid_position = pos
	for dir in connections:
		doors[dir] = true
	update_doors()

func update_doors():
	for door in doors:
		var door_node = get_node_or_null("Doors/" + door.capitalize() + "Door")
		if door_node:
			door_node.visible = doors[door]
			door_node.get_node("Area3D/CollisionShape3D").disabled = !doors[door]

func get_door_position(direction: String) -> Vector3:
	var door = get_node("Doors/" + direction.capitalize() + "Door")
	return door.global_position
