#include "lua_util.h"
#include "kendynet.h"
#include "rpacket.h"
#include "wpacket.h"

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


int lua_rpk_reverse_read_uint8(lua_State *L){
	rpacket_t rpk = lua_touserdata(L,1);
	lua_pushnumber(L,reverse_read_uint8(rpk));
	return 1;
}

int lua_rpk_reverse_read_uint16(lua_State *L){
	rpacket_t rpk = lua_touserdata(L,1);
	lua_pushnumber(L,reverse_read_uint16(rpk));
	return 1;
}

int lua_rpk_reverse_read_uint32(lua_State *L){
	rpacket_t rpk = lua_touserdata(L,1);
	lua_pushnumber(L,reverse_read_uint32(rpk));
	return 1;
}

int lua_rpk_reverse_read_double(lua_State *L){
	rpacket_t rpk = lua_touserdata(L,1);
	lua_pushnumber(L,reverse_read_double(rpk));
	return 1;
}

int lua_rpk_dropback(lua_State *L){
	rpacket_t rpk = lua_touserdata(L,1);
	uint32_t  dropsize = (uint32_t)lua_tonumber(L,2);
	rpk_dropback(rpk,dropsize);

	return 0;
}

//for wpacket

int lua_new_wpk(lua_State *L){
	wpacket_t wpk = wpk_create(128);
	lua_pushlightuserdata(L,wpk);
	return 1;
}

int lua_new_wpk_by_rpk(lua_State *L){
	rpacket_t rpk = lua_touserdata(L,1);
	wpacket_t wpk = wpk_copy_create((packet_t)rpk);
	lua_pushlightuserdata(L,wpk);
	return 1;
}

int lua_new_wpk_by_wpk(lua_State *L){
	wpacket_t l_wpk = lua_touserdata(L,1);
	wpacket_t wpk = wpk_copy_create((packet_t)l_wpk);
	lua_pushlightuserdata(L,wpk);
	return 1;
}

int lua_destroy_wpk(lua_State *L){
	wpacket_t wpk = lua_touserdata(L,1);
	destroy_packet(wpk);
	return 0;
}

int lua_wpk_write_uint8(lua_State *L){
	wpacket_t wpk = lua_touserdata(L,1);
	uint8_t v = (uint8_t)lua_tonumber(L,2);
	wpk_write_uint8(wpk,v);
	return 0;
}

int lua_wpk_write_uint16(lua_State *L){
	wpacket_t wpk = lua_touserdata(L,1);
	uint16_t v = (uint16_t)lua_tonumber(L,2);
	wpk_write_uint16(wpk,v);
	return 0;
}

int lua_wpk_write_uint32(lua_State *L){
	wpacket_t wpk = lua_touserdata(L,1);
	uint32_t v = (uint32_t)lua_tonumber(L,2);
	wpk_write_uint32(wpk,v);
	return 0;
}

int lua_wpk_write_double(lua_State *L){
	wpacket_t wpk = lua_touserdata(L,1);
	double v = (double)lua_tonumber(L,2);
	wpk_write_double(wpk,v);
	return 0;
}

int lua_wpk_write_string(lua_State *L){
	wpacket_t wpk = lua_touserdata(L,1);
	const char* v = lua_tostring(L,2);
	if(v) wpk_write_string(wpk,v);
	return 0;
}
