#include "config.h"
#include "lua_util.h"
#include "groupserver.h"

config* g_config = NULL;

int loadconfig(){
	g_config = calloc(1,sizeof(*g_config));
	lua_State *L = luaL_newstate();
	luaL_openlibs(L);
	if (luaL_dofile(L,"groupcfg.lua")) {
		const char * error = lua_tostring(L, -1);
		lua_pop(L,1);
		LOG_GROUP(LOG_INFO,"error on load gatecfg.lua:%s\n",error);
		lua_close(L);
		return -1;
	}
	
	//监听game
	//luaObject_t obj = GETGLOBAL_OBJECT(L,"game");
	lua_getglobal(L,"game");
	luaTabRef_t obj = create_luaTabRef(L,-1);	
	g_config->lgameip = kn_new_string(LuaTabRefGet(obj,"ip",const char*,lua_tostring));
	g_config->lgameport = LuaTabRefGet(obj,"port",uint16_t,lua_tonumber);
	release_luaTabRef(&obj);
	
	//监听gate
	lua_getglobal(L,"gate");
	obj = create_luaTabRef(L,-1);
	g_config->lgateip = kn_new_string(LuaTabRefGet(obj,"ip",const char*,lua_tostring));
	g_config->lgateport = LuaTabRefGet(obj,"port",uint16_t,lua_tonumber);
	release_luaTabRef(&obj);
	
	//监听group
	lua_getglobal(L,"group");
	obj = create_luaTabRef(L,-1);
	g_config->lgroupip = kn_new_string(LuaTabRefGet(obj,"ip",const char*,lua_tostring));
	g_config->lgroupport = LuaTabRefGet(obj,"port",uint16_t,lua_tonumber);
	release_luaTabRef(&obj);	
	
	lua_close(L);
	return 0;
}
