extends HBoxContainer

@onready var lobby_client : AuthoritativeLobbyClient = $AuthoritativeLobbyClient
@onready var message_text := $VBoxContainer/Message
@onready var message_text2 := $VBoxContainer/Message2
@onready var message_text3 := $VBoxContainer2/Message
@onready var message_text4 := $VBoxContainer2/Message2
@onready var command_toggle := $CommandToggle
@onready var logs_text := $Logs
@export var result_text: RichTextLabel

func _ready() -> void:
	lobby_client.connected_to_lobby.connect(connected_to_lobby)
	lobby_client.disconnected_from_lobby.connect(disconnected_from_lobby)
	lobby_client.lobby_notified.connect(lobby_notified)
	lobby_client.received_peer_data.connect(received_peer_data)
	lobby_client.received_lobby_data.connect(received_lobby_data)
	lobby_client.received_peer_user_data.connect(received_peer_user_data)
	lobby_client.lobby_created.connect(lobby_created)
	lobby_client.lobby_joined.connect(lobby_joined)
	lobby_client.lobby_left.connect(lobby_left)
	lobby_client.lobby_sealed.connect(lobby_sealed)
	lobby_client.peer_joined.connect(peer_joined)
	lobby_client.peer_left.connect(peer_left)
	lobby_client.peer_ready.connect(peer_ready)
	lobby_client.peer_messaged.connect(peer_messaged)
	lobby_client.log_updated.connect(log_updated)
	lobby_client.lobby_tagged.connect(lobby_tagged)

func write_result(text):
	result_text.text += text + "\n"

func log_updated(command: String, logs: String):
	logs_text.text = command + " " + logs

func connected_to_lobby(peer: LobbyPeer, reconnection_token: String):
	write_result("Callback: %s [b]connected_to_lobby[/b] peer_id [color=blue]%s[/color] user_name %s peer_ready %s reconnection_token [color=green]%s[/color]" % [get_index(), peer.id, peer.user_data.get("name", ""), peer.ready, reconnection_token])

func disconnected_from_lobby(reason: String):
	write_result("Callback: %s [b]disconnected_from_lobby[/b] reason %s reconnect_token [color=green]%s[/color]" % [get_index(), reason, lobby_client.reconnection_token])

func received_peer_data(data: Dictionary, to_peer: LobbyPeer, is_private: bool):
	write_result("Callback: %s [b]received_peer_data[/b] data %s to_peer [color=blue]%s[/color] is_private %s" % [get_index(), data, to_peer.id, is_private])
	if is_private:
		write_result("Private data %s" % lobby_client.peer_data)

func received_lobby_data(data: Dictionary):
	write_result("Callback: %s [b]received_lobby_data[/b] data %s" % [get_index(), data])

func lobby_notified(data: String):
	write_result("Callback: %s [b]lobby_notified[/b] data %s" % [get_index(), data])

func lobby_created(lobby: LobbyInfo, peers: Array[LobbyPeer]):
	write_result("Callback: %s [b]lobby_created[/b] lobby_name %s tags %s max_players %s has_password %s" % [get_index(), lobby.lobby_name, lobby.tags, lobby.max_players, str(lobby.password_protected)])
	for peer in peers:
		write_result("Callback: %s [b]lobby_created[/b] peer: peer_id [color=blue]%s[/color] user_name %s peer_ready %s" % [get_index(), peer.id, peer.user_data.get("name", ""), peer.ready])

func lobby_joined(lobby: LobbyInfo, peers: Array[LobbyPeer]):
	write_result("Callback: %s [b]lobby_joined[/b] lobby_name %s" % [get_index(), lobby.lobby_name])
	for peer in peers:
		write_result("Callback: %s [b]lobby_joined[/b] peer: peer_id [color=blue]%s[/color] user_name %s peer_ready %s" % [get_index(), peer.id, peer.user_data.get("name", ""), peer.ready])

func lobby_left(kicked: bool):
	write_result("Callback: %s [b]lobby_left[/b] kicked %s" % [get_index(), kicked])

func peer_joined(peer: LobbyPeer):
	write_result("Callback: %s [b]peer_joined[/b] peer_id [color=blue]%s[/color] user_name %s" % [get_index(), peer.id, peer.user_data.get("name", "")])

func peer_left(peer: LobbyPeer, kicked: bool):
	write_result("Callback: %s [b]peer_left[/b] per_id %s kicked %s" % [get_index(), peer.id, kicked])
	
