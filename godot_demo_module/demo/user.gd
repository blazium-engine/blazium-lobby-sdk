extends HBoxContainer

@onready var lobby_client : LobbyClient = $LobbyClient
@onready var message_text := $Message
@onready var command_toggle := $CommandToggle
@onready var logs_text := $Logs

func _ready() -> void:
	lobby_client.received_data.connect(lobby_data)
	lobby_client.received_data_to.connect(data_to)
	lobby_client.lobby_created.connect(lobby_created)
	lobby_client.lobby_joined.connect(lobby_joined)
	lobby_client.lobby_left.connect(lobby_left)
	lobby_client.lobby_sealed.connect(lobby_sealed)
	lobby_client.peer_joined.connect(peer_joined)
	lobby_client.peer_left.connect(peer_left)
	lobby_client.peer_ready.connect(peer_ready)
	lobby_client.peer_messaged.connect(peer_messaged)
	lobby_client.peer_named.connect(peer_named)
	lobby_client.log_updated.connect(log_updated)
	lobby_client.lobby_tagged.connect(lobby_tagged)

	#lobby_client.server_url = "ws://localhost:8080/connect"
	lobby_client.connect_to_lobby()

func log_updated(command: String, logs: String):
	logs_text.text = command + " " + logs

func lobby_data(data: String, from_peer: LobbyPeer):
	print("Callback: %s lobby_data %s" % [get_index(), data])

func data_to(data: String, from_peer: LobbyPeer):
	print("Callback: %s data_to %s" % [get_index(), data])

func lobby_created(lobby: LobbyInfo, peers: Array[LobbyPeer]):
	print("Callback: %s lobby_created %s %s" % [get_index(), lobby.lobby_name, lobby.tags])
	for peer in peers:
		print("Callback: %s lobby_created peer: " % get_index(), peer.id, " ", peer.peer_name, " ", peer.ready)

func lobby_joined(lobby: LobbyInfo, peers: Array[LobbyPeer]):
	print("Callback: %s lobby_joined %s" % [get_index(), lobby.lobby_name])
	for peer in peers:
		print("Callback: %s lobby_joined peer: "  % get_index(), peer.id, " ", peer.peer_name, " ", peer.ready)

func lobby_left(kicked: bool):
	print("Callback: %s lobby_left kicked %s" % [get_index(), kicked])

func peer_joined(peer: LobbyPeer):
	print("Callback: %s peer_joined %s %s" % [get_index(), peer.id, peer.peer_name])

func peer_left(peer: LobbyPeer, kicked: bool):
	print("Callback: %s peer_left %s %s" % [get_index(), peer.id, kicked])
	
func peer_ready(peer: LobbyPeer, ready: bool):
	print("Callback: %s peer_ready %s" % [get_index(), peer.id])

func peer_named(peer: LobbyPeer):
	print("Callback: %s peer_named %s %s" % [get_index(), peer.id, peer.peer_name])

func peer_messaged(peer: LobbyPeer, message: String):
	print("Callback: %s peer_messaged %s %s" % [get_index(), peer.id, message])

func lobby_sealed(sealed: bool):
	print("Callback: %s lobby_sealed" % [get_index()])

func lobby_tagged(tags: Dictionary):
	print("Callback: %s lobby_tagged tags %s" % [get_index(), tags])

