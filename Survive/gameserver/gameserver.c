#include "kendynet.h"
#include "gameserver.h"
#include "config.h"
#include "lua_util.h"
#include "stream_conn.h"
#include "common/netcmd.h"
#include "common/cmdhandler.h"
#include "astar.h"
#include "aoi.h"
#include "common/common_c_function.h"

IMP_LOG(gamelog);

#define MAXCMD 65535
static cmd_handler_t handler[MAXCMD] = {NULL};

static stream_conn_t   togrp;

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


static int on_gate_packet(stream_conn_t conn,packet_t pk){
	rpacket_t rpk = (rpacket_t)pk;
	uint16_t cmd = rpk_read_uint16(rpk);	
	printf("gate_packet:%u\n",cmd);
	if(handler[cmd]){
		lua_State *L = handler[cmd]->obj->L;
		if(call_lua_handler(handler[cmd]->obj,cmd,conn,rpk)){
				const char *err = lua_tostring(L,1);
				lua_pop(L,1);
				LOG_GAME(LOG_INFO,"error on handle[%u]:%s\n",cmd,err);
				printf("error on handle[%u]:%s\n",cmd,err);				
		}
	}
	return 1;
}

static void on_gate_disconnected(stream_conn_t conn,int err){
	uint16_t cmd = DUMMY_ON_GATE_DISCONNECTED;
	if(handler[cmd]){
		lua_State *L = handler[cmd]->obj->L;
		if(call_lua_handler(handler[cmd]->obj,cmd,conn,NULL)){
				const char *err = lua_tostring(L,1);
				lua_pop(L,1);
				LOG_GAME(LOG_INFO,"error on handle[%u]:%s\n",cmd,err);
				printf("error on handle[%u]:%s\n",cmd,err);				
		}
	}
}


static void on_new_gate(handle_t s,void *_){
	stream_conn_t gate = new_stream_conn(s,65536,RPACKET);
	if(0 != stream_conn_associate(t_engine,gate,on_gate_packet,on_gate_disconnected))
		stream_conn_close(gate);
}


