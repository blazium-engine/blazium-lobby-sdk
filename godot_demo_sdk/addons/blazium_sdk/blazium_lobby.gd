@icon("res://addons/blazium_sdk/blazium_icon.svg")
class_name BlaziumLobby
extends Node

## A node used to connect to a lobby server. It can be used to do matchmaking. You care do operations such as create lobbys, join lobbys, etc.

var _socket := WebSocketPeer.new()

enum _CommandType{CREATE_LOBBY, SIMPLE_REQUEST, LOBBY_VIEW, LOBBY_LIST}

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

class LobbyResponse:
	class Response:
		var _error: String
		var _lobby_name: String
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

class ViewLobby:
	class Response:
		var _error: String
		var _peers: Array[LobbyPeer]
		var _lobby_info: LobbyInfo
		func has_error() -> bool:
			return _error != ""
		func get_error() -> String:
			return _error
		func get_peers() -> Array[LobbyPeer]:
			return _peers
		func get_lobby_info() -> LobbyInfo:
			return _lobby_info
	signal finished(response: Response)

class LobbyData:
	class Response:
		var _error: String
		func has_error() -> bool:
			return _error != ""
		func get_error() -> String:
			return _error
	signal finished(response: Response)

class LobbyInfo:
	var host: String
	var max_players: int
	var sealed: bool

class LobbyPeer:
	var id: String
	var name: String
	var ready: bool

var _commands := {}

signal peer_named(peer: String, name: String)
signal received_data(data: String)
signal received_data_to(data: String)
## Signal generated after the lobby is created by you.
signal lobby_created(lobby: String)
## Signal generated after the lobby is joined by you.
signal lobby_joined(lobby: String)
## Signal generated after the lobby is left by you.
signal lobby_left()
## Signal generated after the host seals the lobby.
signal lobby_sealed()
## Signal generated after the host unseals the lobby.
signal lobby_unsealed()
## Signal generated after a peer joins the lobby.
signal peer_joined(peer_id: String, peer_name)
## Signal generated after a peer leaves the lobby.
signal peer_left(peer_id: String, kicked: bool)
## Signal generated after a peer is ready.
signal peer_ready(peer_id: String)
## Signal generated after a peer is unready.
signal peer_unready(peer_id: String)

## Signals a log from a command.
signal append_log(command: String, logs: String)  # Emitted to log normal activity.

func _ready():
	set_process(false)

## Connect to a Blazium Lobby Server using a [game_id] and [lobby_url]. The default [lobby_url] is wss://lobby.blazium.app and it connects to the free Blazium Lobby server.
func connect_to_lobby(gameID: String, lobby_url: String = "wss://lobby.blazium.app/connect") -> bool:
	var err = _socket.connect_to_url(lobby_url + "?gameID=" + gameID)
	if err != OK:
		append_log.emit("error", "Unable to connect to lobby server at url: " + lobby_url)
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
func create_lobby(max_players: int = 0, password: String = "") -> CreateLobby:
	return _send_data_with_id({"command": "create_lobby", "data": {"max_players": max_players, "password": password}}, CreateLobby.new(), _CommandType.CREATE_LOBBY)

## Join a lobby. If you are already in a lobby, you cannot join another one. You need to leave first.
func join_lobby(lobby: String, password: String = "") -> LobbyResponse:
	return _send_data_with_id({"command": "join_lobby", "data": {"lobby_name": lobby, "password": password}}, LobbyResponse.new(), _CommandType.SIMPLE_REQUEST)

## Kick a peer. You need to be host to do this operation.
## Will generate either error signal or peer_left.
func kick_peer(peer_id: String) -> LobbyResponse:
	return _send_data_with_id({"command": "kick_peer", "data": {"peer_id": peer_id}}, LobbyResponse.new(), _CommandType.SIMPLE_REQUEST)


## Leave a lobby. You need to be in a lobby to leave one.
## Will generate either error signal or lobby_left.
func leave_lobby() -> LobbyResponse:
	return _send_data_with_id({"command": "leave_lobby"}, LobbyResponse.new(), _CommandType.SIMPLE_REQUEST)


