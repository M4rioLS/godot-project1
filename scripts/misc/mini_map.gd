extends CanvasLayer

@export var zoom: float = 0.5
@export var camera_height: float = 20.0  # Height above player
@export var map_radius: float = 500
@export var player_color := Color.GREEN
@export var enemy_color := Color.RED
@export var item_color := Color.YELLOW
@export var wall_color := Color.DARK_BLUE

@export var enemy_radius := 4.0

@onready var viewport := $SubViewport
@onready var map_texture := $TextureRect
@onready var camera := $SubViewport/Camera3D
@onready var parent_node: Node3D = null # Variable to hold a reference to your player node

var player: CharacterBody3D
var walls: TileMap
var enemies: Array
var items: Array
var vec2: Vector2

func _ready():
	parent_node = get_node("../../Players/") 
	# Configure viewport
	viewport.size = Vector2i(250, 250)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	map_texture.texture = viewport.get_texture()
	# Configure camera
	if is_instance_valid(player):
		camera.position = Vector3(
			player.global_position.x,
			camera_height,
			player.global_position.z
		)
		
	camera.cull_mask = 0b10  # Only see layer 2 (minimap_world)
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.TRANSPARENT
	camera.environment = env
	camera.environment.background_mode = Environment.BG_COLOR
	camera.environment.background_color = Color.DIM_GRAY
	
	# Find relevant nodes
	player = _find_player()
	walls = get_tree().get_first_node_in_group("walls")
	#camera.zoom = Vector2(zoom, zoom)
	
func _find_player():
	var children = parent_node.get_children()
	for child in children:
			if child is CharacterBody3D:
				player = child # This is the next CharacterBody3D
				return
				
func _process(delta: float):
	if player == null:
		_find_player()
	if is_instance_valid(player):
		# Follow player position while maintaining height
		camera.position = Vector3(
			player.global_position.x,
			camera_height,
			player.global_position.z
		)

func _draw():
	if !viewport: return
	
	vec2 = Vector2(player.global_position.x, player.global_position.y)
	# Draw walls
	if walls:
		var used_rect = walls.get_used_rect()
		for cell in walls.get_used_cells(0):
			var pos = walls.map_to_local(cell)
			if pos.distance_to(vec2) < map_radius:
				viewport.get_node("CustomRenderer").draw_rect(
					Rect2(pos - Vector2(4,4), Vector2(8,8)))#, wall_color)

	# Draw player
	viewport.get_node("CustomRenderer").draw_rect(
		Rect2(Vector2(-5,-5), Vector2(10,10)))#, player_color)
	
	# Draw enemies
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.global_position.distance_to(player.global_position) < map_radius:
			viewport.get_node("CustomRenderer").draw_rect(
				Rect2(enemy.global_position - Vector2(3,3), Vector2(6,6)))#, enemy_color)
	
	# Draw items
	for item in get_tree().get_nodes_in_group("items"):
		if item.global_position.distance_to(player.global_position) < map_radius:
			viewport.get_node("CustomRenderer").draw_circle(
				item.global_position, 4, item_color)
