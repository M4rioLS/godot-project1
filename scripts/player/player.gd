extends Node

@export var MAX_HEALTH = 100.0
var HEALTH = MAX_HEALTH
@export var MAX_STAMINA = 100.0
var STAMINA = MAX_STAMINA

# --- Node References ---
@onready var character: CharacterBody3D = $CharacterBody3D

func getHealth():
	return HEALTH
	
func getCarriedObject():
		return character.carried_object

func _ready():
	add_to_group("player")
	print("Player group status: ", is_in_group("player"))  # Should output "true"
