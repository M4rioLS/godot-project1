extends MultiplayerSpawner

@export var playerScene : PackedScene


func _ready():
	
	spawn_function = spawnPlayer
	if is_multiplayer_authority():
		spawn(1)
		multiplayer.peer_connected.connect(spawn)
		multiplayer.peer_disconnected.connect(removePlayer)
	pass

var player = {}

func spawnPlayer(data):
	var p = playerScene.instantiate()
	p.set_multiplayer_authority(data)
	player[data] = p
	return p
	

func removePlayer(data):
	player[data].queue_free()
	player.erase(data)
