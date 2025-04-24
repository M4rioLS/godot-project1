extends Node

@export var HEALTH = 100.0

func getHealth():
	return HEALTH

func _ready():
	add_to_group("player")
	print("Player group status: ", is_in_group("player"))  # Should output "true"
