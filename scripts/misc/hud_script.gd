# Attach this script to a Label node in your HUD

extends Label

@onready
var player_node: Node3D = null # Variable to hold a reference to your player node

func _ready():
	player_node = get_node("../../Player") 
	if player_node == null:
		print("HUD Scripts Error: Could not find the player node at the specified path.")
		set_text("Error: Player not found!")
		#set_process(false) # Stop updating if player not found

func _process(_delta):
	var player_health: float = 0
	var carried_value: float = 0
	var carried_object: RigidBody3D = null
	if player_node != null:
		player_health = player_node.getHealth() #player_node.get_health()
		carried_object = player_node.getCarriedObject()
		if carried_object:
			carried_value = carried_object.money_value


	# Get the current FPS
	var fps = Engine.get_frames_per_second()

	# Update the label text
	#
	text = str("HP: " + str(player_health) + "   VAL: " + str(round(carried_value)) + "   FPS: " + str(round(fps)))
