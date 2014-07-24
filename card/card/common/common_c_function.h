#ifndef _COMMON_C_FUNCTION_H
#define _COMMON_C_FUNCTION_H

//注册到lua中的公共函数

#include "lua/lua_util.h"
#include "kendynet.h"
#include "rpacket.h"
#include "wpacket.h"
#include "log.h"
#include "kn_stream_conn.h"
#include "netcmd.h"

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

int lua_conn_close(lua_State *L){
	kn_stream_conn_t conn = lua_touserdata(L,1);
	kn_stream_conn_close(conn);
	return 0;
}

int lua_send(lua_State *L){
/*
	luaObject_t o = create_luaObj(L,1);
	ident  _ident;
	lua_rawgeti(o->L,LUA_REGISTRYINDEX,o->rindex);
	
	lua_pushnumber(o->L,1);
	lua_gettable(o->L,-2);
	_ident._data[0] =  (uint32_t)lua_pop(L,-1);
	
	lua_pushnumber(o->L,2);
	lua_gettable(o->L,-2);
	_ident._data[1] =  (uint32_t)lua_pop(L,-1);	
	
	lua_pushnumber(o->L,3);
	lua_gettable(o->L,-2);
	_ident._data[2] =  (uint32_t)lua_pop(L,-1);	
	
	
	lua_pushnumber(o->L,4);
	lua_gettable(o->L,-2);
	_ident._data[3] =  (uint32_t)lua_pop(L,-1);	
	
	kn_stream_conn_t conn = cast2_kn_stream_conn(_ident);
	if(!conn){
		lua_pushboolean(L,0);
	}else{
		wpacket_t wpk = lua_touserdata(L,2);
		kn_stream_conn_send(conn,wpk);	
		lua_pushboolean(L,1);	
	}
	return 1;	 
*/	
	kn_stream_conn_t conn = lua_touserdata(L,1);
	wpacket_t wpk = lua_touserdata(L,2);
	if(0 == kn_stream_conn_send(conn,wpk))
		lua_pushboolean(L,1);
	else
		lua_pushboolean(L,0);
	return 1;
}

//redis
extern __thread kn_proactor_t t_proactor;

static inline void lua_on_redis_connected(redisconn_t conn,int err,void *ud){
	luaObject_t obj = (luaObject_t)ud;
	const char *error;
	if((error = CALL_OBJ_FUNC2(obj,"on_connect",0,
				   lua_pushlightuserdata(obj->L,conn),
				   lua_pushnumber(obj->L,err)))){
		SYS_LOG(LOG_ERROR,"on_redis_connected:%s\n",error);
		release_luaObj(obj);
	}
}

static inline void lua_on_redis_disconnected(redisconn_t conn,void *ud){
	luaObject_t obj = (luaObject_t)ud;
	const char *error;
	if((error = CALL_OBJ_FUNC1(obj,"on_disconnect",0,
			  lua_pushlightuserdata(obj->L,conn)))){
		SYS_LOG(LOG_ERROR,"on_redis_disconnected:%s\n",error);
	}	
	release_luaObj(obj);
}

