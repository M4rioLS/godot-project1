extends Node

@export var HEALTH = 100.0

func getHealth():
	return HEALTH

func _ready():
	add_to_group("npc")
	print("Npc group status: ", is_in_group("npc"))  # Should output "true"