func peer_ready(peer: LobbyPeer, is_ready: bool):
	write_result("Callback: %s [b]peer_ready[/b] peer_id [color=blue]%s[/color] ready %s" % [get_index(), peer.id, str(is_ready)])

func received_peer_user_data(peer: LobbyPeer, data: Dictionary):
	write_result("Callback: %s [b]received_peer_user_data[/b] peer_id [color=blue]%s[/color] user_data %s" % [get_index(), peer.id, data])

func peer_messaged(peer: LobbyPeer, message: String):
	write_result("Callback: %s [b]peer_messaged[/b] peer_id [color=blue]%s[/color] message %s" % [get_index(), peer.id, message])

func lobby_sealed(sealed: bool):
	write_result("Callback: %s [b]lobby_sealed[/b] sealed %s" % [get_index(), str(sealed)])

func lobby_tagged(tags: Dictionary):
	write_result("Callback: %s [b]lobby_tagged[/b] tags %s" % [get_index(), tags])

func _on_command_toggle_item_selected(index: int) -> void:
	var item = command_toggle.get_item_text(index)
	message_text.placeholder_text = ""
	message_text2.placeholder_text = ""
	message_text3.placeholder_text = ""
	message_text4.placeholder_text = ""
	match item:
		"connect_to_lobby":
			message_text.placeholder_text = "Reconnection Token:"
			message_text2.placeholder_text = "Game ID Override:"
			message_text3.placeholder_text = "Server URL Override:"
		"disconnect_from_lobby":
			pass
		"create_lobby":
			message_text.placeholder_text = "Title:"
			message_text2.placeholder_text = "Password:"
			message_text3.placeholder_text = "Max Players:"
			message_text4.placeholder_text = "Tags (dict):"
		"join_lobby":
			message_text.placeholder_text = "Lobby ID:"
			message_text2.placeholder_text = "Password:"
		"list_lobbies":
			message_text.placeholder_text = "Tags (dict):"
			message_text2.placeholder_text = "Start:"
			message_text3.placeholder_text = "Count:"
		"leave_lobby":
			pass
		"kick_peer":
			message_text.placeholder_text = "Peer ID:"
		"set_lobby_ready(true)":
			pass
		"set_lobby_ready(false)":
			pass
		"set_lobby_sealed(true)":
			pass
		"set_lobby_sealed(false)":
			pass
		"send_chat_message":
			message_text.placeholder_text = "Chat Message:"
		"add_peer_user_data":
			message_text.placeholder_text = "User Data (dict):"
		"del_peer_user_data":
			message_text.placeholder_text = "Keys (array):"
		"add_lobby_tags":
			message_text.placeholder_text = "Data (dict):"
		"del_lobby_tag":
			message_text.placeholder_text = "Keys (array):"

func parse_json_or_empty(str_json: String):
	var dict = {}
	if str_json != "":
		dict = JSON.parse_string(str_json)
	if dict == null:
		dict = {}
	return dict

func parse_bool(str_bool: String) -> bool:
	if str_bool == "true" || str_bool == "1":
		return true
	return false

