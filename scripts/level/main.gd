extends Node2D

var lobby_id = 0
var peer = SteamMultiplayerPeer.new()
@onready var lobby_list = $LobbyContainer/Lobbies

@onready var ns = $MultiplayerSpawner

@export var lobby_filter : String = ""

var case_sensitive : bool = false

func _ready():
	ns.spawn_function = spawn_level
	Steam.lobby_created.connect(_on_lobby_created)

func _on_host_pressed():
	Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC)
	multiplayer.multiplayer_peer = peer
	ns.spawn("res://scenes/levels/level_01.tscn")
	$Host.hide()

func spawn_level(data): 
	var a = (load(data) as PackedScene).instantiate()
	return a

func _on_lobby_created(connect,id):
	if connect:
		lobby_id = id
		Steam.setLobbyData(lobby_id,"name", str(Steam.getPersonaName() + "'s Lobby"))
		Steam.setLobbyJoinable(lobby_id, true)

func _on_steam_join(lobby_id:int):
	peer.connect_lobby(lobby_id)
	multiplayer.multiplayer_peer = peer
	#UI.visible = false
	%HostClient.text = "Client Steam"


func join_lobby(id):
	peer.connect_lobby(id)
	multiplayer.multiplayer_peer = peer
	$Host.hide()
	
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
		lobby_button.connect("pressed", Callable(self, "_on_steam_join").bind(this_lobby))

		lobby_list.add_child(lobby_button)
