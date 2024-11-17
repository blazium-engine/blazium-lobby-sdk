#include "./blazium_lobby.h"
#include "scene/main/node.h"

BlaziumLobby::BlaziumLobby() {
    _socket = Ref<WebSocketPeer>(WebSocketPeer::create());
    initialized = false;
}

BlaziumLobby::~BlaziumLobby() {
    if (initialized) {
        _socket->close(1000, "Disconnected");
        set_process_internal(false);
    }
}

void BlaziumLobby::_bind_methods() {
    // Register methods
    ClassDB::bind_method(D_METHOD("connect_to_lobby", "game_id", "lobby_url"), &BlaziumLobby::connect_to_lobby);
    ClassDB::bind_method(D_METHOD("create_lobby"), &BlaziumLobby::create_lobby);
    ClassDB::bind_method(D_METHOD("join_lobby", "lobby_name"), &BlaziumLobby::join_lobby);
    ClassDB::bind_method(D_METHOD("leave_lobby"), &BlaziumLobby::leave_lobby);
    ClassDB::bind_method(D_METHOD("list_lobby"), &BlaziumLobby::list_lobby);
    ClassDB::bind_method(D_METHOD("view_lobby", "lobby_name"), &BlaziumLobby::view_lobby);
    ClassDB::bind_method(D_METHOD("kick_peer", "peer_id"), &BlaziumLobby::kick_peer);
    ClassDB::bind_method(D_METHOD("lobby_ready"), &BlaziumLobby::lobby_ready);
    ClassDB::bind_method(D_METHOD("lobby_unready"), &BlaziumLobby::lobby_unready);
    ClassDB::bind_method(D_METHOD("seal_lobby"), &BlaziumLobby::seal_lobby);
    ClassDB::bind_method(D_METHOD("unseal_lobby"), &BlaziumLobby::unseal_lobby);

    // Register signals
    ADD_SIGNAL(MethodInfo("lobby_created", PropertyInfo(Variant::STRING, "lobby")));
    ADD_SIGNAL(MethodInfo("lobby_joined", PropertyInfo(Variant::STRING, "lobby")));
    ADD_SIGNAL(MethodInfo("lobby_left"));
    ADD_SIGNAL(MethodInfo("lobby_sealed"));
    ADD_SIGNAL(MethodInfo("lobby_unsealed"));
    ADD_SIGNAL(MethodInfo("peer_joined", PropertyInfo(Variant::STRING, "peer")));
    ADD_SIGNAL(MethodInfo("peer_left", PropertyInfo(Variant::STRING, "peer")));
    ADD_SIGNAL(MethodInfo("peer_ready", PropertyInfo(Variant::STRING, "peer")));
    ADD_SIGNAL(MethodInfo("peer_unready", PropertyInfo(Variant::STRING, "peer")));
    ADD_SIGNAL(MethodInfo("lobby_view", PropertyInfo(Variant::STRING, "host"), PropertyInfo(Variant::BOOL, "sealed"), PropertyInfo(Variant::ARRAY, "peer_ids"), PropertyInfo(Variant::ARRAY, "peer_names"), PropertyInfo(Variant::ARRAY, "peer_readys")));
    ADD_SIGNAL(MethodInfo("lobby_list", PropertyInfo(Variant::ARRAY, "lobbies")));
    ADD_SIGNAL(MethodInfo("append_log", PropertyInfo(Variant::STRING, "command"), PropertyInfo(Variant::STRING, "logs")));
    ADD_SIGNAL(MethodInfo("append_error", PropertyInfo(Variant::STRING, "logs")));
}

void BlaziumLobby::connect_to_lobby(const String &game_id, const String &lobby_url) {
    String url = lobby_url + "?gameID=" + game_id;
    Error err = _socket->connect_to_url(url);
    if (err != OK) {
        emit_signal("append_error", "Unable to connect to lobby server at: " + url);
        return;
    }
    set_process_internal(true);
    initialized = true;
    emit_signal("append_log", "connect_to_lobby","Connected to: " + url);
}

Dictionary create_command_dict(const String &command) {
    Dictionary dict;
    dict["command"] = command;
    return dict;
}

Dictionary create_command_dict(const String &command, const String &data) {
    Dictionary dict;
    dict["command"] = command;
    dict["data"] = data;
    return dict;
}

void BlaziumLobby::create_lobby() {
    _send_data(create_command_dict("create_lobby"));
}