## Lists all lobbies.
## Will generate either error signal or lobby_list.
func list_lobby(start: int = 0, count: int = 10) -> ListLobby:
	return _send_data_with_id({"command": "list_lobby", "data": { "start": start, "count": count }}, ListLobby.new(), _CommandType.LOBBY_LIST)

## Ready up in the lobby. You need to be in a lobby and unready to run this.
## Will generate either error signal or peer_ready.
func lobby_ready() -> LobbyResponse:
	return _send_data_with_id({"command": "lobby_ready"}, LobbyResponse.new(), _CommandType.SIMPLE_REQUEST)

## Ready up in the lobby. You need to be in a lobby and ready to run this.
## Will generate either error signal or peer_unready.
func lobby_unready() -> LobbyResponse:
	return _send_data_with_id({"command": "lobby_unready"}, LobbyResponse.new(), _CommandType.SIMPLE_REQUEST)

## Seals the lobby. You need to be the host to do this and the lobby needs to be unsealed.
## Will generate either error signal or lobby_sealed.
func seal_lobby() -> LobbyResponse:
	return _send_data_with_id({"command": "seal_lobby"}, LobbyResponse.new(), _CommandType.SIMPLE_REQUEST)

## Unseals the lobby. You need to be the host to do this and the lobby needs to be sealed.
## Will generate either error signal or lobby_unsealed.
func unseal_lobby() -> LobbyResponse:
	return _send_data_with_id({"command": "unseal_lobby"}, LobbyResponse.new(), _CommandType.SIMPLE_REQUEST)

## View data from a lobby. Returns lobby settings and peers.
## Will generate either error signal or lobby_view.
func view_lobby(lobby: String, password: String) -> ViewLobby:
	return _send_data_with_id({"command": "view_lobby", "data": { "lobby_name": lobby, "password": password }}, ViewLobby.new(), _CommandType.LOBBY_VIEW)

func lobby_data(peer_data: String) -> LobbyResponse:
	return _send_data_with_id({"command": "lobby_data", "data": { "peer_data": peer_data }}, LobbyResponse.new(), _CommandType.SIMPLE_REQUEST)

func lobby_data_to(peer_data: String, target_peer) -> LobbyResponse:
	return _send_data_with_id({"command": "data_to", "data": { "peer_data": peer_data , "target_peer": target_peer}}, LobbyResponse.new(), _CommandType.SIMPLE_REQUEST)

func set_peer_name(peer_name: String) -> LobbyResponse:
	return _send_data_with_id({"command": "set_name", "data": { "name": peer_name}}, LobbyResponse.new(), _CommandType.SIMPLE_REQUEST)

