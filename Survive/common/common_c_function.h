#ifndef _COMMON_C_FUNCTION_H
#define _COMMON_C_FUNCTION_H

//注册到lua中的公共函数

#include "lua_util.h"
#include "kendynet.h"
#include "rpacket.h"
#include "wpacket.h"
#include "log.h"
#include "stream_conn.h"
#include "netcmd.h"
#include "kn_redis.h"
#include "common/wordfilter.h"

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
	stream_conn_t conn = lua_touserdata(L,1);
	wpacket_t wpk = lua_touserdata(L,2);
	if(0 == stream_conn_send(conn,(packet_t)wpk))
		lua_pushboolean(L,1);
	else
		lua_pushboolean(L,0);
	return 1;
}

//redis
extern __thread engine_t t_engine;

static inline void lua_on_redis_connected(redisconn_t conn,int err,void *ud){
	luaTabRef_t *obj = (luaTabRef_t*)ud;
	const char *error;
	if((error = CallLuaTabFunc2(NULL,(*obj),"on_connect",0,
				   (conn ? lua_pushlightuserdata(obj->L,conn):lua_pushnil(obj->L)),
				   lua_pushinteger(obj->L,err)))){
		SYS_LOG(LOG_ERROR,"on_redis_connected:%s\n",error);
		release_luaTabRef(obj);
		free(obj);
	}
}

static inline void lua_on_redis_disconnected(redisconn_t conn,void *ud){
	luaTabRef_t *obj = (luaTabRef_t*)ud;
	const char *error;
	if((error = CallLuaTabFunc1(NULL,(*obj),"on_disconnect",0,
			  lua_pushlightuserdata(obj->L,conn)))){
		SYS_LOG(LOG_ERROR,"on_redis_disconnected:%s\n",error);
	}	
	release_luaTabRef(obj);
	free(obj);
}

