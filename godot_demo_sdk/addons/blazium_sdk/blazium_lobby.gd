@icon("res://addons/blazium_sdk/blazium_icon.svg")
class_name BlaziumLobby
extends Node

## A node used to connect to a lobby server. It can be used to do matchmaking. You care do operations such as create lobbys, join lobbys, etc.

var _socket := WebSocketPeer.new()
var initialized := false

class LobbyResponse:
	var result: Dictionary
	signal finished()

class LobbyPeer:
	var id: String
	var name: String
	var ready: bool

var _commands := {}

## Signal generated after a lobby is created.
signal lobby_created(lobby: String)
## Signal generated after you joint a lobby.
signal lobby_joined(lobby: String)
## Signal generated after you leave a lobby.
signal lobby_left()
## Signal generated after you list lobbies.
signal lobby_list(lobbies: Array[String])
## Signal generated after the host seals the lobby.
signal lobby_sealed()
## Signal generated after the host unseals the lobby.
signal lobby_unsealed()
## Signal generated after you call view_lobby.
signal lobby_view(host: String, sealed: bool, peer_ids: Array[String], peer_names: Array[String], peer_ready: Array[bool])
## Signal generated after a peer joins the lobby.
signal peer_joined(peer: String)
## Signal generated after a peer leaves the lobby.
signal peer_left(peer: String)
## Signal generated after a peer is ready.
signal peer_ready(peer: String)
## Signal generated after a peer is unready.
signal peer_unready(peer: String)

## Signals a log from a command.
signal append_log(command: String, logs: String)  # Emitted to log normal activity.
## Signals an error.
signal append_error(logs: String)  # Emitted to log errors or unexpected behavior.

## Connect to a Blazium Lobby Server using a [game_id] and [lobby_url]. The default [lobby_url] is wss://lobby.blazium.app and it connects to the free Blazium Lobby server.
func connect_to_lobby(gameID: String, lobby_url: String = "wss://lobby.blazium.app/connect") -> void:
	var err = _socket.connect_to_url(lobby_url + "?gameID=" + gameID)
	initialized = true
	if err != OK:
		append_error.emit("Unable to connect to lobby server at url: " + lobby_url)
		set_process(false)
		return
	append_log.emit("connect_to_lobby", "Connected to lobby server at " + _socket.get_requested_url())

var counter := 0

func _increment_counter() -> int:
	counter += 1
	return counter

func _send_data_with_id(command: Dictionary) -> BlaziumLobby.LobbyResponse:
	var id = _increment_counter()
	if !command.has("data"):
		command["data"] = {}
	command["data"]["id"] = id
	_send_data(command)
	var response := BlaziumLobby.LobbyResponse.new()
	_commands[id] = response
	return response
	

## Create a lobby and become host. If you are already in a lobby, you cannot create one. You need to leave first.
## Will generate either error signal or lobby_created.
func create_lobby() -> BlaziumLobby.LobbyResponse:
	return _send_data_with_id({"command": "create_lobby"})

## Join a lobby. If you are already in a lobby, you cannot join another one. You need to leave first.
## Will generate either error signal or lobby_joined.
func join_lobby(lobby_name: String):
	_send_data({"command": "join_lobby", "data": lobby_name})

## Kick a peer. You need to be host to do this operation.
## Will generate either error signal or peer_left.
func kick_peer(peer_id: String):
	_send_data({"command": "kick_peer", "data": peer_id})


## Leave a lobby. You need to be in a lobby to leave one.
## Will generate either error signal or lobby_left.
func leave_lobby():
	_send_data({"command": "leave_lobby"})


## Lists all lobbies.
## Will generate either error signal or lobby_list.
func list_lobby():
	_send_data({"command": "list_lobby"})

## Ready up in the lobby. You need to be in a lobby and unready to run this.
## Will generate either error signal or peer_ready.
func lobby_ready():
	_send_data({"command": "lobby_ready"})

## Ready up in the lobby. You need to be in a lobby and ready to run this.
## Will generate either error signal or peer_unready.
func lobby_unready():
	_send_data({"command": "lobby_unready"})

## Seals the lobby. You need to be the host to do this and the lobby needs to be unsealed.
## Will generate either error signal or lobby_sealed.
func seal_lobby():
	_send_data({"command": "seal_lobby"})

## Unseals the lobby. You need to be the host to do this and the lobby needs to be sealed.
## Will generate either error signal or lobby_unsealed.
func unseal_lobby():
	_send_data({"command": "unseal_lobby"})

## View data from a lobby. Returns lobby settings and peers.
## Will generate either error signal or lobby_view.
func view_lobby(lobby_name: String):
	_send_data({"command": "view_lobby", "data": lobby_name})

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

func _wait_ready():
	var wait_start := Time.get_ticks_msec()
	while _socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		await get_tree().create_timer(0.01).timeout
		if Time.get_ticks_msec() - wait_start > 5000:
			append_error.emit("Socket not ready for 5 seconds.")
			set_process(false)
			break

func _send_data(data: Dictionary):
	await _wait_ready()
	_socket.send_text(JSON.stringify(data))

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
