# Attach this script to a Label node in your HUD

extends Label

@onready
var player_node = null # Variable to hold a reference to your player node

func _ready():
	# IMPORTANT: Replace "../Player" with the actual NodePath to your player node
	# If your player is in a group named "player", you could use get_tree().get_first_node_in_group("player")
	player_node = get_node("../../Player") 
	if player_node == null:
		print("HUD Scripts Error: Could not find the player node at the specified path.")
		set_text("Error: Player not found!")
		#set_process(false) # Stop updating if player not found

func _process(_delta):
	var player_health = 0
	if player_node != null:
		# IMPORTANT: Replace player_node.health with how you access the player's health
		# This could be a variable (like health) or a method (like get_health())
		#if player_node.has_method("get_health"):
		player_health = player_node.getHealth() #player_node.get_health()
		
		#else:
		#print("HUD Script Error: Player node does not have a 'health' variable or a 'get_health' method.")
		#set_text("Error: No player health found!")
		#set_process(false) # Stop updating if player health not accessible


	# Get the current FPS
	var fps = Engine.get_frames_per_second()

	# Update the label text
	#
	text = str("HP: " + str(player_health) + "   FPS: " + str(round(fps)))