func _on_button_pressed() -> void:
	var item = command_toggle.get_item_text(command_toggle.selected)
	var message = message_text.text
	match item:
		"create_lobby":
			var result : ViewLobbyResult = await lobby_client.create_lobby(message, {"tag1": 1, "tag2": 2, "tag3": 3}, 4, "").finished
			if result.has_error():
				print("Create Error %s: " % get_index(), result.error)
			else:
				print("Create Result %s: " % get_index(), result.lobby.id, " ", result.lobby.max_players, " ", result.lobby.sealed)
				for peer in result.peers:
					print("Create Peer %s: "  % get_index(), peer.id, " ", peer.peer_name, " ", peer.ready)
		"join_lobby":
			var result : ViewLobbyResult = await lobby_client.join_lobby(message).finished
			if result.has_error():
				print("Join Error %s: " % get_index(), result.error)
			else:
				print("Join Result %s: " % get_index(), result.lobby.host, " ", result.lobby.max_players, " ", result.lobby.sealed)
				for peer in result.peers:
					print("Join Peer %s: " % get_index(), peer.id, " ", peer.peer_name, " ", peer.ready)
		"leave_lobby":
			var result :LobbyResult = await lobby_client.leave_lobby().finished
			if result.has_error():
				print("Leave Error %s: " % get_index(), result.error)
			else:
				print("Leave Result %s: Success" % get_index())
		"list_lobby":
			var result :ListLobbyResult = await lobby_client.list_lobbies({"tag1": null}).finished
			if result.has_error():
				print("List Error %s: " % get_index(), result.error)
			else:
				for lobby in result.lobbies:
					print("List Result %s: " % get_index(), lobby.host, " ", lobby.id, " ", lobby.host_name, " ", lobby.max_players, " ", lobby.players, " ", lobby.sealed, " ", lobby.lobby_name)
		"view_lobby":
			var result :ViewLobbyResult = await lobby_client.view_lobby(message, "").finished
			if result.has_error():
				print("View Error %s: " % get_index(), result.error)
			else:
				print("View Result %s: " % get_index(), result.lobby.host, " ", result.lobby.max_players, " ", result.lobby.sealed)
				for peer in result.peers:
					print("View Peer %s: "  % get_index(), peer.id, " ", peer.peer_name, " ", peer.ready)
		"kick_peer":
			var result :LobbyResult = await lobby_client.kick_peer(message).finished
			if result.has_error():
				print("Kick Error %s: " % get_index(), result.error)
			else:
				print("Kick Result %s: Success" % get_index())
		"lobby_ready":
			var result :LobbyResult = await lobby_client.set_lobby_ready(true).finished
			if result.has_error():
				print("Ready Error %s: " % get_index(), result.error)
			else:
				print("Ready Result %s: Success" % get_index())
		"lobby_sealed":
			var result :LobbyResult = await lobby_client.set_lobby_sealed(true).finished
			if result.has_error():
				print("Sealed Error %s: " % get_index(), result.error)
			else:
				print("Sealed Result %s: Success" % get_index())
		"lobby_unsealed":
			var result :LobbyResult = await lobby_client.set_lobby_sealed(false).finished
			if result.has_error():
				print("Unsealed Error %s: " % get_index(), result.error)
			else:
				print("Unsealed Result %s: Success" % get_index())
		"lobby_chat":
			var result :LobbyResult = await lobby_client.send_chat_message(message).finished
			if result.has_error():
				print("Chat Error %s: " % get_index(), result.error)
			else:
				print("Chat Result %s: Success" % get_index())
		"lobby_unready":
			var result :LobbyResult = await lobby_client.set_lobby_ready(false).finished
			if result.has_error():
				print("Unready Error %s: " % get_index(), result.error)
			else:
				print("Unready Result %s: Success" % get_index())
		"set_name":
			var result :LobbyResult = await lobby_client.set_peer_name(message).finished
			if result.has_error():
				print("Set Name Error %s: " % get_index(), result.error)
			else:
				print("Set Name %s: Success" % get_index())
		"seal_lobby":
			var result :LobbyResult = await lobby_client.set_lobby_sealed(true).finished
			if result.has_error():
				print("Seal Error %s: " % get_index(), result.error)
			else:
				print("Seal Result %s: Success" % get_index())
		"unseal_lobby":
			var result :LobbyResult = await lobby_client.set_lobby_sealed(false).finished
			if result.has_error():
				print("Unseal Error %s: " % get_index(), result.error)
			else:
				print("Unseal Result %s: Success" % get_index())
		"lobby_data":
			var result :LobbyResult = await lobby_client.send_lobby_data(message).finished
			if result.has_error():
				print("Lobby Data Error %s: " % get_index(), result.error)
			else:
				print("Lobby Data Result %s: Success" % get_index())
		"data_to":
			var result :LobbyResult = await lobby_client.send_lobby_data_to("message", message).finished
			if result.has_error():
				print("Lobby Data Error %s: " % get_index(), result.error)
			else:
				print("Lobby Data Result %s: Success" % get_index())
		"lobby_tags":
			var result :LobbyResult = await lobby_client.set_lobby_tags({message: 1}).finished
			if result.has_error():
				print("Tags Error %s: " % get_index(), result.error)
			else:
				print("Tags Result %s: Success" % get_index())