func _on_button_pressed() -> void:
	var item = command_toggle.get_item_text(command_toggle.selected)
	var message = message_text.text
	var message2 = message_text2.text
	var message3 = message_text3.text
	var message4 = message_text4.text
	match item:
		"connect_to_lobby":
			lobby_client.reconnection_token = message
			if message2 != "":
				lobby_client.game_id = message2
			else:
				lobby_client.game_id = "echo"
			if message3 != "":
				lobby_client.server_url = message3
			else:
				#lobby_client.server_url = "wss://authlobby.blazium.app/connect"
				lobby_client.server_url = "ws://localhost:8080/connect"
			if !lobby_client.connect_to_lobby():
				write_result("Connect Error")
			else:
				write_result("Connecting")
		"disconnect_from_lobby":
			lobby_client.disconnect_from_lobby()
		"create_lobby":
			var result : ViewLobbyResult = await lobby_client.create_lobby(message, parse_json_or_empty(message4), int(message3), message2).finished
			if result.has_error():
				write_result("Create Error %s: %s" % [get_index(), result.error])
			else:
				write_result("Create Result %s: lobby_id [color=red]%s[/color] max_players %s sealed %s public_data %s" % [get_index(), result.lobby.id, result.lobby.max_players, result.lobby.sealed, result.lobby.data])
				for peer in result.peers:
					write_result("Create Peer %s: peer_id [color=blue]%s[/color] user_name %s ready  %s" % [get_index(), peer.id, peer.user_data.get("name", ""), peer.ready])
		"join_lobby":
			var result : ViewLobbyResult = await lobby_client.join_lobby(message, message2).finished
			if result.has_error():
				write_result("Join Error %s: %s" % [get_index(), result.error])
			else:
				write_result("Join Result %s: host [color=blue]%s[/color] max_players %s sealed %s data %s peer_data %s private_peer_data %s" % [get_index(), result.lobby.host, result.lobby.max_players, result.lobby.sealed, result.lobby.data, lobby_client.peer.data, lobby_client.peer_data])
				for peer in result.peers:
					write_result("Join Peer %s: peer_id [color=blue]%s[/color] user_name %s ready %s" % [get_index(), peer.id, peer.user_data.get("name", ""), peer.ready])
		"leave_lobby":
			var result :LobbyResult = await lobby_client.leave_lobby().finished
			if result.has_error():
				write_result("Leave Error %s: %s" % [get_index(), result.error])
			else:
				write_result("Leave Result %s: Success" % get_index())
		"list_lobbies":
			var result :ListLobbyResult = await lobby_client.list_lobbies(parse_json_or_empty(message), int(message2), int(message3)).finished
			if result.has_error():
				write_result("List Error %s: %s" % [get_index(), result.error])
			else:
				for lobby in result.lobbies:
					write_result("List Result %s: host [color=blue]%s[/color] lobby_id [color=red]%s[/color] max_players %s playeres %s sealed %s lobby_name %s" % [get_index(), lobby.host, lobby.id, lobby.max_players, lobby.players, lobby.sealed, lobby.lobby_name])
		"kick_peer":
			var result :LobbyResult = await lobby_client.kick_peer(message).finished
			if result.has_error():
				write_result("Kick Error %s: %s" % [get_index(), result.error])
			else:
				write_result("Kick Result %s: Success" % get_index())
		"set_lobby_ready(true)":
			var result :LobbyResult = await lobby_client.set_lobby_ready(true).finished
			if result.has_error():
				write_result("Ready Error %s: %s" % [get_index(), result.error])
			else:
				write_result("Ready Result %s: Success" % get_index())
		"set_lobby_ready(false)":
			var result :LobbyResult = await lobby_client.set_lobby_ready(false).finished
			if result.has_error():
				write_result("Unready Error %s: %s" % [get_index(), result.error])
			else:
				write_result("Unready Result %s: Success" % get_index())
		"set_lobby_sealed(true)":
			var result :LobbyResult = await lobby_client.set_lobby_sealed(true).finished
			if result.has_error():
				write_result("Sealed Error %s: %s" % [get_index(), result.error])
			else:
				write_result("Sealed Result %s: Success" % get_index())
		"set_lobby_sealed(false)":
			var result :LobbyResult = await lobby_client.set_lobby_sealed(false).finished
			if result.has_error():
				write_result("Unsealed Error %s: %s" % [get_index(), result.error])
			else:
				write_result("Unsealed Result %s: Success" % get_index())
		"send_chat_message":
			var result :LobbyResult = await lobby_client.send_chat_message(message).finished
			if result.has_error():
				write_result("Chat Error %s: %s" % [get_index(), result.error])
			else:
				write_result("Chat Result %s: Success" % get_index())
		"add_peer_user_data":
			var result :LobbyResult = await lobby_client.add_peer_user_data(parse_json_or_empty(message)).finished
			if result.has_error():
				write_result("Add Peer User Data Error %s: %s" % [get_index(), result.error])
			else:
				write_result("Add Peer User Data %s: Success" % get_index())
		"del_peer_user_data":
			var result :LobbyResult = await lobby_client.del_peer_user_data(parse_json_or_empty(message)).finished
			if result.has_error():
				write_result("Delete Peer User Data Error %s: %s" % [get_index(), result.error])
			else:
				write_result("Delete Peer User Data %s: Success" % get_index())
		"add_lobby_tags":
			var result :LobbyResult = await lobby_client.add_lobby_tags(parse_json_or_empty(message)).finished
			if result.has_error():
				write_result("Tags Error %s: %s" % [get_index(), result.error])
			else:
				write_result("Tags Result %s: Success" % get_index())
		"del_lobby_tag":
			var result :LobbyResult = await lobby_client.del_lobby_tags(parse_json_or_empty(message)).finished
			if result.has_error():
				write_result("Tags Error %s: %s" % [get_index(), result.error])
			else:
				write_result("Tags Result %s: Success" % get_index())
