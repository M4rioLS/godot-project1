# Attach this script to a Label node in your HUD

extends Label

@onready var parent_node: Node3D = null # Variable to hold a reference to your player node
@onready var player_node: CharacterBody3D = null # Variable to hold a reference to your player node

func _ready():
	parent_node = get_node("../../../Players/") 
	_find_player()
	if player_node == null:
		print("HUD Scripts Error: Could not find the player node at the specified path.")
		set_text("Error: Player not found!")
		#set_process(false) # Stop updating if player not found
func _find_player():
	var children = parent_node.get_children()
	for child in children:
			if child is CharacterBody3D:
				player_node = child # This is the next CharacterBody3D
				return
				
func _process(_delta):
	if player_node == null:
		_find_player()
	var player_health: float = 0
	var carried_value: float = 0
	var player_stamina: float = 0
	var carried_object: RigidBody3D = null
	if player_node != null:
		player_health = player_node.HEALTH #player_node.get_health()
		carried_object = player_node.carried_object
		player_stamina = player_node.STAMINA
		if carried_object:
			carried_value = carried_object.money_value


	# Get the current FPS
	var fps = Engine.get_frames_per_second()

	# Update the label text
	#
	text = str("HP: " + str(player_health) + "   STA: " + str(round(player_stamina)) + "   VAL: " + str(round(carried_value)) + "   FPS: " + str(round(fps)))
