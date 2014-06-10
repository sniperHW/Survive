#include "kendynet.h"
#include "groupserver.h"
#include "config.h"
#include "lua/lua_util.h"
#include "kn_stream_conn_server.h"
#include "common/netcmd.h"
#include "common/cmdhandler.h"
#include "common/common_c_function.h"

IMP_LOG(grouplog);

#define MAXCMD 65535
static cmd_handler_t handler[MAXCMD] = {NULL};

static int on_game_packet(kn_stream_conn_t con,rpacket_t rpk){
	uint16_t cmd = rpk_read_uint16(rpk);
	if(handler[cmd]){
		lua_State *L = handler[cmd]->obj->L;
		if(CALL_OBJ_FUNC2(handler[cmd]->obj,"handle",0,
						  lua_pushlightuserdata(L,rpk),
						  lua_pushlightuserdata(L,con))){
			const char * error = lua_tostring(L, -1);
			lua_pop(L,1);
			LOG_GROUP(LOG_INFO,"error on handle[%u]:%s\n",cmd,error);
		}
	}
	return 1;
}

static void on_game_disconnected(kn_stream_conn_t conn,int err){

}


static void on_new_game(kn_stream_server_t server,kn_stream_conn_t conn){
	if(0 == kn_stream_server_bind(server,conn,0,65536,
				      on_game_packet,on_game_disconnected,
				      30*1000,NULL,0,NULL)){
	}else{
		kn_stream_conn_close(conn);
	}
}

static int on_gate_packet(kn_stream_conn_t con,rpacket_t rpk){
	uint16_t cmd = rpk_read_uint16(rpk);
	if(handler[cmd]){
		lua_State *L = handler[cmd]->obj->L;
		if(CALL_OBJ_FUNC2(handler[cmd]->obj,"handle",0,
						  lua_pushlightuserdata(L,rpk),
						  lua_pushlightuserdata(L,con))){
			const char * error = lua_tostring(L, -1);
			lua_pop(L,1);
			LOG_GROUP(LOG_INFO,"error on handle[%u]:%s\n",cmd,error);
		}
	}
	return 1;
}

static void on_gate_disconnected(kn_stream_conn_t conn,int err){

}

static void on_new_gate(kn_stream_server_t server,kn_stream_conn_t conn){
	if(0 == kn_stream_server_bind(server,conn,0,65536,
				      on_gate_packet,on_gate_disconnected,
				      30*1000,NULL,0,NULL)){
	}else{
		kn_stream_conn_close(conn);
	}

}


static volatile int stop = 0;
static void sig_int(int sig){
	stop = 1;
}

static int reg_cmd_handler(lua_State *L){
	uint16_t cmd = lua_tonumber(L,1);
	luaObject_t obj = create_luaObj(L,2);
	if(!handler[cmd]){
		cmd_handler_t h = calloc(1,sizeof(*handler));
		h->obj = obj;
		handler[cmd] = h;
		lua_pushboolean(L,1);
	}else{
		release_luaObj(obj);
		lua_pushboolean(L,0);
	}
	return 1;
}

void reg_group_c_function(lua_State *L){
	lua_getglobal(L,"GroupApp");
	if(!lua_istable(L, -1))
	{
		lua_pop(L,1);
		lua_newtable(L);
		lua_pushvalue(L,-1);
		lua_setglobal(L,"GroupApp");
	}

	lua_pushstring(L, "reg_cmd_handler");
	lua_pushcfunction(L, reg_cmd_handler);
	lua_settable(L, -3);

	lua_pop(L,1);
}

static lua_State *init(){
	lua_State *L = luaL_newstate();
	luaL_openlibs(L);
	if (luaL_dofile(L,"script/handler.lua")) {
		const char * error = lua_tostring(L, -1);
		lua_pop(L,1);
		LOG_GROUP(LOG_INFO,"error on handler.lua:%s\n",error);
		lua_close(L); 
		return NULL;
	}
	//注册C函数，常量到lua
	reg_common_c_function(L);

	//注册group特有的函数
	reg_group_c_function(L);

	//注册lua消息处理器
	if(CALL_LUA_FUNC(L,"reghandler",0)){
		const char * error = lua_tostring(L, -1);
		lua_pop(L,1);
		LOG_GROUP(LOG_INFO,"error on reghandler:%s\n",error);
		lua_close(L); 
	}
	return L;
}

int main(int argc,char **argv){

	if(loadconfig() != 0){
		return 0;
	}

	if(!init())
		return 0;

	signal(SIGINT,sig_int);
	kn_proactor_t p = kn_new_proactor();
	//启动监听
	kn_sockaddr lgameserver;
	kn_addr_init_in(&lgameserver,kn_to_cstr(g_config->lgameip),g_config->lgameport);
	kn_new_stream_server(p,&lgameserver,on_new_game);

	kn_sockaddr lgateserver;
	kn_addr_init_in(&lgateserver,kn_to_cstr(g_config->lgateip),g_config->lgateport);
	kn_new_stream_server(p,&lgateserver,on_new_gate);

	while(!stop)
		kn_proactor_run(p,50);

	return 0;	
}
