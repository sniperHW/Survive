#ifndef _COMMON_C_FUNCTION_H
#define _COMMON_C_FUNCTION_H

//注册到lua中的公共函数

#include "lua/lua_util.h"
#include "kendynet.h"
#include "rpacket.h"
#include "wpacket.h"
#include "log.h"
#include "kn_stream_conn.h"

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
	rpk_dropback(rpk);
	return 0;
}

//for wpacket

int lua_new_wpk(lua_State *L){
	wpacket_t wpk = wpk_create(128,0);
	lua_pushlightuserdata(L,wpk);
	return 1;
}

int lua_new_wpk_by_rpk(lua_State *L){
	rpacket_t rpk = lua_touserdata(L,1);
	wpacket_t wpk = wpk_create_by_rpacket(rpk);
	lua_pushlightuserdata(L,wpk);
	return 1;
}

int lua_new_wpk_by_wpk(lua_State *L){
	wpacket_t l_wpk = lua_touserdata(L,1);
	wpacket_t wpk = wpk_create_by_wpacket(l_wpk);
	lua_pushlightuserdata(L,wpk);
	return 1;
}

int lua_destroy_wpk(lua_State *L){
	wpacket_t wpk = lua_touserdata(L,1);
	wpk_destroy(wpk);
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

//end packet

int lua_systemms(lua_State *L){
	lua_pushnumber(L,kn_systemms());
	return 1;
}

int lua_syslog(lua_State *L){
	int lev = lua_tonumber(L,1);
	const char *msg = lua_tostring(L,2);
	SYS_LOG(lev,"%s",msg);
	return 0;
}

int lua_send(lua_State *L){
	kn_stream_conn_t conn = lua_touserdata(L,1);
	wpacket_t wpk = lua_touserdata(L,2);
	kn_stream_conn_send(conn,wpk);
	return 0;
}

//redis

static inline lua_on_redis_connected(redisconn_t conn,int err,void *ud){
	luaObject_t obj = (luaObject_t)ud;
	if(CALL_OBJ_FUNC2(obj,"on_connect",
				   (conn?lua_pushlightuserdata(obj->L,conn):lua_pushnil(L)),
				   lua_pushnumber(L,err))){
		const char * error = lua_tostring(obj->L, -1);
		SYS_LOG(LOG_ERROR,"on_redis_connected:%s\n",error);
		lua_pop(obj->L,1);
		release_luaObj(obj);
	}
}

static inline lua_on_redis_disconnected(redisconn_t conn,int err,void *ud){
	luaObject_t obj = (luaObject_t)ud;
	if(CALL_OBJ_FUNC2(obj,"on_disconnect",
					  lua_pushlightuserdata(obj->L,conn),
					  lua_pushnumber(L,err))){
		const char * error = lua_tostring(obj->L, -1);
		SYS_LOG(LOG_ERROR,"on_redis_disconnected:%s\n",error);
		lua_pop(obj->L,1);
	}	
	release_luaObj(obj);
}

int lua_redis_connect(lua_State *L){
	const char *ip = lua_tostring(L,1);
	unsigned short port = (unsigned short)lua_tonumber(L,2);
	luaObject_t    obj = create_luaObj(L,3);
	if(0 != kn_redisAsynConnect(ip,port,lua_on_redis_connected,
								lua_on_redis_disconnected,(void*)obj))
	{
		release_luaObj(obj);
		lua_pushboolean(L,0);
	}else
		lua_pushboolean(L,1);
	return 1;
}

int lua_redis_close(lua_State *L){
	redisconn_t conn = lua_touserdata(L,1);
	kn_redisDisconnect(conn);
	return 0;
}

/*
struct redisReply;						
int kn_redisCommand(redisconn_t,const char *cmd,
					void (*cb)(redisconn_t,struct redisReply*,void *pridata),void *pridata);					
*/
int lua_redisCommand(lua_State *L){
	
	return 1;
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
	
	lua_pushstring(L,"rpk_read_uint8");
	lua_pushcfunction(L,&lua_rpk_read_uint8);
	lua_settable(L, -3);

	lua_pushstring(L,"rpk_read_uint16");
	lua_pushcfunction(L,&lua_rpk_read_uint16);
	lua_settable(L, -3);

	lua_pushstring(L,"rpk_read_uint32");
	lua_pushcfunction(L,&lua_rpk_read_uint32);
	lua_settable(L, -3);

	lua_pushstring(L,"rpk_read_uint64");
	lua_pushcfunction(L,&lua_rpk_read_uint64);
	lua_settable(L, -3);

	lua_pushstring(L,"rpk_read_double");
	lua_pushcfunction(L,&lua_rpk_read_double);
	lua_settable(L, -3);

	lua_pushstring(L,"rpk_read_string");
	lua_pushcfunction(L,&lua_rpk_read_string);
	lua_settable(L, -3);

	lua_pushstring(L,"rpk_reverse_read_uint8");
	lua_pushcfunction(L,&lua_rpk_reverse_read_uint8);
	lua_settable(L, -3);

	lua_pushstring(L,"rpk_reverse_read_uint16");
	lua_pushcfunction(L,&lua_rpk_reverse_read_uint16);
	lua_settable(L, -3);

	lua_pushstring(L,"rpk_reverse_read_uint32");
	lua_pushcfunction(L,&lua_rpk_reverse_read_uint32);
	lua_settable(L, -3);

	lua_pushstring(L,"rpk_reverse_read_double");
	lua_pushcfunction(L,&lua_rpk_reverse_read_double);
	lua_settable(L, -3);

	lua_pushstring(L,"rpk_dropback");
	lua_pushcfunction(L,&lua_rpk_dropback);
	lua_settable(L, -3);
	
	lua_pushstring(L,"new_wpk");
	lua_pushcfunction(L,&lua_new_wpk);
	lua_settable(L, -3);

	lua_pushstring(L,"new_wpk_by_rpk");
	lua_pushcfunction(L,&lua_new_wpk_by_rpk);
	lua_settable(L, -3);

	lua_pushstring(L,"new_wpk_by_wpk");
	lua_pushcfunction(L,&lua_new_wpk_by_wpk);
	lua_settable(L, -3);

	lua_pushstring(L,"destroy_wpk");
	lua_pushcfunction(L,&lua_destroy_wpk);
	lua_settable(L, -3);

	lua_pushstring(L,"wpk_write_uint8");
	lua_pushcfunction(L,&lua_wpk_write_uint8);
	lua_settable(L, -3);

	lua_pushstring(L,"wpk_write_uint16");
	lua_pushcfunction(L,&lua_wpk_write_uint16);
	lua_settable(L, -3);

	lua_pushstring(L,"wpk_write_uint32");
	lua_pushcfunction(L,&lua_wpk_write_uint32);
	lua_settable(L, -3);

	lua_pushstring(L,"wpk_write_uint64");
	lua_pushcfunction(L,&lua_wpk_write_uint64);
	lua_settable(L, -3);

	lua_pushstring(L,"wpk_write_double");
	lua_pushcfunction(L,&lua_wpk_write_double);
	lua_settable(L, -3);

	lua_pushstring(L,"wpk_write_string");
	lua_pushcfunction(L,&lua_wpk_write_string);
	lua_settable(L, -3);

	lua_pushstring(L,"systemms");
	lua_pushcfunction(L,&lua_systemms);
	lua_settable(L, -3);

	lua_pushstring(L,"syslog");
	lua_pushcfunction(L,&lua_syslog);
	lua_settable(L, -3);

	lua_pushstring(L,"send");
	lua_pushcfunction(L,&lua_send);
	lua_settable(L, -3);

	//redis
	lua_pushstring(L,"redis_connect");
	lua_pushcfunction(L,&lua_redis_connect);
	lua_settable(L, -3);

	lua_pushstring(L,"redis_close");
	lua_pushcfunction(L,&lua_redis_close);
	lua_settable(L, -3);

	lua_pushstring(L,"redisCommand");
	lua_pushcfunction(L,&lua_redisCommand);
	lua_settable(L, -3);
	
	lua_setglobal(L,"C");
}



#endif
