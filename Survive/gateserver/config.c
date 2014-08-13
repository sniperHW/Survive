#include "config.h"
#include "lua_util.h"
#include "gateserver.h"

config* g_config = NULL;

int loadconfig(){
	g_config = calloc(1,sizeof(*g_config));
	lua_State *L = luaL_newstate();
	luaL_openlibs(L);
	if (luaL_dofile(L,"gatecfg.lua")) {
		const char * error = lua_tostring(L, -1);
		lua_pop(L,1);
		LOG_GATE(LOG_INFO,"error on load gatecfg.lua:%s\n",error);
		lua_close(L);
		return -1;
	}
	
	//连接group
	//luaObject_t obj = GETGLOBAL_OBJECT(L,"togrp");
	
	lua_getglobal(L,"togrp");
	luaTabRef_t obj = create_luaTabRef(L,-1);	
	g_config->groupip = kn_new_string(LuaTabRefGet(obj,"ip",const char*,lua_tostring));
	g_config->groupport = LuaTabRefGet(obj,"port",uint16_t,lua_tonumber);
	release_luaTabRef(&obj);

	//连接redis

	lua_getglobal(L,"toredis");
	obj = create_luaTabRef(L,-1);	
	g_config->redisip = kn_new_string(LuaTabRefGet(obj,"ip",const char*,lua_tostring));
	g_config->redisport = LuaTabRefGet(obj,"port",uint16_t,lua_tonumber);
	release_luaTabRef(&obj);

	//监听客户端
	lua_getglobal(L,"listen");
	obj = create_luaTabRef(L,-1);		
	g_config->toclientip = kn_new_string(LuaTabRefGet(obj,"ip",const char*,lua_tostring));
	g_config->toclientport = LuaTabRefGet(obj,"port",uint16_t,lua_tonumber);
	release_luaTabRef(&obj);
	lua_getglobal(L,"agentcount");
	g_config->agentcount = lua_tointeger(L,-1);
	lua_close(L);
	return 0;
}
