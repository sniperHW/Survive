#include "kendynet.h"
#include "gameserver.h"
#include "config.h"
#include "lua/lua_util.h"
#include "kn_stream_conn_server.h"
#include "kn_stream_conn_client.h"
#include "common/netcmd.h"
#include "common/cmdhandler.h"
#include "astar.h"
#include "aoi.h"
#include "common/common_c_function.h"

IMP_LOG(gamelog);

#define MAXCMD 65535
static cmd_handler_t handler[MAXCMD] = {NULL};

static kn_stream_client_t c;
static kn_stream_conn_t   togrp;

__thread kn_proactor_t t_proactor = NULL;

static int on_gate_packet(kn_stream_conn_t conn,rpacket_t rpk){
	uint16_t cmd = rpk_read_uint16(rpk);	
	if(handler[cmd]){
		lua_State *L = handler[cmd]->obj->L;
		const char *error = NULL;
		if((error = CALL_OBJ_FUNC2(handler[cmd]->obj,"handle",0,
						  lua_pushlightuserdata(L,rpk),
						  lua_pushlightuserdata(L,conn)))){
			LOG_GAME(LOG_INFO,"error on handle[%u]:%s\n",cmd,error);
			printf("error on handle[%u]:%s\n",cmd,error);
		}
	}
	return 1;
}

static void on_gate_disconnected(kn_stream_conn_t conn,int err){
	uint16_t cmd = DUMMY_ON_GATE_DISCONNECTED;
	if(handler[cmd]){
		lua_State *L = handler[cmd]->obj->L;
		const char *error = NULL;
		if((error = CALL_OBJ_FUNC2(handler[cmd]->obj,"handle",0,
						  lua_pushnil(L),lua_pushlightuserdata(L,conn)))){
			LOG_GAME(LOG_INFO,"error on handle[%u]:%s\n",cmd,error);
		}
	}	
}

static void on_new_gate(kn_stream_server_t server,kn_stream_conn_t conn){
	if(0 == kn_stream_server_bind(server,conn,0,65536,
				      on_gate_packet,on_gate_disconnected,
				      0,NULL,0,NULL)){
	}else{
		kn_stream_conn_close(conn);
	}
}


static int on_group_packet(kn_stream_conn_t con,rpacket_t rpk){
	uint16_t cmd = rpk_read_uint16(rpk);
	if(handler[cmd]){
		lua_State *L = handler[cmd]->obj->L;
		const char *error = NULL;
		if((error = CALL_OBJ_FUNC2(handler[cmd]->obj,"handle",0,
						  lua_pushlightuserdata(L,rpk),
						  lua_pushlightuserdata(L,con)))){
			LOG_GAME(LOG_INFO,"error on handle[%u]:%s\n",cmd,error);
			printf("error on handle[%u]:%s\n",cmd,error);
		}
	}
	return 1;
}


static int  cb_timer(kn_timer_t timer)//如果返回1继续注册，否则不再注册
{
	kn_sockaddr grpaddr;
	kn_addr_init_in(&grpaddr,kn_to_cstr(g_config->groupip),g_config->groupport);		
	kn_stream_connect(c,NULL,&grpaddr,NULL);
	free(timer);
	return 0;
}

static void on_group_connect_failed(kn_stream_client_t _,kn_sockaddr *addr,int err,void *ud)
{
	(void)_;
	(void)addr;
	(void)err;
	(void)ud;
	kn_reg_timer(t_proactor,5000,cb_timer,NULL);
	printf("connect to group failed,retry after 5 sec\n");
}

static void on_group_disconnected(kn_stream_conn_t conn,int err){
	(void)conn;
	(void)err; 
	togrp = NULL;
	kn_reg_timer(t_proactor,5000,cb_timer,NULL);	
}

