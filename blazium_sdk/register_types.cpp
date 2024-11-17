#include "register_types.h"
#include "./lobby/blazium_lobby.h"

void initialize_blazium_sdk_module(ModuleInitializationLevel p_level) {
    if (p_level == MODULE_INITIALIZATION_LEVEL_SCENE) {
		GDREGISTER_CLASS(BlaziumLobby);
	}
}

void uninitialize_blazium_sdk_module(ModuleInitializationLevel p_level) {
}
