#ifndef BLAZIUM_SDK_LOBBY_BLAZIUM_LOBBY_H
#define BLAZIUM_SDK_LOBBY_BLAZIUM_LOBBY_H

#include "scene/main/node.h"
#include "core/io/json.h"
#include "modules/websocket/websocket_peer.h"

class LobbyClient : public Node {
    GDCLASS(LobbyClient, Node);
public:
    class CreateLobbyResponse {
        String error;
        String lobby_name;
    public:
        bool has_error() const { return !error.empty(); }
        String get_error() const { return error; }
        String get_lobby_name() const { return _lobby_name; }
    };

    class LobbyResponse {
        String error;
    public:
        bool has_error() const { return !error.empty(); }
        String get_error() const { return error; }
    };

    class ListLobbyResponse {
        String error;
        Array lobbies;
    public:

        bool has_error() const { return !error.empty(); }
        String get_error() const { return error; }
        Array get_lobbies() const { return lobbies; }
    };

    class ViewLobbyResponse {
        String error;
        Array peers;
        Dictionary lobby_info;
    public:

        bool has_error() const { return !error.empty(); }
        String get_error() const { return error; }
        Array get_peers() const { return peers; }
        Dictionary get_lobby_info() const { return lobby_info; }
    };

    class LobbyInfo {
    public:
        String host;
        int max_players = 0;
        bool sealed = false;
    };

    class LobbyPeer {
    public:
        String id;
        String name;
        bool ready = false;
    };
private:
    Ref<WebSocketPeer> _socket;
    int _counter = 0;
    Dictionary _commands;

    String _get_data_from_dict(const Dictionary &dict, const String &key);
    void _receive_data(const Dictionary &data);
    void _send_data(const Dictionary &data);
    void _wait_ready();

protected:

	void _notification(int p_notification);
	static void _bind_methods();

public:
    void connect_to_lobby(const String &game_id, const String &lobby_url);
    void create_lobby();
    void join_lobby(const String &lobby_name);
    void leave_lobby();
    void list_lobby();
    void view_lobby(const String &lobby_name);
    void kick_peer(const String &peer_id);
    void lobby_ready();
    void lobby_unready();
    void seal_lobby();
    void unseal_lobby();

    LobbyClient();
    ~LobbyClient();
};

#endif // BLAZIUM_SDK_LOBBY_BLAZIUM_LOBBY_H
