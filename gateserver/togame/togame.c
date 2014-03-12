#include "togame.h"
#include "common/cmd.h"
#include "common/agentsession.h"
#include "core/kn_string.h"
#include "agentservice/agentservice.h"

static toGame_t g_togame = NULL;
static string_t g_gameip = NULL;
static int32_t  g_gameport = 0;



void send2game(wpacket_t wpk)
{
	asyn_send(g_togame->togame,wpk);
}

agentservice_t get_agent_byindex(uint8_t);

int32_t togame_processpacket(msgdisp_t disp,rpacket_t rpk)
{
	uint16_t cmd = rpk_peek_uint16(rpk);
	if(cmd >= CMD_GAME2C && cmd < CMD_GAME2C_END){
		if(cmd == CMD_GAME2GATE_BUSY){
			agentsession session;
			session.data = reverse_read_uint32(rpk);
			agentservice_t agent = get_agent_byindex(session.aid);
			if(agent){
				if(0 == send_msg(NULL,agent->msgdisp,(msg_t)rpk))
					return 0;
			}
		}else{
		
		}
	}
	return 1;
}

static void togame_connect(msgdisp_t disp,sock_ident sock,const char *ip,int32_t port)
{
	disp->bind(disp,0,sock,65536,0,180*1000,0);//由系统选择poller
}

static void togame_connected(msgdisp_t disp,sock_ident sock,const char *ip,int32_t port)
{
	g_togame->togame = sock;
}

static void togame_disconnected(msgdisp_t disp,sock_ident sock,const char *ip,int32_t port,uint32_t err)
{
	MAKE_EMPTY_IDENT(g_togame->togame);
}

static void togame_connect_failed(msgdisp_t disp,const char *ip,int32_t port,uint32_t reason)
{
	//再次发起连接尝试
	g_togame->msgdisp->connect(g_togame->msgdisp,0,to_cstr(g_gameip),g_gameport,30*1000);
}

static void *service_main(void *ud){
    toGame_t service = (toGame_t)ud;
    while(!service->stop){
        msg_loop(service->msgdisp,50);
    }
    return NULL;
}


int32_t start_togame_service(asynnet_t asynet){
	//读取配置文件
	g_togame = calloc(1,sizeof(*g_togame));
	g_togame->msgdisp = new_msgdisp(asynet,5,
								   CB_CONNECT(togame_connect),
                                   CB_CONNECTED(togame_connected),
                                   CB_DISCNT(togame_disconnected),
                                   CB_PROCESSPACKET(togame_processpacket),
                                   CB_CONNECTFAILED(togame_connect_failed)
                                   );
	g_togame->thd = create_thread(THREAD_JOINABLE); 
	thread_start_run(g_togame->thd,service_main,(void*)g_togame);
	g_togame->msgdisp->connect(g_togame->msgdisp,0,to_cstr(g_gameip),g_gameport,30*1000);
	return 0;
}

void stop_togame_service(){
	g_togame->stop = 1;
	thread_join(g_togame->thd);
}
