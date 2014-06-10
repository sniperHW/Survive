#include "config.h"
#include "lua/lua_util.h"

config* g_config = NULL;

int loadconfig(){
	g_config = calloc(1,sizeof(*g_config));
	lua_State *L = luaL_newstate();
	luaL_openlibs(L);
	if (luaL_dofile(L,"gatecfg.lua")) {
		const char * error = lua_tostring(L, -1);
		lua_pop(L,1);
		return -1;
	}

	luaObject_t obj = GETGLOBAL_OBJECT(L,"togrp");
	g_config->groupip = kn_new_string(GET_OBJ_FIELD(obj,"ip",const char*,lua_tostring));
	g_config->groupport = (uint16_t)GET_OBJ_FIELD(obj,"port",const char*,lua_number);
	release_luaObj(obj);

	luaObject_t obj = GETGLOBAL_OBJECT(L,"toredis");
	g_config->redisip = kn_new_string(GET_OBJ_FIELD(obj,"ip",const char*,lua_tostring));
	g_config->redisport = (uint16_t)GET_OBJ_FIELD(obj,"port",const char*,lua_number);
	release_luaObj(obj);

	obj = GETGLOBAL_OBJECT(L,"toclient");
	g_config->toclientip = kn_new_string(GET_OBJ_FIELD(obj,"ip",const char*,lua_tostring));
	g_config->toclientport = (uint16_t)GET_OBJ_FIELD(obj,"port",const char*,lua_number);
	release_luaObj(obj);
	g_config->agentcount = GETGLOBAL_NUMBER(L,"agentcount");

	return 0;
}