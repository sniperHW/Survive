#include "kendynet.h"
#include "groupserver.h"
#include "config.h"
#include "lua_util.h"
#include "stream_conn.h"
#include "common/netcmd.h"
#include "common/cmdhandler.h"
#include "common/common_c_function.h"

IMP_LOG(grouplog);

#define MAXCMD 65535
static cmd_handler_t handler[MAXCMD] = {NULL};
__thread engine_t t_engine = NULL;

static inline int call_lua_handler(luaTabRef_t *obj,uint16_t cmd,stream_conn_t conn,rpacket_t rpk){
		lua_State *L = obj->L;
		//get lua handle function
		lua_rawgeti(L,LUA_REGISTRYINDEX, obj->rindex);
		lua_pushinteger(L,cmd);
		lua_gettable(L,-2);
		lua_remove(L,-2);		
		//push arg
		if(rpk) 
			lua_pushlightuserdata(L,rpk);
		else 
			lua_pushnil(L);
		if(conn) 
			lua_pushlightuserdata(L,conn);
		else
			lua_pushnil(L);
		return lua_pcall(L,2,0,0);
}


static void process_cmd(uint16_t cmd,stream_conn_t conn,rpacket_t rpk){
	//printf("process_cmd:%d\n",cmd);
	if(handler[cmd]){
		lua_State *L = handler[cmd]->obj->L;
		if(call_lua_handler(handler[cmd]->obj,cmd,conn,rpk)){
				const char *err = lua_tostring(L,1);
				lua_pop(L,1);
				LOG_GROUP(LOG_INFO,"error on handle[%u]:%s\n",cmd,err);
				printf("error on handle[%u]:%s\n",cmd,err);				
		}
	}else{
		printf("unknow cmd %d\n",cmd);
	}
}

static int on_game_packet(stream_conn_t conn,packet_t pk){
	rpacket_t rpk = (rpacket_t)pk;
	uint16_t cmd = rpk_read_uint16(rpk);
	process_cmd(cmd,conn,rpk);
	return 1;
}

static void on_game_disconnected(stream_conn_t conn,int err){
	process_cmd(DUMMY_ON_GAME_DISCONNECTED,conn,NULL);
}


static void on_new_game(handle_t s,void *_){
	stream_conn_t game = new_stream_conn(s,65536,RPACKET);
	if(0 != stream_conn_associate(t_engine,game,on_game_packet,on_game_disconnected))
		stream_conn_close(game);
}

static int on_gate_packet(stream_conn_t conn,packet_t pk){
	rpacket_t rpk = (rpacket_t)pk;
	uint16_t cmd = rpk_read_uint16(rpk);
	process_cmd(cmd,conn,rpk);
	return 1;
}

static void on_gate_disconnected(stream_conn_t conn,int err){
	process_cmd(DUMMY_ON_GATE_DISCONNECTED,conn,NULL);
}


static void on_new_gate(handle_t s,void *_){
	stream_conn_t gate = new_stream_conn(s,65536,RPACKET);
	if(0 != stream_conn_associate(t_engine,gate,on_gate_packet,on_gate_disconnected))
		stream_conn_close(gate);
}

static void sig_int(int sig){
	kn_stop_engine(t_engine);
}

int reg_cmd_handler(lua_State *L){
	uint16_t cmd = lua_tonumber(L,1);
	luaTabRef_t obj = create_luaTabRef(L,2);
	if(!handler[cmd]){
		printf("reg cmd %d\n",cmd);
		cmd_handler_t h = calloc(1,sizeof(*h));
		h->_type = FN_LUA;
		h->obj = calloc(1,sizeof(*h->obj));
		*h->obj = obj;
		handler[cmd] = h;
		lua_pushboolean(L,1);
	}else{
		release_luaTabRef(&obj);
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
	
	REGISTER_FUNCTION("reg_cmd_handler",&reg_cmd_handler);
	REGISTER_FUNCTION("grouplog",&lua_grouplog);			

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
	const char *error = NULL;
	if((error = LuaCall0(L,"reghandler",1))){
		LOG_GROUP(LOG_INFO,"error on reghandler:%s\n",error);
		printf("error on reghandler:%s\n",error);
		lua_close(L); 
	}
	
	int ret = lua_toboolean(L,1);
	lua_pop(L,1);
	if(!ret){
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
	{
		//监听gameserver的连接
		kn_sockaddr game_local;
		kn_addr_init_in(&game_local,kn_to_cstr(g_config->lgameip),g_config->lgameport);	
		handle_t l = kn_new_sock(AF_INET,SOCK_STREAM,IPPROTO_TCP);
		if(0 != kn_sock_listen(t_engine,l,&game_local,on_new_game,NULL)){
			printf("create server on ip[%s],port[%u] error\n",kn_to_cstr(g_config->lgameip),g_config->lgameport);
			LOG_GROUP(LOG_INFO,"create server on ip[%s],port[%u] error\n",kn_to_cstr(g_config->lgameip),g_config->lgameport);	
			exit(0);
		}
	}
	
	{
		//监听gateserver的连接		
		kn_sockaddr gate_local;
		kn_addr_init_in(&gate_local,kn_to_cstr(g_config->lgateip),g_config->lgateport);	
		handle_t l = kn_new_sock(AF_INET,SOCK_STREAM,IPPROTO_TCP);
		if(0 != kn_sock_listen(t_engine,l,&gate_local,on_new_gate,NULL)){
			printf("create server on ip[%s],port[%u] error\n",kn_to_cstr(g_config->lgateip),g_config->lgateport);
			LOG_GROUP(LOG_INFO,"create server on ip[%s],port[%u] error\n",kn_to_cstr(g_config->lgateip),g_config->lgateport);	
			exit(0);
		}
	}	
	return 0;
} 

int main(int argc,char **argv){
	signal(SIGPIPE,SIG_IGN);	
	if(loadconfig() != 0){
		return 0;
	}
	signal(SIGINT,sig_int);
	t_engine = kn_new_engine();	
	if(!init())
		return 0;
	kn_engine_run(t_engine);
	return 0;	
}