static int on_group_packet(stream_conn_t conn,packet_t pk){
	rpacket_t rpk = (rpacket_t)pk;
	uint16_t cmd = rpk_read_uint16(rpk);
	if(handler[cmd]){
		lua_State *L = handler[cmd]->obj->L;
		if(call_lua_handler(handler[cmd]->obj,cmd,conn,rpk)){
				const char *err = lua_tostring(L,1);
				lua_pop(L,1);
				LOG_GAME(LOG_INFO,"error on handle[%u]:%s\n",cmd,err);
				printf("error on handle[%u]:%s\n",cmd,err);				
		}
	}
	return 1;
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

static void cb_connect_group(handle_t s,int err,void *ud,kn_sockaddr *addr);
static void on_group_disconnected(stream_conn_t c,int err){
	togrp = NULL;
	struct recon_ctx *recon = calloc(1,sizeof(*recon));
	recon->sock = kn_new_sock(AF_INET,SOCK_STREAM,IPPROTO_TCP);
	recon->cb_connect = cb_connect_group;
	recon->addr = *kn_sock_addrpeer(stream_conn_gethandle(c));
	kn_reg_timer(t_engine,5000,cb_timer,recon);	
}

static void cb_connect_group(handle_t s,int err,void *ud,kn_sockaddr *addr)
{
	if(err == 0){
		//success
		stream_conn_t conn = new_stream_conn(s,65536,RPACKET);
		stream_conn_associate(t_engine,conn,on_group_packet,on_group_disconnected);		
		togrp = conn;		
		wpacket_t wpk = wpk_create(64);
		wpk_write_uint16(wpk,CMD_GAMEG_LOGIN);
		wpk_write_string(wpk,"game1");
		wpk_write_string(wpk,kn_to_cstr(g_config->lgateip));
		wpk_write_uint16(wpk,g_config->lgateport);
		stream_conn_send(conn,(packet_t)wpk);		
		printf("connect to group success\n");
	}else{
		kn_close_sock(s);
		//failed
		struct recon_ctx *recon = calloc(1,sizeof(*recon));
		recon->sock = kn_new_sock(AF_INET,SOCK_STREAM,IPPROTO_TCP);
		recon->addr = *addr;
		recon->cb_connect = cb_connect_group;
		kn_reg_timer(t_engine,5000,cb_timer,recon);
	}
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


static int lua_send2grp(lua_State *L){
	packet_t wpk = lua_touserdata(L,1);
	if(!togrp){
		destroy_packet(wpk);
	}else{
		stream_conn_send(togrp,wpk);
	}
	return 0;
}

static int lua_gamelog(lua_State *L){
	int lev = lua_tonumber(L,1);
	const char *msg = lua_tostring(L,2);
	LOG_GAME(lev,"%s",msg);
	return 0;
}

static uint8_t in_myscope(aoi_object *_self,aoi_object *_other){
	/*luaObject_t self = (luaObject_t)_self->ud;
	luaObject_t other = (luaObject_t)_other->ud;
	lua_State *L = self->L;
	const char *error = NULL;
	if((error = CALL_OBJ_FUNC1(self,"isInMyScope",1,
					  PUSH_LUAOBJECT(L,other)))){
		LOG_GAME(LOG_INFO,"error on enter_see:%s\n",error);
		return 0;
	}
	return lua_tonumber(L,1);*/
	//完全使用管理格判断可视性
	return 1;		
}

static void    cb_enter(aoi_object *_self,aoi_object *_other){
	luaTabRef_t* self = (luaTabRef_t*)_self->ud;
	luaTabRef_t* other = (luaTabRef_t*)_other->ud;
	lua_State *L = self->L;
	const char *error = NULL;
	if((error = CallLuaTabFunc1(NULL,*self,"enter_see",0,
					  PushLuaTabRef(L,*other)))){
		LOG_GAME(LOG_INFO,"error on enter_see:%s\n",error);
	}		
}

static void    cb_leave(aoi_object *_self,aoi_object *_other){
	luaTabRef_t* self = (luaTabRef_t*)_self->ud;
	luaTabRef_t* other = (luaTabRef_t*)_other->ud;
	lua_State *L = self->L;
	const char *error = NULL;
	if((error = CallLuaTabFunc1(NULL,*self,"leave_see",0,
					  PushLuaTabRef(L,*other)))){
		LOG_GAME(LOG_INFO,"error on leave_see:%s\n",error);
	}		
}

static int lua_create_aoi_obj(lua_State *L){
	luaTabRef_t *obj = calloc(1,sizeof(*obj));	
	*obj = create_luaTabRef(L,1);
	aoi_object* o = calloc(1,sizeof(*o));
	o->in_myscope = in_myscope;
	o->cb_enter = cb_enter;
	o->cb_leave = cb_leave;
	o->ud = obj;
	o->view_objs = new_bitset(4096);
	lua_pushlightuserdata(L,o);
	return 1;
}

static int lua_destroy_aoi_obj(lua_State *L){
	aoi_object* o = lua_touserdata(L,1);
	if(o->map) aoi_leave(o);
	del_bitset(o->view_objs);
	release_luaTabRef((luaTabRef_t*)o->ud);
	free(o->ud);
	free(o);
	return 0;
}

static int lua_create_aoimap(lua_State *L){
	uint32_t length = lua_tonumber(L,1);
	uint32_t radius = lua_tonumber(L,2);
	point2D  top_left,bottom_right;
	top_left.x = lua_tonumber(L,3);
	top_left.y = lua_tonumber(L,4);
	bottom_right.x = lua_tonumber(L,5);
	bottom_right.y = lua_tonumber(L,6);	
	aoi_map *m = aoi_create(4096,length,radius,&top_left,&bottom_right);
	lua_pushlightuserdata(L,(void*)m);
	return 1;
}

static int lua_destroy_aoimap(lua_State *L){
	aoi_map *m = lua_touserdata(L,1);
	aoi_destroy(m);
	return 0;
}

static int lua_aoi_enter(lua_State *L){
	aoi_map   * m = lua_touserdata(L,1);
	aoi_object* o = lua_touserdata(L,2);
	int x = (int)lua_tonumber(L,3);
	int y = (int)lua_tonumber(L,4);
	
	if(0 == aoi_enter(m,o,x,y))
		lua_pushboolean(L,1);
	else
		lua_pushboolean(L,0);
	return 1;	
}

static int lua_aoi_leave(lua_State *L){
	aoi_object* o = lua_touserdata(L,1);
	
	if(0 == aoi_leave(o))
		lua_pushboolean(L,1);
	else
		lua_pushboolean(L,0);
	return 1;		
}

static int lua_aoi_moveto(lua_State *L){
	aoi_object* o = lua_touserdata(L,1);
	int x = (int)lua_tonumber(L,2);
	int y = (int)lua_tonumber(L,3);	
	if(0 == aoi_moveto(o,x,y))
		lua_pushboolean(L,1);
	else
		lua_pushboolean(L,0);
	return 1;			
}

int readline(FILE * f, char *vptr, unsigned int maxlen){
	if(f == stdin){
		int c = 0;
		for(; c < maxlen; ++c)
		{
			vptr[c] = (char)getchar();
			if(vptr[c] == '\n'){
				vptr[c] = '\0';
				return c+1;
			}
		}
		vptr[maxlen-1] = '\0';
		return maxlen;
	}
	else{
		long curpos = ftell(f);
		int rc = fread(vptr,1,maxlen,f);
		if(rc > 0){
			int c = 0;
			for( ; c < rc; ++c){
				if(vptr[c] == '\n' && (unsigned int)c < maxlen-1){
					vptr[c] = '\0';
					fseek(f,curpos+c+1,SEEK_SET);
					return c+1;
				}
			}
			if((unsigned int)c < maxlen-1)
				vptr[c] = '\0';
			else
				vptr[maxlen-1] = '\0';
			return c;
		} 
		return 0;
	}
}

static int lua_create_astar(lua_State *L){
	const char *colifile = lua_tostring(L,1);
	int  xcount = lua_tonumber(L,2);
	int  ycount = lua_tonumber(L,3);
	
	FILE *f = fopen(colifile,"r");
	if(!f) 
		lua_pushnil(L);
	else{
		int* coli = calloc(1,xcount*ycount);
		char buf[1024];
		int size = xcount*ycount;
		int i = 0;
		for(; i < size; ++i){
			if(readline(f,buf,1024) == 0){
				free(coli);
				fclose(f);
				//输出提示
				lua_pushnil(L);
				return 1;
			}
			coli[i] = atol(buf);
		}
		AStar_t astar = create_AStar(xcount,ycount,coli);
		lua_pushlightuserdata(L,astar);
		free(coli);
		fclose(f);	
	}	
	return 1;
}

static int lua_findpath(lua_State *L){
	AStar_t astar = lua_touserdata(L,1);
	int x1 = lua_tonumber(L,2);
	int y1 = lua_tonumber(L,3);
	int x2 = lua_tonumber(L,4);
	int y2 = lua_tonumber(L,5);
	kn_dlist path;kn_dlist_init(&path);
	if(find_path(astar,x1,y1,x2,y2,&path)){
		int i = 1;
		lua_newtable(L);
		AStarNode *n;
		while((n = (AStarNode*)kn_dlist_pop(&path))){
			lua_newtable(L);
			lua_pushinteger(L,n->x);
			lua_rawseti(L,-2,1);
			lua_pushinteger(L,n->y);
			lua_rawseti(L,-2,2);
			lua_rawseti(L,-2,i++);	
		}
	}else
		lua_pushnil(L);
	return 1;
}

void reg_game_c_function(lua_State *L){
	lua_getglobal(L,"GameApp");
	if(!lua_istable(L, -1))
	{
		lua_pop(L,1);
		lua_newtable(L);
		lua_pushvalue(L,-1);
		lua_setglobal(L,"GameApp");
	}

	REGISTER_FUNCTION("create_astar",&lua_create_astar);
	REGISTER_FUNCTION("findpath",&lua_findpath);			
	REGISTER_FUNCTION("create_aoimap",&lua_create_aoimap);
	REGISTER_FUNCTION("destroy_aoimap",&lua_destroy_aoimap);			
	
	REGISTER_FUNCTION("create_aoi_obj",&lua_create_aoi_obj);
	REGISTER_FUNCTION("destroy_aoi_obj",&lua_destroy_aoi_obj);	
	REGISTER_FUNCTION("aoi_enter",&lua_aoi_enter);
	REGISTER_FUNCTION("aoi_leave",&lua_aoi_leave);		
	REGISTER_FUNCTION("aoi_moveto",&lua_aoi_moveto);		
	REGISTER_FUNCTION("send2grp",&lua_send2grp);		
	REGISTER_FUNCTION("gamelog",&lua_gamelog);


	lua_pop(L,1);
}

static lua_State *init(){
	lua_State *L = luaL_newstate();
	luaL_openlibs(L);
	//注册C函数，常量到lua
	reg_common_c_function(L);

	//注册group特有的函数
	reg_game_c_function(L);

	if (luaL_dofile(L,"script/handler.lua")) {
		const char * error = lua_tostring(L, -1);
		lua_pop(L,1);
		LOG_GAME(LOG_INFO,"error on handler.lua:%s\n",error);
		printf("error on handler.lua:%s\n",error);
		lua_close(L); 
		return NULL;
	}

	//注册lua消息处理器
	const char *error = NULL;
	if((error = LuaCall0(L,"reghandler",1))){
		LOG_GAME(LOG_INFO,"error on reghandler:%s\n",error);
		printf("error on handler.lua:%s\n",error);
		lua_close(L); 
	}
	
	int ret = lua_toboolean(L,1);
	lua_pop(L,1);
	if(!ret){
		LOG_GAME(LOG_ERROR,"reghandler failed\n");
		printf("reghandler failed\n");
		return NULL;
	}		
	
	return L;
}

static void sig_int(int sig){
	kn_stop_engine(t_engine);
}

int on_db_initfinish(lua_State *_){
	(void)_;
	printf("on_db_initfinish\n");
	//启动监听
	{
		kn_sockaddr gate_local;
		kn_addr_init_in(&gate_local,kn_to_cstr(g_config->lgateip),g_config->lgateport);	
		handle_t l = kn_new_sock(AF_INET,SOCK_STREAM,IPPROTO_TCP);
		if(0 != kn_sock_listen(t_engine,l,&gate_local,on_new_gate,NULL)){
			printf("create server on ip[%s],port[%u] error\n",kn_to_cstr(g_config->lgateip),g_config->lgateport);
			LOG_GAME(LOG_INFO,"create server on ip[%s],port[%u] error\n",kn_to_cstr(g_config->lgateip),g_config->lgateport);	
			exit(0);
		}
	}


	//连接group
	{
		kn_sockaddr group_addr;
		kn_addr_init_in(&group_addr,kn_to_cstr(g_config->groupip),g_config->groupport);	
		handle_t l = kn_new_sock(AF_INET,SOCK_STREAM,IPPROTO_TCP);
		kn_sock_connect(t_engine,l,&group_addr,NULL,cb_connect_group,NULL);		
	}
	return 0;
} 

int main(int argc,char **argv){
	signal(SIGPIPE,SIG_IGN);	
	signal(SIGINT,sig_int);
	t_engine = kn_new_engine();
	if(loadconfig() != 0){
		return 0;
	}
	if(!init())
		return 0;
	kn_engine_run(t_engine);
	return 0;	
}



