extends CharacterBody3D
var direction = 1
@export var player_id := 1:
	set(id):
		player_id = id
		%InputSynchronizer.set_multiplayer_authority(id)

func apply_position(delta):
	direction = %InputSynchronizer.input_direction
	
	
