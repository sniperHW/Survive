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
		
	//监听
	lua_getglobal(L,"listen");
	luaTabRef_t obj = create_luaTabRef(L,-1);
	g_config->listenip = kn_new_string(LuaTabRefGet(obj,"ip",const char*,lua_tostring));
	g_config->listenport = LuaTabRefGet(obj,"port",uint16_t,lua_tonumber);
	release_luaTabRef(&obj);
	lua_close(L);
	return 0;
}
