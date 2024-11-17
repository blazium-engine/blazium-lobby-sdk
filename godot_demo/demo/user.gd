extends HBoxContainer

@onready var lobby := $BlaziumLobby
@onready var message_text := $Message
@onready var command_toggle := $CommandToggle
@onready var logs_text := $Logs

func _ready() -> void:
	lobby._create("demo_game", "ws://localhost:8080/connect")

	lobby.lobby_created.connect(lobby_created)
	lobby.lobby_joined.connect(lobby_joined)
	lobby.lobby_sealed.connect(lobby_sealed)
	lobby.lobby_unsealed.connect(lobby_unsealed)
	lobby.lobby_left.connect(lobby_left)
	lobby.lobby_list.connect(lobby_list)
	lobby.lobby_view.connect(lobby_view)
	lobby.peer_joined.connect(peer_joined)
	lobby.peer_left.connect(peer_left)
	lobby.peer_ready.connect(peer_ready)
	lobby.peer_unready.connect(peer_unready)
	lobby.append_error.connect(append_error)
	lobby.append_log.connect(append_log)

func append_log(command: String, logs: String):
	logs_text.text = command + " " + logs

func append_error(logs: String):
	logs_text.text = logs
	push_error(logs)

func lobby_list(lobbies: Array[String]):
	print("Callback: %s lobby_list %s." % [get_index(), lobbies])

func lobby_created(lobby_name: String):
	print("Callback: %s lobby_created %s." % [get_index(), lobby_name])

func lobby_joined(lobby_name: String):
	print("Callback: %s lobby_joined %s" % [get_index(), lobby_name])

func peer_joined(lobby_peer: String):
	print("Callback: %s peer_joined %s" % [get_index(), lobby_peer])

func peer_left(lobby_peer: String):
	print("Callback: %s peer_left %s" % [get_index(), lobby_peer])
	
func lobby_view(host: String, sealed: bool, lobby_peers: Array[BlaziumLobby.Peer]):
	var print_result = "Callback: %s lobby_view: host %s sealed %s peers: " % [get_index(), host, sealed]
	for peer in lobby_peers:
		print_result += "( id: %s name: %s ready: %s )" % [peer.id, peer.name, peer.ready]
	print(print_result)

func peer_ready(lobby_peer: String):
	print("Callback: %s peer_ready %s" % [get_index(), lobby_peer])

func peer_unready(lobby_peer: String):
	print("Callback: %s peer_unready %s" % [get_index(), lobby_peer])

func lobby_left():
	print("Callback: %s lobby_left" % [get_index()])

func lobby_sealed():
	print("Callback: %s lobby_sealed" % [get_index()])

func lobby_unsealed():
	print("Callback: %s lobby_unsealed" % [get_index()])

func _on_button_pressed() -> void:
	var item = command_toggle.get_item_text(command_toggle.selected)
	var message = message_text.text
	match item:
		"create_lobby":
			lobby.create_lobby()
		"join_lobby":
			lobby.join_lobby(message)
		"leave_lobby":
			lobby.leave_lobby()
		"list_lobby":
			lobby.list_lobby()
		"view_lobby":
			lobby.view_lobby(message)
		"kick_peer":
			lobby.kick_peer(message)
		"lobby_ready":
			lobby.lobby_ready()
		"lobby_unready":
			lobby.lobby_unready()
		"seal_lobby":
			lobby.seal_lobby()
		"unseal_lobby":
			lobby.unseal_lobby()
