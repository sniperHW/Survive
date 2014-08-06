#include "config.h"
#include "lua_util.h"
#include "gameserver.h"

config* g_config = NULL;

int loadconfig(){
	g_config = calloc(1,sizeof(*g_config));
	lua_State *L = luaL_newstate();
	luaL_openlibs(L);
	if (luaL_dofile(L,"gamecfg.lua")) {
		const char * error = lua_tostring(L, -1);
		lua_pop(L,1);
		LOG_GAME(LOG_INFO,"error on load gamecfg.lua:%s\n",error);
		lua_close(L);
		return -1;
	}

	//连接group
	lua_getglobal(L,"togrp");
	luaTabRef_t obj = create_luaTabRef(L,-1);	
	g_config->groupip = kn_new_string(GET_OBJ_FIELD(obj,"ip",const char*,lua_tostring));
	g_config->groupport = GET_OBJ_FIELD(obj,"port",uint16_t,lua_tonumber);
	release_luaTabRef(&obj);

	//监听gate
	lua_getglobal(L,"gate");
	obj = create_luaTabRef(L,-1);
	g_config->lgateip = kn_new_string(GET_OBJ_FIELD(obj,"ip",const char*,lua_tostring));
	g_config->lgateport = GET_OBJ_FIELD(obj,"port",uint16_t,lua_tonumber);
	release_luaTabRef(&obj);

	lua_close(L);
	return 0;
}
