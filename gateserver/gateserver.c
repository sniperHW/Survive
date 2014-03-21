#include "agentservice/agentservice.h"
#include "togame/togame.h"
#include "verifyservice/verifyservice.h"
#include "core/lua_util.h"
#include "core/kn_string.h"
#include "core/log.h"

extern string_t g_gameip;
extern int32_t  g_gameport;

extern string_t g_redisip;
extern int32_t  g_redisport;

static volatile uint8_t stop = 0;

static int agentcount = 0;

static void stop_handler(int signo){
    stop = 1;
}

static void setup_signal_handler()
{
	struct sigaction act;
    bzero(&act, sizeof(act));
    act.sa_handler = stop_handler;
    sigaction(SIGINT, &act, NULL);
    sigaction(SIGTERM, &act, NULL);
}

static void agent_connect(msgdisp_t disp,sock_ident sock,const char *ip,int32_t port)
{
	disp->bind(g_agents[rand()%agentcount]->msgdisp,0,sock,4096,0,30*1000,0);//由系统选择poller
}

int main(){

	lua_State *L = luaL_newstate();
	luaL_openlibs(L);
	if (luaL_dofile(L,"gateconfig.lua")) {
		const char * error = lua_tostring(L, -1);
		lua_pop(L,1);
		printf("%s\n",error);
		return 0;
	}
		
	luaObject_t gatecfg = GETGLOBAL_OBJECT(L,"gateserver");
	agentcount = GET_OBJ_FIELD(gatecfg,"agentservice_count",int,lua_tonumber);
	release_luaObj(gatecfg);
	
	luaObject_t toclicfg = GETGLOBAL_OBJECT(L,"toclient");
	string_t cliip = new_string(GET_OBJ_FIELD(toclicfg,"ip",const char *,lua_tostring));
	int      cliport = GET_OBJ_FIELD(toclicfg,"port",int,lua_tonumber);
	release_luaObj(toclicfg);
	
	luaObject_t togamecfg = GETGLOBAL_OBJECT(L,"togame");
	g_gameip = new_string(GET_OBJ_FIELD(togamecfg,"ip",const char *,lua_tostring));
	g_gameport = GET_OBJ_FIELD(togamecfg,"port",int,lua_tonumber);
	release_luaObj(togamecfg);
	
	luaObject_t torediscfg = GETGLOBAL_OBJECT(L,"toredis");
	g_redisip = new_string(GET_OBJ_FIELD(torediscfg,"ip",const char *,lua_tostring));
	g_redisport = GET_OBJ_FIELD(torediscfg,"port",int,lua_tonumber);
	release_luaObj(torediscfg);
	
	lua_close(L);
	
	InitNetSystem();
	
	
	//两个poller,一个用于accept,一个用于数据传输
	asynnet_t asynet = asynnet_new(2);
	
	if(start_verifyservice() != 0){
		SYS_LOG(LOG_ERROR,"start verifyservice failed\n");
		return 0;
	}
	
	if(start_togame_service(asynet) != 0){
		SYS_LOG(LOG_ERROR,"start togame service failed\n");
		return 0;
	}
		
	uint8_t i;
	for(i = 0; i < agentcount; ++i){
		g_agents[i] = new_agentservice(i,asynet);
	}
	
	msgdisp_t listener = new_msgdisp(asynet,1,CB_CONNECT(agent_connect));
	//开启对客户端的监听	
	int32_t err = 0;
	listener->listen(listener,0,to_cstr(cliip),cliport,&err);
	if(err != 0)
	{
		SYS_LOG(LOG_ERROR,"start listen failed:%d\n",err);
		return 0;
	}
	setup_signal_handler();	    
    while(!stop){
        msg_loop(listener,500);
    }
    
	stop_togame_service();
	stop_verifyservice();
	
	for(i = 0; i < agentcount; ++i){
		stop_agentservice(g_agents[i]);
	}		

	return 0;
}