func _receive_data(data: Dictionary):
	var message: String = data["message"]
	var command: String = data["command"]
	append_log.emit(command, message)
	var message_id := ""
	if data.has("data") && data["data"] != null && data["data"].has("id"):
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
			lobby_created.emit(command_response._lobby_name)
		"joined_lobby":
			var command_response := LobbyResponse.Response.new()
			command_response._lobby_name = data["data"]["lobby_name"]
			command_object.finished.emit(command_response)
			_commands.erase(message_id)
			lobby_joined.emit(command_response._lobby_name)
		"lobby_left":
			# Either if you leave a lobby, or if you get kicked
			if command_object != null:
				var command_response := LobbyResponse.Response.new()
				command_object.finished.emit(command_response)
				_commands.erase(message_id)
			lobby_left.emit()
		"lobby_sealed":
			# Either if you seal a lobby, or if host seals
			if command_object != null:
				var command_response := LobbyResponse.Response.new()
				command_object.finished.emit(command_response)
				_commands.erase(message_id)
			lobby_sealed.emit()
		"lobby_unsealed":
			# Either if you unseal a lobby, or if host unseals
			if command_object != null:
				var command_response := LobbyResponse.Response.new()
				command_object.finished.emit(command_response)
				_commands.erase(message_id)
			lobby_unsealed.emit()
		"peer_ready":
			# Either if you ready, or if some else is ready
			if command_object != null:
				var command_response := LobbyResponse.Response.new()
				command_object.finished.emit(command_response)
				_commands.erase(message_id)
			peer_ready.emit(data["data"]["peer_id"])
		"peer_name":
			# Either if you named, or someone else named
			if command_object != null:
				var command_response := LobbyResponse.Response.new()
				command_object.finished.emit(command_response)
				_commands.erase(message_id)
			peer_named.emit(data["data"]["peer_id"], data["data"]["name"])
		"peer_unready":
			# Either if you seal are unready, or if some else is unready
			if command_object != null:
				var command_response := LobbyResponse.Response.new()
				command_object.finished.emit(command_response)
				_commands.erase(message_id)
			peer_unready.emit(data["data"]["peer_id"])
		"lobby_view":
			var ids: Array[String] = []
			var names: Array[String] = []
			var readys: Array[bool] = []
			var peers : Array[LobbyPeer]
			if data["data"].has("peers"):
				for peer_json in data["data"]["peers"]:
					var lobby_peer := LobbyPeer.new()
					lobby_peer.id = peer_json["id"]
					lobby_peer.name = peer_json["name"]
					lobby_peer.ready = peer_json["ready"]
					peers.append(lobby_peer)
			var command_response := ViewLobby.Response.new()
			command_response._peers = peers
			command_response._lobby_info = LobbyInfo.new()
			command_response._lobby_info.host = data["data"]["lobby"]["host"]
			command_response._lobby_info.sealed = data["data"]["lobby"]["sealed"]
			command_response._lobby_info.max_players = data["data"]["lobby"]["max_players"]
			command_object.finished.emit(command_response)
			_commands.erase(message_id)
		"lobby_list":
			var arr: Array[String] = []
			arr.assign(data["data"]["lobbies"])
			var command_response := ListLobby.Response.new()
			command_response._lobbies = arr
			command_object.finished.emit(command_response)
			_commands.erase(message_id)
		"lobby_data":
			if command_object != null:
				var command_response := LobbyResponse.Response.new()
				command_object.finished.emit(command_response)
				_commands.erase(message_id)
			received_data.emit(data["data"]["peer_data"])
		"lobby_data_sent":
			if command_object != null:
				var command_response := LobbyResponse.Response.new()
				command_object.finished.emit(command_response)
				_commands.erase(message_id)
		"data_to_sent":
			if command_object != null:
				var command_response := LobbyResponse.Response.new()
				command_object.finished.emit(command_response)
				_commands.erase(message_id)
		"data_to":
			if command_object != null:
				var command_response := LobbyResponse.Response.new()
				command_object.finished.emit(command_response)
				_commands.erase(message_id)
			received_data_to.emit(data["data"]["peer_data"])
		"peer_joined":
			peer_joined.emit(data["data"]["peer_id"], data["data"]["peer_name"])
		"peer_left":
			# Either if you kick a peer, or a peer leaves
			if command_object != null:
				var command_response := LobbyResponse.Response.new()
				command_object.finished.emit(command_response)
				_commands.erase(message_id)
			peer_left.emit(data["data"]["peer_id"], data["data"]["kicked"])
		"error":
			match command_type:
				_CommandType.CREATE_LOBBY:
					var command_response := CreateLobby.Response.new()
					command_response._error = message
					command_object.finished.emit(command_response)
					_commands.erase(message_id)
				_CommandType.SIMPLE_REQUEST:
					var command_response := LobbyResponse.Response.new()
					command_response._error = message
					command_object.finished.emit(command_response)
					_commands.erase(message_id)
				_CommandType.LOBBY_LIST:
					var command_response := ListLobby.Response.new()
					command_response._error = message
					command_object.finished.emit(command_response)
					_commands.erase(message_id)
				_CommandType.LOBBY_VIEW:
					var command_response := ViewLobby.Response.new()
					command_response._error = message
					command_object.finished.emit(command_response)
					_commands.erase(message_id)
				_: # Regular error case
					append_log.emit("error", message)
		_:
			append_log.emit("error", "Unmatched %s %s" % [command, message])

func _wait_ready():
	var wait_start := Time.get_ticks_msec()
	while _socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		await get_tree().create_timer(0.01).timeout
		if Time.get_ticks_msec() - wait_start > 5000:
			append_log.emit("error", "Socket not ready for 5 seconds.")
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
		append_log.emit("error", "WebSocket closed with code: %d. Clean: %s Reason: %s" % [code, code != -1, reason])
		set_process(false)