int lua_redis_connect(lua_State *L){
	const char *ip = lua_tostring(L,1);
	unsigned short port = (unsigned short)lua_tonumber(L,2);
	luaObject_t    obj = create_luaObj(L,3);
	if(0 != kn_redisAsynConnect(t_proactor,ip,port,lua_on_redis_connected,
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


static void build_resultset(struct redisReply* reply,lua_State *L){
	if(reply->type == REDIS_REPLY_INTEGER){
		lua_pushinteger(L,(int32_t)reply->integer);
	}else if(reply->type == REDIS_REPLY_STRING){
		lua_pushstring(L,reply->str);
	}else if(reply->type == REDIS_REPLY_ARRAY){
		lua_newtable(L);
		int i = 0;
		for(; i < reply->elements; ++i){
			//lua_pushinteger(L,i+1);
			build_resultset(reply->element[i],L);
			lua_rawseti(L,-2,i+1);//lua_settable(L, -3);
		}
	}else{
		lua_pushnil(L);
	}
}

void redis_command_cb(redisconn_t conn,struct redisReply* reply,void *pridata)
{
	printf("redis_command_cb\n");
	luaObject_t obj = (luaObject_t)pridata;
	const char * error;
	if(!reply || reply->type == REDIS_REPLY_NIL){
		if((error = CALL_OBJ_FUNC2(obj,"callback",0,lua_pushnil(obj->L),lua_pushnil(obj->L)))){
			SYS_LOG(LOG_ERROR,"redis_command_cb:%s\n",error);
			printf("redis_command_cb:%s\n",error);
		}				
	}else if(reply->type == REDIS_REPLY_ERROR){
		if((error = CALL_OBJ_FUNC2(obj,"callback",0,lua_pushstring(obj->L,reply->str),lua_pushnil(obj->L)))){
			SYS_LOG(LOG_ERROR,"redis_command_cb:%s\n",error);
			printf("redis_command_cb:%s\n",error);
		}			
	}else{
		if((error = CALL_OBJ_FUNC2(obj,"callback",0,lua_pushnil(obj->L),build_resultset(reply,obj->L)))){
			SYS_LOG(LOG_ERROR,"redis_command_cb:%s\n",error);
			printf("redis_command_cb:%s\n",error);
		}			
	} 	
	release_luaObj(obj);
}

int lua_redisCommand(lua_State *L){
	redisconn_t conn = (redisconn_t)lua_touserdata(L,1);
	const char *cmd = lua_tostring(L,2);
	luaObject_t obj = create_luaObj(L,3);
	do{
		if(!cmd || strcmp(cmd,"") == 0){
			lua_pushboolean(L,0);
			break;
		}
		
		void (*cb)(redisconn_t,struct redisReply*,void *) = NULL; 
		if(obj) cb = redis_command_cb;
		if(REDIS_OK!= kn_redisCommand(conn,cmd,cb,obj))
			lua_pushboolean(L,0);
		else
			lua_pushboolean(L,1);
	}while(0);
	return 1;
}

extern int on_db_initfinish(lua_State *L); 

int lua_timer_callback(kn_timer_t t)//如果返回1继续注册，否则不再注册
{
	luaObject_t obj = (luaObject_t)kn_timer_getud(t);
	lua_State *L = obj->L;
	const char* error = NULL;
	if((error = CALL_OBJ_FUNC(obj,"on_timeout",1))){
		//LOG_GAME(LOG_INFO,"error on on_timeout:%s\n",error);
		printf("error on on_timeout:%s\n",error);
		return 1;
	}	
	int ret = lua_tonumber(L,-1);
	lua_pop(L,1);
	return ret;	
}

int lua_reg_timer(lua_State *L){
	uint64_t    timeout = (uint64_t)lua_tonumber(L,1); 
	luaObject_t obj = create_luaObj(L,2);
	kn_reg_timer(t_proactor,timeout,lua_timer_callback,(void*)obj);
	return 0;
}

int lua_del_timer(lua_State *L){
	kn_timer_t timer = lua_touserdata(L,1);
	luaObject_t obj = (luaObject_t)kn_timer_getud(timer);
	kn_del_timer(timer);
	release_luaObj(obj);
	return 0;
}

int lua_break(lua_State *L){
	return 0;
}

int reg_cmd_handler(lua_State *L);


#define REGISTER_CONST(L,N) do{\
		lua_pushstring(L, #N);\
		lua_pushinteger(L, N);\
		lua_settable(L, -3);\
}while(0)


#define REGISTER_FUNCTION(NAME,FUNC) do{\
	lua_pushstring(L,NAME);\
	lua_pushcfunction(L,FUNC);\
	lua_settable(L, -3);\
}while(0)	

void reg_common_c_function(lua_State *L){
	
	lua_getglobal(L,"_G");
	if(!lua_istable(L, -1))
	{
		lua_pop(L,1);
		lua_newtable(L);
		lua_pushvalue(L,-1);
		lua_setglobal(L,"_G");
	}
	
	
	//client <-> agent
	REGISTER_CONST(L,ERROR_STATUS_SUCCESS);
	REGISTER_CONST(L,ERROR_STATUS_UNKNOWN);
	
	REGISTER_CONST(L,ERROR_STATUS_LOGIN_PASSWORD);
	REGISTER_CONST(L,ERROR_STATUS_LOGIN_RELOGIN);
	REGISTER_CONST(L,ERROR_STATUS_LOGIN_NOROLE);
	REGISTER_CONST(L,ERROR_STATUS_LOGIN_NO_RECONNECT);
	REGISTER_CONST(L,ERROR_STATUS_CREATE_ROLE_MALLOC);
	REGISTER_CONST(L,ERROR_STATUS_CREATE_ROLE_FAIL);
	REGISTER_CONST(L,ERROR_STATUS_CREATE_ROLE_RENAME);
	REGISTER_CONST(L,ERROR_STATUS_CREATE_ROLE_DB);
	REGISTER_CONST(L,ERROR_STATUS_CREATE_ROLE_NAME_LEN);
	
	REGISTER_CONST(L,CSID_PING_REQ);
	REGISTER_CONST(L,SSID_CONNECTSERVER_RPT);
	REGISTER_CONST(L,SSID_SERVERSTOP_PREPARE);
	REGISTER_CONST(L,SSID_SERVERSTOP_FINAL);
	REGISTER_CONST(L,GDID_USER_INFO_REQ);
	REGISTER_CONST(L,DGID_USER_INFO_ACK);
	REGISTER_CONST(L,DGID_NO_USER_ACK);
	REGISTER_CONST(L,GDID_CREATE_ROLE_REQ);
	REGISTER_CONST(L,DGID_CREATE_ROLE_ACK);
	REGISTER_CONST(L,GDID_UPDATE_USER_INFO_REQ);		
	REGISTER_CONST(L,CSID_LOGIN_REQ);
	REGISTER_CONST(L,CSID_CREATE_ROLE_REQ);
	REGISTER_CONST(L,CSID_RECONNECT_REQ);
	REGISTER_CONST(L,SCID_PING_ACK);
	REGISTER_CONST(L,SCID_LOGIN_ACK);
	REGISTER_CONST(L,SCID_CREATE_ROLE_ACK);
	REGISTER_CONST(L,SCID_ROLE_INFO_ACK);
	REGISTER_CONST(L,SCID_RECONNECT_ACK);	
	REGISTER_CONST(L,CSID_ENTERMAP_REQ);
	REGISTER_CONST(L,CSID_MAP_INFO);
	REGISTER_CONST(L,CSID_ENTERMAP_ACK);
	REGISTER_CONST(L,CSID_MOVETEST_REQ );
	REGISTER_CONST(L,CSID_MAPPOINT_INFO);
	REGISTER_CONST(L,CSID_MOVETEST_ACK);
	REGISTER_CONST(L,CSID_ENTERFIGHT_REQ);
	REGISTER_CONST(L,CSID_FIGHT_FRAME_DATA);
	REGISTER_CONST(L,CSID_ENTERFIGHT_ACK);
	REGISTER_CONST(L,CSID_PREFIGHT_REQ);
	REGISTER_CONST(L,CSID_PREFIGHT_INFO);
	REGISTER_CONST(L,CSID_PREFIGHT_ACK);
	REGISTER_CONST(L,CSID_MAPREWARD_REQ);
	REGISTER_CONST(L,CSID_MAPREWARD_INFO);
	REGISTER_CONST(L,CSID_MAPREWARD_ACK);
	REGISTER_CONST(L,CSID_FIGHT_RESULT);
	REGISTER_CONST(L,CSID_MAP_REWARD);
	REGISTER_CONST(L,CSID_MAPFINISHED_REQ);		
	REGISTER_CONST(L,DUMMY_ON_CLI_DISCONNECTED);		
		
	REGISTER_FUNCTION("rpk_read_uint8",&lua_rpk_read_uint8);	
	REGISTER_FUNCTION("rpk_read_uint16",&lua_rpk_read_uint16);	
	REGISTER_FUNCTION("rpk_read_uint32",&lua_rpk_read_uint32);	
	REGISTER_FUNCTION("rpk_read_double",&lua_rpk_read_double);
	REGISTER_FUNCTION("rpk_read_string",&lua_rpk_read_string);		

	REGISTER_FUNCTION("rpk_reverse_read_uint8",&lua_rpk_reverse_read_uint8);
	REGISTER_FUNCTION("rpk_reverse_read_uint16",&lua_rpk_reverse_read_uint16);
	REGISTER_FUNCTION("rpk_reverse_read_uint32",&lua_rpk_reverse_read_uint32);
	REGISTER_FUNCTION("rpk_reverse_read_double",&lua_rpk_reverse_read_double);				


	REGISTER_FUNCTION("rpk_dropback",&lua_rpk_dropback);	
	REGISTER_FUNCTION("new_wpk",&lua_new_wpk);
	REGISTER_FUNCTION("new_wpk_by_rpk",&lua_new_wpk_by_rpk);	
	REGISTER_FUNCTION("new_wpk_by_wpk",&lua_new_wpk_by_wpk);
	REGISTER_FUNCTION("destroy_wpk",&lua_destroy_wpk);


	REGISTER_FUNCTION("wpk_write_uint8",&lua_wpk_write_uint8);
	REGISTER_FUNCTION("wpk_write_uint16",&lua_wpk_write_uint16);
	REGISTER_FUNCTION("wpk_write_uint32",&lua_wpk_write_uint32);	
	REGISTER_FUNCTION("wpk_write_double",&lua_wpk_write_double);
	REGISTER_FUNCTION("wpk_write_string",&lua_wpk_write_string);	

	lua_pop(L,1);
    
	lua_newtable(L);
		
	REGISTER_FUNCTION("initwordfilter",&lua_initwordfilter);
	REGISTER_FUNCTION("isvaildword",&lua_isvaildword);
	REGISTER_FUNCTION("systemms",&lua_systemms);
	REGISTER_FUNCTION("syslog",&lua_syslog);			

	REGISTER_FUNCTION("send",&lua_send);

	//redis
	REGISTER_FUNCTION("redis_connect",&lua_redis_connect);	
	REGISTER_FUNCTION("redis_close",&lua_redis_close);
	REGISTER_FUNCTION("redisCommand",&lua_redisCommand);		

	REGISTER_FUNCTION("db_initfinish",&on_db_initfinish);		
	REGISTER_FUNCTION("reg_timer",&lua_reg_timer);	
	REGISTER_FUNCTION("del_timer",&lua_del_timer);	
	REGISTER_FUNCTION("reg_cmd_handler",&reg_cmd_handler);	
	REGISTER_FUNCTION("debug",&lua_break);
	
	lua_setglobal(L,"C");
}



#endif
