extends Node3D
class_name LevelGenerator3D

@export var room_size := Vector3(10, 5, 10)
@export var max_rooms := 10
@export var room_variants : Array[PackedScene] = [preload("res://scenes/levels/rooms/room_01.tscn")]

var rooms := {}
var current_room : Room3D
var player : CharacterBody3D

func _ready():
	generate_dungeon()
	spawn_player()

func _process(_delta):
	var player_pos = get_tree().get_first_node_in_group("player").global_position
	var distance = global_position.distance_to(player_pos)
	visible = distance < room_size.length() * 2
	
func generate_dungeon():
	var room_queue = []
	var start_pos = Vector3.ZERO
	
	# Create start room
	var start_room = create_room(start_pos, ["north", "south", "east", "west"])
	rooms[start_pos] = start_room
	room_queue.append(start_pos)
	
	# Generate connected rooms
	while not room_queue.is_empty() and rooms.size() < max_rooms:
		var current_pos = room_queue.pop_front()
		
		for dir in get_random_directions():
			var neighbor_pos = current_pos + direction_to_vector(dir)
			
			if rooms.size() >= max_rooms:
				break
			
			if not rooms.has(neighbor_pos) and randf() < 0.7:
				var connections = []
				var new_room = create_room(neighbor_pos, connections)
				
				# Connect rooms bidirectionally
				rooms[current_pos].doors[dir] = true
				rooms[current_pos].update_doors()
				
				var opposite_dir = get_opposite_direction(dir)
				new_room.doors[opposite_dir] = true
				new_room.update_doors()
				
				rooms[neighbor_pos] = new_room
				room_queue.append(neighbor_pos)

func create_room(pos: Vector3, connections: Array) -> Room3D:
	var room = room_variants.pick_random().instantiate()
	add_child(room)
	room.setup(pos, connections)
	room.position = Vector3(
		pos.x * room_size.x,
		0,
		pos.z * room_size.z
	)
	return room

func direction_to_vector(dir: String) -> Vector3:
	match dir:
		"north": return Vector3(0, 0, -1)
		"south": return Vector3(0, 0, 1)
		"east": return Vector3(1, 0, 0)
		"west": return Vector3(-1, 0, 0)
	return Vector3.ZERO

func get_opposite_direction(dir: String) -> String:
	match dir:
		"north": return "south"
		"south": return "north"
		"east": return "west"
		"west": return "east"
	return ""

func get_random_directions() -> Array[String]:
	var dirs = ["north", "south", "east", "west"]
	dirs.shuffle()
	return dirs

func spawn_player():
	var player_scene = preload("res://scenes/player/player.tscn")
	player = player_scene.instantiate()
	add_child(player)
	player.global_position = rooms[Vector3.ZERO].get_door_position("north") + Vector3(0, 1, 0)
