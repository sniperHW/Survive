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


static void on_disconnected(stream_conn_t conn,int err){
	int type = (int)stream_conn_getud(conn);
	if(type == GAMESERVER)
		process_cmd(DUMMY_ON_GAME_DISCONNECTED,conn,NULL);
	else if(type == GATESERVER)
		process_cmd(DUMMY_ON_GATE_DISCONNECTED,conn,NULL);
}


static int on_packet(stream_conn_t conn,packet_t pk){
	rpacket_t rpk = (rpacket_t)pk;
	uint16_t cmd = rpk_read_uint16(rpk);
	process_cmd(cmd,conn,rpk);
	return 1;
}


static void on_new_connection(handle_t s,void *_){
	stream_conn_t conn = new_stream_conn(s,65535,RPACKET);
	if(0 != stream_conn_associate(t_engine,conn,on_packet,on_disconnected))
		stream_conn_close(conn);
}

struct recon_ctx{
	handle_t     sock;
	kn_sockaddr  addr;
	void (*cb_connect)(handle_t,int,void*,kn_sockaddr*);
};

static int  cb_timer(kn_timer_t timer)//如果返回1继续注册，否则不再注册
{
	struct recon_ctx *recon = (struct recon_ctx*)kn_timer_getud(timer);
	kn_sock_connect(t_engine,recon->sock,&recon->addr,NULL,recon->cb_connect,NULL);
	free(recon);
	return 0;
}

//to chatserver
static stream_conn_t tochat = NULL;

static void cb_connect_chat(handle_t s,int err,void *ud,kn_sockaddr *addr);

static void on_chat_disconnected(stream_conn_t c,int err){
	tochat = NULL;
	struct recon_ctx *recon = calloc(1,sizeof(*recon));
	recon->sock = kn_new_sock(AF_INET,SOCK_STREAM,IPPROTO_TCP);
	recon->cb_connect = cb_connect_chat;
	recon->addr = *kn_sock_addrpeer(stream_conn_gethandle(c));
	kn_reg_timer(t_engine,5000,cb_timer,recon);	
}

static int on_chat_packet(stream_conn_t conn,packet_t pk){
	((void)conn);
	((void)pk);
	return 1;
}

static void cb_connect_chat(handle_t s,int err,void *ud,kn_sockaddr *addr)
{
	if(err == 0){
		//success
		tochat = new_stream_conn(s,65535,RPACKET);
		stream_conn_associate(t_engine,tochat,on_chat_packet,on_chat_disconnected);
		printf("connect to chat success\n");					
		process_cmd(DUMMY_ON_CHAT_CONNECTED,tochat,NULL);
	}else{
		//failed
		kn_close_sock(s);
		struct recon_ctx *recon = calloc(1,sizeof(*recon));
		recon->sock = kn_new_sock(AF_INET,SOCK_STREAM,IPPROTO_TCP);
		recon->addr = *addr;
		recon->cb_connect = cb_connect_chat;
		kn_reg_timer(t_engine,5000,cb_timer,recon);
	}
}

static int lua_send2chat(lua_State *L){
	wpacket_t wpk = lua_touserdata(L,1);
	if(0 == stream_conn_send(tochat,(packet_t)wpk))
		lua_pushboolean(L,1);
	else
		lua_pushboolean(L,0);
	return 1;	
}

//to mysql_proxy


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
	if(!lua_istable(L, -1)){
		lua_pop(L,1);
		lua_newtable(L);
		lua_pushvalue(L,-1);
		lua_setglobal(L,"GroupApp");
	}
	
	REGISTER_FUNCTION("reg_cmd_handler",&reg_cmd_handler);
	REGISTER_FUNCTION("grouplog",&lua_grouplog);
	REGISTER_FUNCTION("send2chat",&lua_send2chat);
	lua_pop(L,1);
}

//应由命令行传入
const char *db_config = "{\"deploydb\":{\"ip\":\"127.0.0.1\",\"port\":6379},\"1\":{\"ip\":\"127.0.0.1\",\"port\":6379}}";

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
	if((error = LuaCall1(L,"reghandler",1,lua_pushstring(L,db_config)))){
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
	kn_sockaddr local;
	kn_addr_init_in(&local,kn_to_cstr(g_config->listenip),g_config->listenport);	
	handle_t l = kn_new_sock(AF_INET,SOCK_STREAM,IPPROTO_TCP);
	if(0 != kn_sock_listen(t_engine,l,&local,on_new_connection,NULL)){
		printf("create server on ip[%s],port[%u] error\n",kn_to_cstr(g_config->listenip),g_config->listenport);
		LOG_GROUP(LOG_INFO,"create server on ip[%s],port[%u] error\n",kn_to_cstr(g_config->listenip),g_config->listenport);	
		exit(0);
	}
	/*{
		//connect chatserver
		kn_sockaddr addr;
		kn_addr_init_in(&addr,kn_to_cstr(g_config->chatip),g_config->chatport);
		handle_t sock = kn_new_sock(AF_INET,SOCK_STREAM,IPPROTO_TCP);
		kn_sock_connect(t_engine,sock,&addr,NULL,cb_connect_chat,NULL);
	}*/	
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
