#include "kendynet.h"
#include "lua_util.h"
#include "stream_conn.h"
#include "common/netcmd.h"
#include "common/cmdhandler.h"
#include "common/common_c_function.h"


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


static int on_packet(stream_conn_t conn,packet_t pk){
	rpacket_t rpk = (rpacket_t)pk;
	uint16_t cmd = rpk_read_uint16(rpk);
	if(handler[cmd]){
		lua_State *L = handler[cmd]->obj->L;
		if(call_lua_handler(handler[cmd]->obj,cmd,conn,rpk)){
				const char *err = lua_tostring(L,1);
				lua_pop(L,1);				
		}
	}else{
		printf("unknow cmd %d\n",cmd);
	}
	return 1;
}

static void on_disconnected(stream_conn_t conn,int err){
	process_cmd(DUMMY_ON_DAEMON_DISCONNECTED,conn,NULL);
}


static void on_new_daemon(handle_t s,void *_){
	stream_conn_t daemon = new_stream_conn(s,65536,RPACKET);
	if(0 != stream_conn_associate(t_engine,daemon,on_packet,on_disconnected))
		stream_conn_close(daemon);
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


static lua_State *init(){
	lua_State *L = luaL_newstate();
	luaL_openlibs(L);
	reg_common_c_function(L);
	
	if (luaL_dofile(L,"script/handler.lua")) {
		const char * error = lua_tostring(L, -1);
		lua_pop(L,1);
		printf("error on handler.lua:%s\n",error);
		lua_close(L); 
		return NULL;
	}

	const char *error = NULL;
	if((error = LuaCall0(L,"reghandler",1))){
		printf("error on reghandler:%s\n",error);
		lua_close(L); 
	}
	
	int ret = lua_toboolean(L,1);
	lua_pop(L,1);
	if(!ret){
		printf("reghandler failed\n");
		return NULL;
	}
	return L;
}

int on_db_initfinish(lua_State *_){
	printf("on_db_initfinish\n");
	(void)_;
	
	//Æô¶¯¶ÔdaemonµÄ¼àÌý
	kn_sockaddr addr;
	kn_addr_init_in(&addr,"0.0.0.0",8888);	
	handle_t l = kn_new_sock(AF_INET,SOCK_STREAM,IPPROTO_TCP);
	if(0 != kn_sock_listen(t_engine,l,&addr,on_new_daemon,NULL)){
		printf("create server on ip[%s],port[%u] error\n","0.0.0.0",8888);
		exit(0);
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