int lua_redis_connect(lua_State *L){
	const char *ip = lua_tostring(L,1);
	unsigned short port = (unsigned short)lua_tonumber(L,2);
	luaTabRef_t    *obj = calloc(1,sizeof(*obj));	
	*obj = create_luaTabRef(L,3);
	if(0 != kn_redisAsynConnect(t_engine,ip,port,lua_on_redis_connected,
				   lua_on_redis_disconnected,(void*)obj))
	{
		release_luaTabRef(obj);
		free(obj);
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
	luaTabRef_t *obj = (luaTabRef_t*)pridata;
	const char * error;
	if(!reply || reply->type == REDIS_REPLY_NIL){
		if((error = CallLuaTabFunc2(NULL,(*obj),"callback",0,lua_pushnil(obj->L),lua_pushnil(obj->L)))){
			SYS_LOG(LOG_ERROR,"redis_command_cb:%s\n",error);
			printf("redis_command_cb:%s\n",error);
		}				
	}else if(reply->type == REDIS_REPLY_ERROR){
		if((error = CallLuaTabFunc2(NULL,(*obj),"callback",0,lua_pushstring(obj->L,reply->str),lua_pushnil(obj->L)))){
			SYS_LOG(LOG_ERROR,"redis_command_cb:%s\n",error);
			printf("redis_command_cb:%s\n",error);
		}			
	}else{
		if((error = CallLuaTabFunc2(NULL,(*obj),"callback",0,lua_pushnil(obj->L),build_resultset(reply,obj->L)))){
			SYS_LOG(LOG_ERROR,"redis_command_cb:%s\n",error);
			printf("redis_command_cb:%s\n",error);
		}			
	} 	
	release_luaTabRef(obj);
	free(obj);
}

int lua_redisCommand(lua_State *L){
	redisconn_t conn = (redisconn_t)lua_touserdata(L,1);
	const char *cmd = lua_tostring(L,2);
	luaTabRef_t    *obj = calloc(1,sizeof(*obj));	
	*obj = create_luaTabRef(L,3);	
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

static __thread wordfilter_t filter = NULL; 

int lua_initwordfilter(lua_State *L){
	int len = lua_rawlen(L,1);
	const char **words = calloc(len+1,sizeof(char*));
	int c = 0;
	luaTabRef_t    *obj = calloc(1,sizeof(*obj));	
	*obj = create_luaTabRef(L,1);	
	LuaTabEnum((*obj)){
		const char *tmp = lua_tostring(L,EnumVal);
		char *word = calloc(1,strlen(tmp)+1);
		strcpy(word,tmp);
		words[c++] = word;
	}
	words[c] = NULL;
	filter = wordfilter_new(words);
	int i = 0;
	for(; i < c; ++i)
		if(words[i]) free((void*)words[i]);
	free(words);
	return 0;
}

int lua_isvaildword(lua_State *L){
	const char *word = lua_tostring(L,1);
	if(isvaildword(filter,word))
		lua_pushboolean(L,1);
	else
		lua_pushboolean(L,0);
	return 1;
}

int lua_timer_callback(kn_timer_t t)//如果返回1继续注册，否则不再注册
{
	luaTabRef_t *obj = (luaTabRef_t*)kn_timer_getud(t);
	lua_State *L = obj->L;
	const char* error = NULL;
	if((error = CallLuaTabFunc0(NULL,(*obj),"on_timeout",1))){
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
	luaTabRef_t *obj = calloc(1,sizeof(*obj));
	*obj = create_luaTabRef(L,2);
	kn_reg_timer(t_engine,timeout,lua_timer_callback,(void*)obj);
	return 0;
}

int lua_del_timer(lua_State *L){
	kn_timer_t timer = lua_touserdata(L,1);
	luaTabRef_t *obj = (luaTabRef_t*)kn_timer_getud(timer);
	kn_del_timer(timer);
	release_luaTabRef(obj);
	free(obj);
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


#define GAMESERVER  1
#define GATESERVER  2
#define GROUPSERVER 3


int lua_set_conn_type(lua_State *L){
	stream_conn_t conn = lua_touserdata(L,1);
	int type = lua_tointeger(L,2);
	stream_conn_setud(conn,(void*)type);
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
	
	REGISTER_CONST(L,GAMESERVER);
	REGISTER_CONST(L,GATESERVER);
	REGISTER_CONST(L,GROUPSERVER);
	
	//client <-> agent
	REGISTER_CONST(L,CMD_CA_LOGIN);
	
	//client <-> game
	REGISTER_CONST(L,CMD_CS_MOV);	
	REGISTER_CONST(L,CMD_SC_ENTERMAP);	
	REGISTER_CONST(L,CMD_SC_ENTERSEE);	
	REGISTER_CONST(L,CMD_SC_LEAVESEE);
	REGISTER_CONST(L,CMD_SC_MOV);	
	REGISTER_CONST(L,CMD_SC_MOV_ARRI);				
	REGISTER_CONST(L,CMD_SC_MOV_FAILED);	
	//client <-> group
	REGISTER_CONST(L,CMD_CG_CREATE);	
	REGISTER_CONST(L,CMD_CG_ENTERMAP);
	REGISTER_CONST(L,CMD_GC_CREATE);		
	REGISTER_CONST(L,CMD_GC_BEGINPLY);	
	REGISTER_CONST(L,CMD_GC_ERROR);
	//gate <-> group
	REGISTER_CONST(L,CMD_AG_LOGIN);	
	REGISTER_CONST(L,CMD_AG_PLYLOGIN);		
	REGISTER_CONST(L,CMD_AG_CLIENT_DISCONN);	
	REGISTER_CONST(L,CMD_GA_NOTIFYGAME);
	REGISTER_CONST(L,CMD_GA_BUSY);	
	REGISTER_CONST(L,CMD_GA_PLY_INVAILD);	
	REGISTER_CONST(L,CMD_GA_CREATE);	
	//game <-> group
	REGISTER_CONST(L,CMD_GAMEG_LOGIN);
	REGISTER_CONST(L,CMD_GGAME_CLIDISCONNECTED);
	REGISTER_CONST(L,CMD_AGAME_LOGIN);	
	//REGISTER_CONST(L,CMD_AGAME_CLIENT_DISCONN);
	REGISTER_CONST(L,CMD_GAMEA_LOGINRET);
	//dummy cmd
	REGISTER_CONST(L,DUMMY_ON_GATE_DISCONNECTED);
	REGISTER_CONST(L,DUMMY_ON_GAME_DISCONNECTED);
	REGISTER_CONST(L,DUMMY_ON_CHAT_CONNECTED);
	REGISTER_CONST(L,DUMMY_ON_DAEMON_DISCONNECTED);	
	//rpc
	REGISTER_CONST(L,CMD_RPC_CALL);	
	REGISTER_CONST(L,CMD_RPC_RESPONSE);
	
	//end of netcmd
	REGISTER_CONST(L,LOG_INFO);	
	REGISTER_CONST(L,LOG_ERROR);

	
			
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
	REGISTER_FUNCTION("set_conn_type",&lua_set_conn_type);
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
