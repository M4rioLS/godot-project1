extends Node2D

var player = preload("res://scenes/player/player.tscn")
var lobby_id = 0
var peer = SteamMultiplayerPeer.new()
var multiplayer_scene = preload("res://scenes/player/multiplayer_controller.tscn")
@export var _players_spawn_node: Node3D
@onready var lobby_list = $LobbyContainer/Lobbies

@onready var ns = $MultiplayerSpawner

@export var lobby_filter : String = ""

var case_sensitive : bool = false

func _ready():
	ns.spawn_function = spawn_level
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_match_list.connect(_on_lobby_match_list)
	_open_lobby_list()

func _on_host_pressed():
	print("Starting host!")
	
	multiplayer.peer_connected.connect(_add_player_to_game)
	multiplayer.peer_disconnected.connect(_del_player)
	Steam.lobby_joined.connect(_on_lobby_joined.bind())
	Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC) #max members TODO
	#multiplayer.multiplayer_peer = peer
	ns.spawn("res://scenes/levels/main/level_01.tscn") #main/level_01.tscn
	hide_hud_elements()
	
func _on_refresh_pressed():
	if $LobbyContainer/Lobbies.get_child_count() > 0:
		for n in $LobbyContainer/Lobbies.get_children():
			n.queue_free()
	_open_lobby_list()

func spawn_level(data): 
	var a = (load(data) as PackedScene).instantiate()
	return a
	
func hide_hud_elements():
	$Host.hide()
	$LobbyContainer/Lobbies.hide()
	$Refresh.hide()
	$Singleplayer.hide()

func join_as_client(lobby_ID):
	print("Joining lobby %s" % lobby_ID)
	Steam.lobby_joined.connect(_on_lobby_joined.bind())
	Steam.joinLobby(int(lobby_ID))
	hide_hud_elements()
	
func _create_host():
	print("Create Host")
	
	var error = peer.create_host(0)
	
	if error == OK:
		multiplayer.set_multiplayer_peer(peer)
		
		if not OS.has_feature("dedicated_server"):
			_add_player_to_game(1)
	else:
		print("error creating host: %s" % str(error))
		

func _on_lobby_created(_connect,id):
	if _connect == 1:
		lobby_id = id
		Steam.setLobbyData(lobby_id,"name", str(Steam.getPersonaName() + "'s Lobby"))
		Steam.setLobbyJoinable(lobby_id, true)
		
		_create_host()
		
func _on_lobby_joined(lobby: int, permissions: int, locked: bool, response: int):
	print("On lobby joined")
	
	if response == 1:
		var id = Steam.getLobbyOwner(lobby)
		if id != Steam.getSteamID():
			print("Connecting client to socket...")
			connect_socket(id)
	else:
		# Get the failure reason
		var FAIL_REASON: String
		match response:
			2:  FAIL_REASON = "This lobby no longer exists."
			3:  FAIL_REASON = "You don't have permission to join this lobby."
			4:  FAIL_REASON = "The lobby is now full."
			5:  FAIL_REASON = "Uh... something unexpected happened!"
			6:  FAIL_REASON = "You are banned from this lobby."
			7:  FAIL_REASON = "You cannot join due to having a limited account."
			8:  FAIL_REASON = "This lobby is locked or disabled."
			9:  FAIL_REASON = "This lobby is community locked."
			10: FAIL_REASON = "A user in the lobby has blocked you from joining."
			11: FAIL_REASON = "A user you have blocked is in the lobby."
		print(FAIL_REASON)
		
func connect_socket(steam_id: int):
	print("Try Connect Socket...")
	var error = peer.create_client(steam_id, 0)
	if error == OK:
		print("Connecting peer to host...")
		multiplayer.set_multiplayer_peer(peer)
		_add_player_to_game(2) #TEST
	else:
		print("Error creating client: %s" % str(error))

func _on_steam_join(lobby_ID:int):
	#unused!
	peer.connect_lobby(lobby_ID)
	multiplayer.multiplayer_peer = peer
	#UI.visible = false
	%HostClient.text = "Client Steam"
	
func _add_player_to_game(id: int):
	print("Player %s joined the game!" % id)

	var player_to_add = player.instantiate()
	player_to_add.player_id = id
	player_to_add.name = str(id)
	_players_spawn_node.add_child(player_to_add, true)
	
func _del_player(id: int):
	print("Player %s left the game!" % id)
	if not _players_spawn_node.has_node(str(id)):
		return
	_players_spawn_node.get_node(str(id)).queue_free()


func join_lobby(id):
	peer.connect_lobby(id)
	multiplayer.multiplayer_peer = peer
	hide_hud_elements()
	
func _open_lobby_list() -> void:
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	Steam.requestLobbyList()
	
func _on_lobby_match_list(these_lobbies: Array) -> void:
	
	if lobby_list.get_child_count() > 0:
		for n in lobby_list.get_children():
			n.queue_free()
	
	for this_lobby in these_lobbies:
		
		var lobby_name: String = Steam.getLobbyData(this_lobby, "name")
		var lobby_mode: String = Steam.getLobbyData(this_lobby, "mode")
		var lobby_num_members: int = Steam.getNumLobbyMembers(this_lobby)
		
		if lobby_filter != "":
			if !case_sensitive:
				print(lobby_name.to_lower())
				if !lobby_name.to_lower().contains(lobby_filter.to_lower()):
					continue
			else:
				if !lobby_name.contains(lobby_filter):
					continue
		
		var lobby_button: Button = Button.new()
		lobby_button.set_text("Lobby %s: %s [%s] - %s Player(s)" % [this_lobby, lobby_name, lobby_mode, lobby_num_members])
		lobby_button.set_size(Vector2(400/4, 25/4))
		lobby_button.set_name("lobby_%s" % this_lobby)
		lobby_button.connect("pressed", Callable(self, "join_as_client").bind(this_lobby))

		lobby_list.add_child(lobby_button)


func _on_singleplayer_pressed() -> void:
	ns.spawn("res://scenes/levels/rooms/room_01.tscn") #("res://scenes/levels/main/level_01.tscn")
	hide_hud_elements()
	_add_player_to_game(1)
