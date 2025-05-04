extends Node

@export var MAX_HEALTH = 100.0
var HEALTH = MAX_HEALTH
@export var MAX_STAMINA = 100.0
var STAMINA = MAX_STAMINA


func getHealth():
	return HEALTH

func _ready():
	add_to_group("player")
	print("Player group status: ", is_in_group("player"))  # Should output "true"