void BlaziumLobby::join_lobby(const String &lobby_name) {
    _send_data(create_command_dict("join_lobby", lobby_name));
}

void BlaziumLobby::leave_lobby() {
    _send_data(create_command_dict("leave_lobby"));
}

void BlaziumLobby::list_lobby() {
    _send_data(create_command_dict("list_lobby"));
}

void BlaziumLobby::view_lobby(const String &lobby_name) {
    _send_data(create_command_dict("view_lobby", lobby_name));
}

void BlaziumLobby::kick_peer(const String &peer_id) {
    _send_data(create_command_dict("kick_peer", peer_id));
}

void BlaziumLobby::lobby_ready() {
    _send_data(create_command_dict("lobby_ready"));
}

void BlaziumLobby::lobby_unready() {
    _send_data(create_command_dict("lobby_unready"));
}

void BlaziumLobby::seal_lobby() {
    _send_data(create_command_dict("seal_lobby"));
}

void BlaziumLobby::unseal_lobby() {
    _send_data(create_command_dict("unseal_lobby"));
}


void BlaziumLobby::_notification(int p_what) {
	switch (p_what) {
		case NOTIFICATION_INTERNAL_PROCESS: {
    if (!initialized) {
        return;
    }

    _socket->poll();

    WebSocketPeer::State state = _socket->get_ready_state();
    if (state == WebSocketPeer::STATE_OPEN) {
        while (_socket->get_available_packet_count() > 0) {
            Vector<uint8_t> packet_buffer;
            Error err = _socket->get_packet_buffer(packet_buffer);
            if (err != OK) {
                emit_signal("append_error", "Unable to get packet.");
                return;
            }
            String packet_string = String::utf8((const char *)packet_buffer.ptr(), packet_buffer.size());
            _receive_data(JSON::parse_string(packet_string));
        }
    } else if (state == WebSocketPeer::STATE_CLOSED) {
        emit_signal("append_error", "WebSocket closed unexpectedly.");
        initialized = false;
    }
		} break;
	}
}

void BlaziumLobby::_send_data(const Dictionary &data) {
    if (_socket->get_ready_state() != WebSocketPeer::STATE_OPEN) {
        emit_signal("append_error", "Socket is not ready.");
        return;
    }
    _socket->send_text(JSON::stringify(data));
}

void BlaziumLobby::_receive_data(const Dictionary &dict) {
    String command = "error";
    if (dict.has("command")) {
        command = dict["command"];
    }
    emit_signal("append_log", command, dict["message"]);
    if (command == "lobby_created") {
        emit_signal("lobby_created", dict["data"]);
    } else if (command == "joined_lobby") {
        emit_signal("lobby_joined", dict["data"]);
    } else if (command == "lobby_left") {
        emit_signal("lobby_left");
    } else if (command == "lobby_sealed") {
        emit_signal("lobby_sealed");
    } else if (command == "lobby_unsealed") {
        emit_signal("lobby_unsealed");
    } else if (command == "lobby_list") {
        emit_signal("lobby_list", dict["data"]);
    } else if (command == "lobby_view") {
        Dictionary data_dict = dict["data"];
        Dictionary lobby_dict = data_dict["lobby"];
        
        Array peer_ids;
        Array peer_names;
        Array peer_readys;

        // Iterate through peers and populate arrays
        Array peers = data_dict["peers"];
        for (int i = 0; i < peers.size(); ++i) {
            Dictionary peer_json = peers[i];
            peer_ids.push_back(peer_json["peer_id"]);
            peer_names.push_back(peer_json["peer_name"]);
            peer_readys.push_back(peer_json["peer_ready"]);
        }

        // Emit the signal
        emit_signal("lobby_view", lobby_dict["host"], lobby_dict["sealed"], peer_ids, peer_names, peer_readys);
    } else if (command == "peer_ready") {
        emit_signal("peer_ready", dict["data"]);
    } else if (command == "peer_unready") {
        emit_signal("peer_unready", dict["data"]);
    } else if (command == "peer_joined") {
        emit_signal("peer_joined", dict["data"]);
    } else if (command == "peer_left") {
        emit_signal("peer_left", dict["data"]);
    } else if (command == "error") {
        emit_signal("append_error", dict["message"]);
    } else{
        emit_signal("append_error", "Unknown command received.");
    }
}
