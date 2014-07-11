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
__thread kn_proactor_t t_proactor = NULL;


static void process_cmd(uint16_t cmd,kn_stream_conn_t con,rpacket_t rpk){
	//printf("process_cmd:%d\n",cmd);
	if(handler[cmd]){
		lua_State *L = handler[cmd]->obj->L;
		const char *error = NULL;
		if((error = CALL_OBJ_FUNC2(handler[cmd]->obj,"handle",0,
						  lua_pushlightuserdata(L,rpk),
						  lua_pushlightuserdata(L,con)))){
			LOG_GROUP(LOG_INFO,"error on handle[%u]:%s\n",cmd,error);
			printf("error on handle[%u]:%s\n",cmd,error);
		}
	}else{
		printf("unknow cmd %d\n",cmd);
	}
}

static int on_game_packet(kn_stream_conn_t conn,rpacket_t rpk){
	uint16_t cmd = rpk_read_uint16(rpk);
	process_cmd(cmd,conn,rpk);
	return 1;
}

static void on_game_disconnected(kn_stream_conn_t conn,int err){
	process_cmd(DUMMY_ON_GAME_DISCONNECTED,conn,NULL);
}


static void on_new_game(kn_stream_server_t server,kn_stream_conn_t conn){
	if(0 == kn_stream_server_bind(server,conn,0,65536,
				      on_game_packet,on_game_disconnected,
				      0,NULL,0,NULL)){
	}else{
		kn_stream_conn_close(conn);
	}
}

static int on_gate_packet(kn_stream_conn_t conn,rpacket_t rpk){
	uint16_t cmd = rpk_read_uint16(rpk);
	process_cmd(cmd,conn,rpk);
	return 1;
}

static void on_gate_disconnected(kn_stream_conn_t conn,int err){
	process_cmd(DUMMY_ON_GATE_DISCONNECTED,conn,NULL);
}

static void on_new_gate(kn_stream_server_t server,kn_stream_conn_t conn){
	if(0 == kn_stream_server_bind(server,conn,0,65536,
				      on_gate_packet,on_gate_disconnected,
				      0,NULL,0,NULL)){
		printf("on_new_gate\n");
	}else{
		kn_stream_conn_close(conn);
	}

}


static volatile int stop = 0;
static void sig_int(int sig){
	stop = 1;
}

int reg_cmd_handler(lua_State *L){
	uint16_t cmd = lua_tonumber(L,1);
	luaObject_t obj = create_luaObj(L,2);
	if(!handler[cmd]){
		printf("reg cmd %d\n",cmd);
		cmd_handler_t h = calloc(1,sizeof(*h));
		h->_type = FN_LUA;
		h->obj = obj;
		handler[cmd] = h;
		lua_pushboolean(L,1);
	}else{
		release_luaObj(obj);
		lua_pushboolean(L,0);
	}
	return 1;
}

static int lua_grouplog(lua_State *L){
	int lev = lua_tonumber(L,1);
	const char *msg = lua_tostring(L,2);
	LOG_GROUP(lev,"%s",msg);
	return 0;
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

	lua_pushstring(L, "grouplog");
	lua_pushcfunction(L, lua_grouplog);
	lua_settable(L, -3);

	lua_pop(L,1);
}

static lua_State *init(){
	lua_State *L = luaL_newstate();
	luaL_openlibs(L);
	//注册C函数，常量到lua
	reg_common_c_function(L);

	//注册group特有的函数
	reg_group_c_function(L);
	
	if (luaL_dofile(L,"script/handler.lua")) {
		const char * error = lua_tostring(L, -1);
		lua_pop(L,1);
		LOG_GROUP(LOG_INFO,"error on handler.lua:%s\n",error);
		printf("error on handler.lua:%s\n",error);
		lua_close(L); 
		return NULL;
	}

	//注册lua消息处理器
	if(CALL_LUA_FUNC(L,"reghandler",1)){
		const char * error = lua_tostring(L, -1);
		lua_pop(L,1);
		LOG_GROUP(LOG_INFO,"error on reghandler:%s\n",error);
		printf("error on reghandler:%s\n",error);
		lua_close(L); 
	}
	
	if(!lua_toboolean(L,1)){
		LOG_GROUP(LOG_ERROR,"reghandler failed\n");
		printf("reghandler failed\n");
		return NULL;
	}
	return L;
}

int on_db_initfinish(lua_State *_){
	printf("on_db_initfinish\n");
	(void)_;
	//启动监听
	kn_sockaddr lgameserver;
	kn_addr_init_in(&lgameserver,kn_to_cstr(g_config->lgameip),g_config->lgameport);
	kn_new_stream_server(t_proactor,&lgameserver,on_new_game);

	kn_sockaddr lgateserver;
	kn_addr_init_in(&lgateserver,kn_to_cstr(g_config->lgateip),g_config->lgateport);
	kn_new_stream_server(t_proactor,&lgateserver,on_new_gate);
	
	return 0;
} 

int main(int argc,char **argv){
	signal(SIGPIPE,SIG_IGN);	
	if(loadconfig() != 0){
		return 0;
	}
	signal(SIGINT,sig_int);
	t_proactor = kn_new_proactor();	
	if(!init())
		return 0;
	while(!stop)
		kn_proactor_run(t_proactor,50);
	return 0;	
}
