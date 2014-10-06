#include "lua_util.h"
#include "kendynet.h"
#include "log.h"
#include "kn_redis.h"

//redis
static engine_t g_engine;

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
	if(0 != kn_redisAsynConnect(g_engine,ip,port,lua_on_redis_connected,
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