static void on_group_connect(kn_stream_client_t _,kn_stream_conn_t conn,void *ud){
	(void)_;
	if(0 == kn_stream_client_bind(c,conn,0,65536,on_group_packet,on_group_disconnected,
						  0,NULL,0,NULL)){	
		togrp = conn;		
		wpacket_t wpk = NEW_WPK(64);
		wpk_write_uint16(wpk,CMD_GAMEG_LOGIN);
		wpk_write_string(wpk,"game1");
		wpk_write_string(wpk,kn_to_cstr(g_config->lgateip));
		wpk_write_uint16(wpk,g_config->lgateport);
		kn_stream_conn_send(conn,wpk);		
		printf("connect to group success\n");
	}else{
		kn_stream_conn_close(conn);		
		LOG_GAME(LOG_ERROR,"on_group_connect failed\n");
	}
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


static int lua_send2grp(lua_State *L){
	wpacket_t wpk = lua_touserdata(L,1);
	if(!togrp){
		wpk_destroy(wpk);
	}else{
		kn_stream_conn_send(togrp,wpk);
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
	luaObject_t self = (luaObject_t)_self->ud;
	luaObject_t other = (luaObject_t)_other->ud;
	lua_State *L = self->L;
	const char *error = NULL;
	if((error = CALL_OBJ_FUNC1(self,"enter_see",0,
					  PUSH_LUAOBJECT(L,other)))){
		LOG_GAME(LOG_INFO,"error on enter_see:%s\n",error);
	}		
}

static void    cb_leave(aoi_object *_self,aoi_object *_other){
	luaObject_t self = (luaObject_t)_self->ud;
	luaObject_t other = (luaObject_t)_other->ud;
	lua_State *L = self->L;
	const char *error = NULL;
	if((error = CALL_OBJ_FUNC1(self,"leave_see",0,
					  PUSH_LUAOBJECT(L,other)))){
		LOG_GAME(LOG_INFO,"error on leave_see:%s\n",error);
	}		
}

static int lua_create_aoi_obj(lua_State *L){
	luaObject_t obj = create_luaObj(L,1);
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
	if(o->map) aoi_leave(o->map,o);
	del_bitset(o->view_objs);
	release_luaObj((luaObject_t)o->ud);
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
	aoi_map *m = lua_touserdata(L,2);
	aoi_destroy(m);
	return 0;
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
					fseek(f,curpos+c+2,SEEK_SET);
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
		lua_newtable(L);
		AStarNode *n;
		while((n = (AStarNode*)kn_dlist_pop(&path))){
			lua_newtable(L);
			lua_pushinteger(L,n->x);
			lua_rawseti(L,-2,1);
			lua_pushinteger(L,n->y);
			lua_rawseti(L,-2,2);
		}
		lua_rawseti(L,-2,1);	
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
		
	lua_pushstring(L, "create_astar");
	lua_pushcfunction(L, &lua_create_astar);
	lua_settable(L, -3);		
	
	lua_pushstring(L, "findpath");
	lua_pushcfunction(L, &lua_findpath);
	lua_settable(L, -3);	
	
	lua_pushstring(L, "create_aoimap");
	lua_pushcfunction(L, &lua_create_aoimap);
	lua_settable(L, -3);	
	
	lua_pushstring(L, "destroy_aoimap");
	lua_pushcfunction(L, &lua_destroy_aoimap);
	lua_settable(L, -3);	
	
	lua_pushstring(L, "create_aoi_obj");
	lua_pushcfunction(L, &lua_create_aoi_obj);
	lua_settable(L, -3);
	
	lua_pushstring(L, "destroy_aoi_obj");
	lua_pushcfunction(L, &lua_destroy_aoi_obj);
	lua_settable(L, -3);		

	lua_pushstring(L, "send2grp");
	lua_pushcfunction(L, &lua_send2grp);
	lua_settable(L, -3);

	lua_pushstring(L, "gamelog");
	lua_pushcfunction(L, lua_gamelog);
	lua_settable(L, -3);

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
	if(CALL_LUA_FUNC(L,"reghandler",0)){
		const char * error = lua_tostring(L, -1);
		lua_pop(L,1);
		LOG_GAME(LOG_INFO,"error on reghandler:%s\n",error);
		printf("error on handler.lua:%s\n",error);
		lua_close(L); 
	}
	return L;
}

static volatile int stop = 0;
static void sig_int(int sig){
	stop = 1;
}

int on_db_initfinish(lua_State *_){
	(void)_;
	printf("on_db_initfinish\n");
	//启动监听
	kn_sockaddr lgateserver;
	kn_addr_init_in(&lgateserver,kn_to_cstr(g_config->lgateip),g_config->lgateport);
	kn_new_stream_server(t_proactor,&lgateserver,on_new_gate);

	//连接group
	c = kn_new_stream_client(t_proactor,
			on_group_connect,
			on_group_connect_failed);

	kn_sockaddr grpaddr;
	kn_addr_init_in(&grpaddr,kn_to_cstr(g_config->groupip),g_config->groupport);
	kn_stream_connect(c,NULL,&grpaddr,NULL);
	return 0;
} 

int main(int argc,char **argv){
	signal(SIGINT,sig_int);
	t_proactor = kn_new_proactor();
	if(loadconfig() != 0){
		return 0;
	}

	if(!init())
		return 0;

	while(!stop)
		kn_proactor_run(t_proactor,50);

	return 0;	
}



