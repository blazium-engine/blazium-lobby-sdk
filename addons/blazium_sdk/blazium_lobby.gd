@icon("res://addons/blazium_sdk/blazium_icon.svg")
class_name BlaziumLobby
extends Node

# A node-based SDK to manage multiplayer lobbies using WebSocket for communication.
# Features include creating, joining, listing, and managing lobbies and peers.

# WebSocket peer for handling network communication.
var _socket := WebSocketPeer.new()
var initialized := false  # Tracks whether the WebSocket connection is initialized.

# Signals
signal lobby_created(lobby: String)
signal lobby_joined(lobby: String)
signal lobby_left()
signal lobby_sealed()
signal lobby_unsealed()
signal peer_joined(peer: String)
signal peer_left(peer: String)
signal peer_ready(peer: String)
signal peer_unready(peer: String)
signal lobby_view(host: String, sealed: bool, peer_ids: Array[String], peer_names: Array[String], peer_ready: Array[bool])
signal lobby_list(lobbies: Array[String])

signal append_log(command: String, logs: String)  # Emitted to log normal activity.
signal append_error(logs: String)  # Emitted to log errors or unexpected behavior.

# Initializes the WebSocket connection.
# @param gameID The unique identifier for the game.
# @param lobby_url The URL of the lobby server. Default is "wss://lobby.blazium.app/connect".
# @param peer_name The display name of the peer. Default is "Blaze".
func connect_to_lobby(gameID: String, lobby_url: String = "wss://lobby.blazium.app/connect") -> void:
	var err = _socket.connect_to_url(lobby_url + "?gameID=" + gameID)
	initialized = true
	if err != OK:
		append_error.emit("Unable to connect to lobby server at url: " + lobby_url)
		set_process(false)
		return
	append_log.emit("Connected to lobby server at " + _socket.get_requested_url())

# Sends a request to create a new lobby.
func create_lobby():
	_send_data({"command": "create_lobby"})

# Sends a request to join an existing lobby.
# @param lobby_name The name of the lobby to join.
func join_lobby(lobby_name: String):
	_send_data({"command": "join_lobby", "data": lobby_name})

# Sends a request to leave the current lobby.
func leave_lobby():
	_send_data({"command": "leave_lobby"})

# Sends a request to list all available lobbies.
func list_lobby():
	_send_data({"command": "list_lobby"})

# Sends a request to view details of a specific lobby.
# @param lobby_name The name of the lobby to view.
func view_lobby(lobby_name: String):
	_send_data({"command": "view_lobby", "data": lobby_name})


func kick_peer(peer_id: String):
	_send_data({"command": "kick_peer", "data": peer_id})

func lobby_ready():
	_send_data({"command": "lobby_ready"})

func lobby_unready():
	_send_data({"command": "lobby_unready"})

func seal_lobby():
	_send_data({"command": "seal_lobby"})

func unseal_lobby():
	_send_data({"command": "unseal_lobby"})

# Processes received WebSocket data.
# @param data The data received from the WebSocket.
func _receive_data(data: Dictionary):
	var message: String = data["message"]
	var command: String = data["command"]
	append_log.emit(command, message)

	match command:
		"lobby_created":
			lobby_created.emit(data["data"])
		"joined_lobby":
			lobby_joined.emit(data["data"])
		"lobby_left":
			lobby_left.emit()
		"lobby_sealed":
			lobby_sealed.emit()
		"lobby_unsealed":
			lobby_unsealed.emit()
		"peer_ready":
			peer_ready.emit(data["data"])
		"peer_unready":
			peer_unready.emit(data["data"])
		"lobby_view":
			var ids: Array[String] = []
			var names: Array[String] = []
			var readys: Array[bool] = []
			for peer_json in data["data"]["peers"]:
				ids.push_back(peer_json["peer_id"])
				names.push_back(peer_json["peer_name"])
				readys.push_back(peer_json["peer_ready"])
			lobby_view.emit(data["data"]["lobby"]["host"], data["data"]["lobby"]["sealed"], ids, names, readys)
		"lobby_list":
			var arr: Array[String] = []
			arr.assign(data["data"])
			lobby_list.emit(arr)
		"peer_joined":
			peer_joined.emit(data["data"])
		"peer_left":
			peer_left.emit(data["data"])
		"error":
			append_error.emit(message)
		_:
			append_error.emit("Unmatched Command %s Message %s " % [command, message])

# Waits for the WebSocket to be ready before sending data.
func _wait_ready():
	var wait_start := Time.get_ticks_msec()
	while _socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		await get_tree().create_timer(0.01).timeout
		if Time.get_ticks_msec() - wait_start > 5000:
			append_error.emit("Socket not ready for 5 seconds.")
			set_process(false)
			break

# Sends data to the WebSocket server.
# @param data The data to send as a dictionary.
func _send_data(data: Dictionary):
	await _wait_ready()
	_socket.send_text(JSON.stringify(data))

# Polls the WebSocket for new messages and processes them.
# Called every frame.
func _process(_delta):
	if !initialized:
		return

	_socket.poll()

	var state = _socket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		while _socket.get_available_packet_count():
			var data := _socket.get_packet().get_string_from_utf8()
			_receive_data(JSON.parse_string(data))
	elif state == WebSocketPeer.STATE_CLOSING:
		pass
	elif state == WebSocketPeer.STATE_CLOSED:
		var code = _socket.get_close_code()
		var reason = _socket.get_close_reason()
		append_error.emit("WebSocket closed with code: %d. Clean: %s Reason: %s" % [code, code != -1, reason])
		set_process(false)
