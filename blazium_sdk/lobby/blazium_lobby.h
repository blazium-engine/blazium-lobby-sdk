#ifndef BLAZIUM_SDK_LOBBY_BLAZIUM_LOBBY_H
#define BLAZIUM_SDK_LOBBY_BLAZIUM_LOBBY_H

#include "scene/main/node.h"
#include "core/io/json.h"
#include "modules/websocket/websocket_peer.h"

class BlaziumLobby : public Node {
    GDCLASS(BlaziumLobby, Node);

private:
    Ref<WebSocketPeer> _socket;
    bool initialized;

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

    BlaziumLobby();
    ~BlaziumLobby();
};

#endif // BLAZIUM_SDK_LOBBY_BLAZIUM_LOBBY_H
