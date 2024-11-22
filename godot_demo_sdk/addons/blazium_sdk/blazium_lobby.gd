@icon("res://addons/blazium_sdk/blazium_icon.svg")
class_name BlaziumLobby
extends Node

## A node used to connect to a lobby server. It can be used to do matchmaking. You care do operations such as create lobbys, join lobbys, etc.

var _socket := WebSocketPeer.new()
var initialized := false

enum _CommandType{CREATE_LOBBY, JOIN_LOBBY, KICK_PEER, LOBBY_VIEW, LOBBY_LIST, LEAVE_LOBBY}

class CreateLobby:
	class Response:
		var _error: String
		var _lobby_name: String
		func has_error() -> bool:
			return _error != ""
		func get_error() -> String:
			return _error
		func get_lobby_name() -> String:
			return _lobby_name
	signal finished(response: Response)

class JoinLobby:
	class Response:
		var _error: String
		var _lobby_name: String
		func has_error() -> bool:
			return _error != ""
		func get_error() -> String:
			return _error
		func get_lobby_name() -> String:
			return _lobby_name
	signal finished(response: Response)

class LeaveLobby:
	class Response:
		var _error: String
		func has_error() -> bool:
			return _error != ""
		func get_error() -> String:
			return _error
	signal finished(response: Response)

class ListLobby:
	class Response:
		var _error: String
		var _lobbies: Array[String]
		func has_error() -> bool:
			return _error != ""
		func get_error() -> String:
			return _error
		func get_lobbies() -> Array[String]:
			return _lobbies
	signal finished(response: Response)

class KickPeer:
	class Response:
		var _error: String
		var _lobby_name: String
		func has_error() -> bool:
			return _error != ""
		func get_error() -> String:
			return _error
		func get_lobby_name() -> String:
			return _lobby_name
	signal finished(response: Response)

class LobbyPeer:
	var id: String
	var name: String
	var ready: bool

var _commands := {}

## Signal generated after the host seals the lobby.
signal lobby_sealed()
## Signal generated after the host unseals the lobby.
signal lobby_unsealed()
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

func _ready():
	set_process(false)

## Connect to a Blazium Lobby Server using a [game_id] and [lobby_url]. The default [lobby_url] is wss://lobby.blazium.app and it connects to the free Blazium Lobby server.
func connect_to_lobby(gameID: String, lobby_url: String = "wss://lobby.blazium.app/connect") -> bool:
	var err = _socket.connect_to_url(lobby_url + "?gameID=" + gameID)
	if err != OK:
		append_log.emit("Unable to connect to lobby server at url: " + lobby_url)
		set_process(false)
		return false
	set_process(true)
	append_log.emit("connect_to_lobby", "Connected to lobby server at " + _socket.get_requested_url())
	return true

var _counter := 0

func _increment_counter() -> String:
	_counter += 1
	return str(_counter)

func _send_data_with_id(command: Dictionary, response, command_type: _CommandType):
	var id = _increment_counter()
	if !command.has("data"):
		command["data"] = {}
	command["data"]["id"] = id
	_commands[id] = [command_type, response]
	_send_data(command)
	return response
	

## Create a lobby and become host. If you are already in a lobby, you cannot create one. You need to leave first.
func create_lobby(max_players: int = 4, password: String = "") -> BlaziumLobby.CreateLobby:
	return _send_data_with_id({"command": "create_lobby", "data": {"max_players": max_players, "password": password}}, CreateLobby.new(), _CommandType.CREATE_LOBBY)

## Join a lobby. If you are already in a lobby, you cannot join another one. You need to leave first.
func join_lobby(lobby_name: String, password: String = "") -> BlaziumLobby.JoinLobby:
	return _send_data_with_id({"command": "join_lobby", "data": {"lobby": lobby_name, "password": password}}, JoinLobby.new(), _CommandType.JOIN_LOBBY)

## Kick a peer. You need to be host to do this operation.
## Will generate either error signal or peer_left.
func kick_peer(peer_id: String) -> BlaziumLobby.KickPeer:
	return _send_data_with_id({"command": "kick_peer", "data": {"peer": peer_id}}, KickPeer.new(), _CommandType.KICK_PEER)


## Leave a lobby. You need to be in a lobby to leave one.
## Will generate either error signal or lobby_left.
func leave_lobby():
	return _send_data_with_id({"command": "leave_lobby"}, LeaveLobby.new(), _CommandType.LEAVE_LOBBY)


## Lists all lobbies.
## Will generate either error signal or lobby_list.
func list_lobby(start: int = 0, count: int = 10):
	return _send_data_with_id({"command": "list_lobby", "data": { "start": start, "count": count }}, ListLobby.new(), _CommandType.LOBBY_LIST)

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
	var message_id := ""
	if data.has("data") && data["data"].has("id"):
		message_id = data["data"]["id"]
	var command_type
	var command_object
	if _commands.has(message_id):
		var command_array: Array = _commands[message_id]
		command_type = command_array[0]
		command_object = command_array[1]
		data.erase("id")
	match command:
		"lobby_created":
			var command_response := CreateLobby.Response.new()
			command_response._lobby_name = data["data"]["lobby_name"]
			command_object.finished.emit(command_response)
			_commands.erase(message_id)
		"joined_lobby":
			var command_response := JoinLobby.Response.new()
			command_response._lobby_name = data["data"]["lobby_name"]
			command_object.finished.emit(command_response)
			_commands.erase(message_id)
		"lobby_left":
			var command_response := LeaveLobby.Response.new()
			command_object.finished.emit(command_response)
			_commands.erase(message_id)
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
			#lobby_view.emit(data["data"]["lobby"]["host"], data["data"]["lobby"]["sealed"], ids, names, readys)
		"lobby_list":
			var arr: Array[String] = []
			arr.assign(data["data"]["lobbies"])
			var command_response := ListLobby.Response.new()
			command_response._lobbies = arr
			command_object.finished.emit(command_response)
			_commands.erase(message_id)
		"peer_joined":
			peer_joined.emit(data["data"]["peer"])
		"peer_left":
			peer_left.emit(data["data"]["peer"])
		"error":
			match command_type:
				_CommandType.CREATE_LOBBY:
					var command_response := CreateLobby.Response.new()
					command_response._error = message
					command_object.finished.emit(command_response)
					_commands.erase(message_id)
				_CommandType.JOIN_LOBBY:
					var command_response := JoinLobby.Response.new()
					command_response._error = message
					command_object.finished.emit(command_response)
					_commands.erase(message_id)
				_CommandType.LEAVE_LOBBY:
					var command_response := LeaveLobby.Response.new()
					command_response._error = message
					command_object.finished.emit(command_response)
					_commands.erase(message_id)
				_CommandType.LOBBY_LIST:
					var command_response := ListLobby.Response.new()
					command_response._error = message
					command_object.finished.emit(command_response)
					_commands.erase(message_id)
				_: # Regular error case
					append_log.emit(message)
		_:
			append_log.emit("Unmatched Command %s Message %s " % [command, message])

func _wait_ready():
	var wait_start := Time.get_ticks_msec()
	while _socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		await get_tree().create_timer(0.01).timeout
		if Time.get_ticks_msec() - wait_start > 5000:
			append_log.emit("Socket not ready for 5 seconds.")
			set_process(false)
			break

func _send_data(data: Dictionary):
	await _wait_ready()
	_socket.send_text(JSON.stringify(data))

func _process(_delta):
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
		append_log.emit("WebSocket closed with code: %d. Clean: %s Reason: %s" % [code, code != -1, reason])
		set_process(false)
