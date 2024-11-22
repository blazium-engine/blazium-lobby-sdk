extends HBoxContainer

@onready var lobby : BlaziumLobby = $BlaziumLobby
@onready var message_text := $Message
@onready var command_toggle := $CommandToggle
@onready var logs_text := $Logs

func _ready() -> void:
	lobby.lobby_created.connect(lobby_created)
	lobby.lobby_joined.connect(lobby_joined)
	lobby.lobby_left.connect(lobby_left)
	lobby.lobby_sealed.connect(lobby_sealed)
	lobby.lobby_unsealed.connect(lobby_unsealed)
	lobby.peer_joined.connect(peer_joined)
	lobby.peer_left.connect(peer_left)
	lobby.peer_ready.connect(peer_ready)
	lobby.peer_unready.connect(peer_unready)
	lobby.append_log.connect(append_log)

	lobby.connect_to_lobby("demo_game", "ws://localhost:8080/connect")

func append_log(command: String, logs: String):
	logs_text.text = command + " " + logs

func lobby_created(lobby: String):
	print("Callback: %s lobby_created %s" % [get_index(), lobby])

func lobby_joined(lobby: String):
	print("Callback: %s lobby_joined %s" % [get_index(), lobby])

func lobby_left():
	print("Callback: %s lobby_left" % [get_index()])

func peer_joined(lobby_peer: String):
	print("Callback: %s peer_joined %s" % [get_index(), lobby_peer])

func peer_left(lobby_peer: String):
	print("Callback: %s peer_left %s" % [get_index(), lobby_peer])
	
func peer_ready(lobby_peer: String):
	print("Callback: %s peer_ready %s" % [get_index(), lobby_peer])

func peer_unready(lobby_peer: String):
	print("Callback: %s peer_unready %s" % [get_index(), lobby_peer])

func lobby_sealed():
	print("Callback: %s lobby_sealed" % [get_index()])

func lobby_unsealed():
	print("Callback: %s lobby_unsealed" % [get_index()])

func _on_button_pressed() -> void:
	var item = command_toggle.get_item_text(command_toggle.selected)
	var message = message_text.text
	match item:
		"create_lobby":
			var result :BlaziumLobby.CreateLobby.Response = await lobby.create_lobby(4).finished
			if result.has_error():
				print("Create Error %s: " % get_index(), result.get_error())
			else:
				print("Create Result %s: " % get_index(), result.get_lobby_name())
		"join_lobby":
			var result :BlaziumLobby.LobbyResponse.Response = await lobby.join_lobby(message).finished
			if result.has_error():
				print("Join Error %s: " % get_index(), result.get_error())
			else:
				print("Join Result %s: Success" % get_index())
		"leave_lobby":
			var result :BlaziumLobby.LobbyResponse.Response = await lobby.leave_lobby().finished
			if result.has_error():
				print("Leave Error %s: " % get_index(), result.get_error())
			else:
				print("Leave Result %s: Success" % get_index())
		"list_lobby":
			var result :BlaziumLobby.ListLobby.Response = await lobby.list_lobby().finished
			if result.has_error():
				print("List Error %s: " % get_index(), result.get_error())
			else:
				print("List Result %s: " % get_index(), result.get_lobbies())
		"view_lobby":
			var result :BlaziumLobby.ViewLobby.Response = await lobby.view_lobby(message, "").finished
			if result.has_error():
				print("View Error %s: " % get_index(), result.get_error())
			else:
				print("View Result %s: " % get_index(), result.get_lobby_info().host, " ", result.get_lobby_info().max_players, " ", result.get_lobby_info().sealed)
				for peer in result.get_peers():
					print("View Result Peer %s: "  % get_index(), peer.id, " ", peer.name, " ", peer.ready)
		"kick_peer":
			var result :BlaziumLobby.LobbyResponse.Response = await lobby.kick_peer(message).finished
			if result.has_error():
				print("Kick Error %s: " % get_index(), result.get_error())
			else:
				print("Kick Result %s: Success" % get_index())
		"lobby_ready":
			var result :BlaziumLobby.LobbyResponse.Response = await lobby.lobby_ready().finished
			if result.has_error():
				print("Ready Error %s: " % get_index(), result.get_error())
			else:
				print("Ready Result %s: Success" % get_index())
		"lobby_unready":
			var result :BlaziumLobby.LobbyResponse.Response = await lobby.lobby_unready().finished
			if result.has_error():
				print("Unready Error %s: " % get_index(), result.get_error())
			else:
				print("Unready Result %s: Success" % get_index())
		"seal_lobby":
			var result :BlaziumLobby.LobbyResponse.Response = await lobby.seal_lobby().finished
			if result.has_error():
				print("Seal Error %s: " % get_index(), result.get_error())
			else:
				print("Seal Result %s: Success" % get_index())
		"unseal_lobby":
			var result :BlaziumLobby.LobbyResponse.Response = await lobby.unseal_lobby().finished
			if result.has_error():
				print("Unseal Error %s: " % get_index(), result.get_error())
			else:
				print("Unseal Result %s: Success" % get_index())
