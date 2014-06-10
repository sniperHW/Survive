#ifndef _COMMON_C_FUNCTION_H
#define _COMMON_C_FUNCTION_H

//注册到lua中的公共函数

#include "lua/lua_util.h"
#include "kendynet.h"
#include "rpacket.h"
#include "wpacket.h"
#include "log.h"

//for rpacket
int lua_rpk_read_uint8(lua_State *L){
	rpacket_t rpk = lua_touserdata(L,1);
	lua_pushnumber(L,rpk_read_uint8(rpk));
	return 1;
}

int lua_rpk_read_uint16(lua_State *L){
	rpacket_t rpk = lua_touserdata(L,1);
	lua_pushnumber(L,rpk_read_uint16(rpk));
	return 1;
}

int lua_rpk_read_uint32(lua_State *L){
	rpacket_t rpk = lua_touserdata(L,1);
	lua_pushnumber(L,rpk_read_uint32(rpk));
	return 1;
}

int lua_rpk_read_uint64(lua_State *L){
	rpacket_t rpk = lua_touserdata(L,1);
	lua_pushnumber(L,rpk_read_uint64(rpk));
	return 1;
}

int lua_rpk_read_double(lua_State *L){
	rpacket_t rpk = lua_touserdata(L,1);
	lua_pushnumber(L,rpk_read_double(rpk));
	return 1;	
}

int lua_rpk_read_string(lua_State *L){
	rpacket_t rpk = lua_touserdata(L,1);
	lua_pushstring(L,rpk_read_string(rpk));
	return 1;	
}

//for wpacket

int lua_wpk_write_uint8(lua_State *L){
	wpacket_t rpk = lua_touserdata(L,1);
	uint8_t v = (uint8_t)lua_tonumber(L,2);
	wpk_write_uint8(v);
	return 0;
}

int lua_wpk_write_uint16(lua_State *L){
	wpacket_t rpk = lua_touserdata(L,1);
	uint16_t v = (uint16_t)lua_tonumber(L,2);
	wpk_write_uint16(v);
	return 0;
}

int lua_wpk_write_uint32(lua_State *L){
	wpacket_t rpk = lua_touserdata(L,1);
	uint32_t v = (uint32_t)lua_tonumber(L,2);
	wpk_write_uint32(v);
	return 0;
}

int lua_wpk_write_uint64(lua_State *L){
	wpacket_t rpk = lua_touserdata(L,1);
	uint64_t v = (uint64_t)lua_tonumber(L,2);
	wpk_write_uint64(v);
	return 0;
}

int lua_wpk_write_double(lua_State *L){
	wpacket_t rpk = lua_touserdata(L,1);
	double v = (double)lua_tonumber(L,2);
	wpk_write_double(v);
	return 0;
}

int lua_wpk_write_string(lua_State *L){
	wpacket_t rpk = lua_touserdata(L,1);
	const char* v = lua_tostring(L,2);
	if(v) wpk_write_string(v);
	return 0;
}

//end packet

int lua_systemms(lua_State *L){
	lua_pushnumber(L,kn_systemms());
	return 1;
}

int lua_syslog(lua_State *L){
	int lev = lua_tonumber(L,1);
	const char *msg = lua_tostring(L,2);
	SYS_LOG(lev,msg);
	return 0;
}


void reg_common_c_function(lua_State *L){
	
	lua_getglobal(L,"_G");
	if(!lua_istable(L, -1))
	{
		lua_pop(L,1);
		lua_newtable(L);
		lua_pushvalue(L,-1);
		lua_setglobal(L,"_G");
	}
	lua_pushstring(L, "LOG_INFO");
	lua_pushinteger(L, LOG_INFO);
	lua_settable(L, -3);
	
	lua_pushstring(L, "LOG_ERROR");
	lua_pushinteger(L, LOG_ERROR);
	lua_settable(L, -3);

	lua_pop(L,1);
    
	lua_newtable(L);
	
	lua_pushstring(L,"lua_rpk_read_uint8");
	lua_pushcfunction(L,&rpk_read_uint8);
	lua_settable(L, -3);

	lua_pushstring(L,"lua_rpk_read_uint16");
	lua_pushcfunction(L,&rpk_read_uint16);
	lua_settable(L, -3);

	lua_pushstring(L,"lua_rpk_read_uint32");
	lua_pushcfunction(L,&rpk_read_uint32);
	lua_settable(L, -3);

	lua_pushstring(L,"lua_rpk_read_uint64");
	lua_pushcfunction(L,&rpk_read_uint64);
	lua_settable(L, -3);

	lua_pushstring(L,"lua_rpk_read_double");
	lua_pushcfunction(L,&rpk_read_double);
	lua_settable(L, -3);

	lua_pushstring(L,"lua_rpk_read_string");
	lua_pushcfunction(L,&rpk_read_string);
	lua_settable(L, -3);

	lua_pushstring(L,"lua_wpk_write_uint8");
	lua_pushcfunction(L,&wpk_write_uint8);
	lua_settable(L, -3);

	lua_pushstring(L,"lua_wpk_write_uint16");
	lua_pushcfunction(L,&wpk_write_uint16);
	lua_settable(L, -3);

	lua_pushstring(L,"lua_wpk_write_uint32");
	lua_pushcfunction(L,&wpk_write_uint32);
	lua_settable(L, -3);

	lua_pushstring(L,"lua_wpk_write_uint64");
	lua_pushcfunction(L,&wpk_write_uint64);
	lua_settable(L, -3);

	lua_pushstring(L,"lua_wpk_write_double");
	lua_pushcfunction(L,&wpk_write_double);
	lua_settable(L, -3);

	lua_pushstring(L,"lua_wpk_write_string");
	lua_pushcfunction(L,&wpk_write_string);
	lua_settable(L, -3);

	lua_pushstring(L,"lua_systemms");
	lua_pushcfunction(L,&systemms);
	lua_settable(L, -3);

	lua_pushstring(L,"lua_syslog");
	lua_pushcfunction(L,&syslog);
	lua_settable(L, -3);
	
	lua_setglobal(L,"C");
}



#endif