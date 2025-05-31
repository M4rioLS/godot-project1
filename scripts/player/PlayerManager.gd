# PlayerManager.gd (autoload)
extends Node

# Dictionary to cache player references: {peer_id: player_node}
var _players = {}

# Register a player when it enters the scene
func register_player(player: CharacterBody3D):
	var peer_id = player.name.to_int()
	if peer_id > 0:  # Ensure valid ID
		_players[peer_id] = player

# Unregister a player when it leaves the scene
func unregister_player(player: CharacterBody3D):
	var peer_id = player.name.to_int()
	if _players.has(peer_id):
		_players.erase(peer_id)

# Main function to get player by peer ID
func get_player_by_id(peer_id: int) -> CharacterBody3D:
	# Check cache first
	if _players.has(peer_id):
		return _players[peer_id]
	
	# Fallback search
	return _find_player_by_id(peer_id)

# Recursive search function
func _find_player_by_id(peer_id: int) -> CharacterBody3D:
	var player_name = str(peer_id)
	var root = get_tree().root
	
	# Breadth-first search for efficiency
	var queue = [root]
	while queue:
		var node = queue.pop_front()
		
		# Check if this is the player node
		if node is CharacterBody3D and node.name == player_name:
			_players[peer_id] = node  # Cache result
			return node
		
		# Add children to queue
		for child in node.get_children():
			queue.append(child)
	
	return null
