extends HBoxContainer

@onready var lobby : LobbyClient = $LobbyClient
@onready var message_text := $Message
@onready var command_toggle := $CommandToggle
@onready var logs_text := $Logs

func _ready() -> void:
	lobby.received_data.connect(lobby_data)
	lobby.received_data_to.connect(data_to)
	lobby.lobby_created.connect(lobby_created)
	lobby.lobby_joined.connect(lobby_joined)
	lobby.lobby_left.connect(lobby_left)
	lobby.lobby_sealed.connect(lobby_sealed)
	lobby.lobby_unsealed.connect(lobby_unsealed)
	lobby.peer_joined.connect(peer_joined)
	lobby.peer_left.connect(peer_left)
	lobby.peer_ready.connect(peer_ready)
	lobby.peer_unready.connect(peer_unready)
	lobby.peer_named.connect(peer_named)
	lobby.append_log.connect(append_log)

	#lobby.connect_to_lobby("demo_game", "ws://localhost:8080/connect")
	lobby.connect_to_lobby("demo_game")

func append_log(command: String, logs: String):
	logs_text.text = command + " " + logs

func lobby_data(data: String):
	print("Callback: %s lobby_data %s" % [get_index(), data])

func data_to(data: String):
	print("Callback: %s data_to %s" % [get_index(), data])

func lobby_created(lobby: String):
	print("Callback: %s lobby_created %s" % [get_index(), lobby])

func lobby_joined(lobby: String):
	print("Callback: %s lobby_joined %s" % [get_index(), lobby])

func lobby_left():
	print("Callback: %s lobby_left" % [get_index()])

func peer_joined(peer_id: String, peer_name: String):
	print("Callback: %s peer_joined %s %s" % [get_index(), peer_id, peer_name])

func peer_left(lobby_peer: String, kicked: bool):
	print("Callback: %s peer_left %s %s" % [get_index(), lobby_peer, kicked])
	
func peer_ready(lobby_peer: String):
	print("Callback: %s peer_ready %s" % [get_index(), lobby_peer])

func peer_unready(lobby_peer: String):
	print("Callback: %s peer_unready %s" % [get_index(), lobby_peer])

func peer_named(peer_id: String, peer_name: String):
	print("Callback: %s peer_named %s %s" % [get_index(), peer_id, peer_name])

func lobby_sealed():
	print("Callback: %s lobby_sealed" % [get_index()])

func lobby_unsealed():
	print("Callback: %s lobby_unsealed" % [get_index()])

func _on_button_pressed() -> void:
	var item = command_toggle.get_item_text(command_toggle.selected)
	var message = message_text.text
	match item:
		"create_lobby":
			var result :LobbyClient.CreateLobby.Response = await lobby.create_lobby(4).finished
			print(typeof(result))
			if result.has_error():
				print("Create Error %s: " % get_index(), result.get_error())
			else:
				print("Create Result %s: " % get_index(), result.get_lobby_name())
		"join_lobby":
			var result :LobbyClient.LobbyResponse.Response = await lobby.join_lobby(message).finished
			if result.has_error():
				print("Join Error %s: " % get_index(), result.get_error())
			else:
				print("Join Result %s: Success" % get_index())
		"leave_lobby":
			var result :LobbyClient.LobbyResponse.Response = await lobby.leave_lobby().finished
			if result.has_error():
				print("Leave Error %s: " % get_index(), result.get_error())
			else:
				print("Leave Result %s: Success" % get_index())
		"list_lobby":
			var result :LobbyClient.ListLobby.Response = await lobby.list_lobby().finished
			if result.has_error():
				print("List Error %s: " % get_index(), result.get_error())
			else:
				print("List Result %s: " % get_index(), result.get_lobbies())
		"view_lobby":
			var result :LobbyClient.ViewLobby.Response = await lobby.view_lobby(message, "").finished
			if result.has_error():
				print("View Error %s: " % get_index(), result.get_error())
			else:
				print("View Result %s: " % get_index(), result.get_lobby_info().host, " ", result.get_lobby_info().max_players, " ", result.get_lobby_info().sealed)
				for peer in result.get_peers():
					print("View Result Peer %s: "  % get_index(), peer.id, " ", peer.name, " ", peer.ready)
		"kick_peer":
			var result :LobbyClient.LobbyResponse.Response = await lobby.kick_peer(message).finished
			if result.has_error():
				print("Kick Error %s: " % get_index(), result.get_error())
			else:
				print("Kick Result %s: Success" % get_index())
		"lobby_ready":
			var result :LobbyClient.LobbyResponse.Response = await lobby.lobby_ready().finished
			if result.has_error():
				print("Ready Error %s: " % get_index(), result.get_error())
			else:
				print("Ready Result %s: Success" % get_index())
		"lobby_unready":
			var result :LobbyClient.LobbyResponse.Response = await lobby.lobby_unready().finished
			if result.has_error():
				print("Unready Error %s: " % get_index(), result.get_error())
			else:
				print("Unready Result %s: Success" % get_index())
		"set_name":
			var result :LobbyClient.LobbyResponse.Response = await lobby.set_peer_name(message).finished
			if result.has_error():
				print("Set Name Error %s: " % get_index(), result.get_error())
			else:
				print("Set Name %s: Success" % get_index())
		"seal_lobby":
			var result :LobbyClient.LobbyResponse.Response = await lobby.seal_lobby().finished
			if result.has_error():
				print("Seal Error %s: " % get_index(), result.get_error())
			else:
				print("Seal Result %s: Success" % get_index())
		"unseal_lobby":
			var result :LobbyClient.LobbyResponse.Response = await lobby.unseal_lobby().finished
			if result.has_error():
				print("Unseal Error %s: " % get_index(), result.get_error())
			else:
				print("Unseal Result %s: Success" % get_index())
		"lobby_data":
			var result :LobbyClient.LobbyResponse.Response = await lobby.lobby_data(message).finished
			if result.has_error():
				print("Lobby Data Error %s: " % get_index(), result.get_error())
			else:
				print("Lobby Data Result %s: Success" % get_index())
		"data_to":
			var result :LobbyClient.LobbyResponse.Response = await lobby.lobby_data_to("message", message).finished
			if result.has_error():
				print("Lobby Data Error %s: " % get_index(), result.get_error())
			else:
				print("Lobby Data Result %s: Success" % get_index())
