#include "agentservice.h"
#include "core/tls.h"
#include "togame/togame.h"
#include "common/tls_define.h"
#include "common/cmd.h"
#include "verifyservice/verifyservice.h"

static void *service_main(void *ud){
    agentservice_t service = (agentservice_t)ud;
    tls_set(MSGDISCP_TLS,(void*)service->msgdisp);
    tls_set(AGETNSERVICE_TLS,(void*)service);
    while(!service->stop){
        msg_loop(service->msgdisp,50);
    }
    return NULL;
}


agentplayer_t new_agentplayer(sock_ident sock)
{
	agentservice_t service = get_thd_agentservice();
	int32_t id = get_id(service->_idmgr);
	if(id == -1)
		return NULL;
	agentplayer_t player = &service->players[id];
	player->session.aid = service->agentid;
	player->session.identity = service->identity;
	player->session.sessionid = (uint16_t)id;
	player->state = agent_init;
	player->con = sock;
	return player;
}

void release_agentplayer(agentplayer_t player)
{
	agentservice_t service = get_thd_agentservice();
	release_id(service->_idmgr,(int32_t)player->session.sessionid);
	player->session.data = 0;
	player->state = agent_unusing;
}

agentplayer_t get_agentplayer(agentsession session)
{
	agentservice_t service = get_thd_agentservice();
	agentplayer_t ply = &service->players[session.sessionid];
	if(ply->session.data != session.data) return NULL;
	if(ply->state == agent_unusing) return NULL;
	return ply;
}

void send2player(agentplayer_t ply,wpacket_t wpk)
{
	asyn_send(ply->con,wpk);
}


static void agent_connect(msgdisp_t disp,sock_ident sock,const char *ip,int32_t port)
{
	agentplayer_t ply = new_agentplayer(sock);
	if(!ply)
	{
		//关闭连接
		asynsock_close(sock);
	}else
	{
		agentservice_t service = get_thd_agentservice();
		asynsock_set_ud(sock,(void*)ply->session.data);
		service->msgdisp->bind(service->msgdisp,0,sock,4096,0,30*1000,0);//由系统选择poller
	}
}

static void agent_disconnected(msgdisp_t disp,sock_ident sock,const char *ip,int32_t port,uint32_t err)
{
	//agentservice_t service = get_thd_agentservice();
	agentsession session;
	session.data = (uint32_t)asynsock_get_ud(sock);
	agentplayer_t ply = get_agentplayer(session);
	if(ply){
		if(ply->state == agent_playing || ply->state == agent_creating){
			//通知gameserver玩家连接断开
			wpacket_t wpk = wpk_create(64,0);
			wpk_write_uint16(wpk,CMD_GATE2GAME_CDISCONNECT);
			send2game(wpk);
		}
		release_agentplayer(ply);
	}
}

#define GET_AGENT_PLAYER\
		agentsession session;\
		session.data = (uint32_t)asynsock_get_ud(sock);\
		agentplayer_t ply = get_agentplayer(session)


struct logincall_context{
    asyncall_context base_context;
    agentsession     session;
    string_t         acctname;
    string_t         passwd;    
};

void login_result(struct asyncall_context *_context,void *result)
{
	struct logincall_context *context = (struct logincall_context*)_context;
	if(result != NULL){
		//验证成功，发送消息到game,请求调入角色信息
		wpacket_t wpk = wpk_create(64,0);
		wpk_write_uint16(wpk,CMD_GATE2GAME_LOGIN);
		wpk_write_uint32(wpk,context->session.data);
		wpk_write_string(wpk,to_cstr(context->acctname));
		send2game(wpk);
	}else{
		//验证失败
		agentplayer_t ply = get_agentplayer(context->session);
		if(ply){
			wpacket_t wpk = wpk_create(64,0);
			wpk_write_uint16(wpk,CMD_GATE2C_VERIFY_FAILED);
			send2player(ply,wpk);
		}
	}
	release_string(context->acctname);
	release_string(context->passwd);
	free(context);	
}
		

static void agent_cmd_login(rpacket_t rpk)
{
	sock_ident sock = TO_SOCK(MSG_IDENT(rpk));
	GET_AGENT_PLAYER;
	if(ply){
		const char *acctname = rpk_read_string(rpk);
		const char *passwd =   rpk_read_string(rpk);		
		struct logincall_context *lcontext = calloc(1,sizeof(*lcontext));
		lcontext->session = session;
		lcontext->acctname = new_string(acctname);
		lcontext->passwd = new_string(passwd);
		if(0 != verify_login((asyncall_context_t)lcontext,login_result,lcontext->acctname,lcontext->passwd))
		{
			//通知用户登录系统故障，断开连接
			asynsock_close(sock);
		}			
	}
}

static void agent_cmd_create(rpacket_t rpk)
{
	sock_ident sock = TO_SOCK(MSG_IDENT(rpk));
	GET_AGENT_PLAYER;
	if(ply){
		
	}	
}

static inline void agent_game_busy(rpacket_t rpk)
{
	rpk_read_uint16(rpk);//丢掉命令码
	agentsession session;
	session.data = rpk_read_uint32(rpk);
	agentplayer_t ply = get_agentplayer(session);
	if(ply){
		wpacket_t wpk = wpk_create(64,0);
		wpk_write_uint16(wpk,CMD_GATE2C_BUSY);
		send2player(ply,wpk);
		asynsock_close(ply->con);
	}	
}


int32_t agent_processpacket(msgdisp_t disp,rpacket_t rpk)
{
	uint16_t cmd = rpk_peek_uint16(rpk);
	if(cmd >= CMD_C2GATE && cmd < CMD_C2GATE_END){
		rpk_read_uint16(rpk);//丢掉命令码
		if(cmd == CMD_C2GATE_LOGIN)
			agent_cmd_login(rpk);
		else if(cmd == CMD_C2GATE_CREATE)
			agent_cmd_create(rpk);
	}else{
		//agentservice_t service = get_thd_agentservice();
		if(cmd >= CMD_GAME2C && cmd < CMD_GAME2C_END){
			uint16_t size = reverse_read_uint16(rpk);//这个包需要发给多少个客户端
			//创建一个rpacket_t用于读取需要广播的客户端
			rpacket_t r = rpk_create_skip(rpk,size*sizeof(agentsession)+sizeof(size));
			//将rpk中用于广播的信息丢掉
			rpk_dropback(rpk,size*sizeof(agentsession)+sizeof(size));
			int i = 0;
			wpacket_t wpk = wpk_create_by_rpacket(rpk);
			//发送给所有需要接收的客户端
			for( ; i < size; ++i)
			{
				agentsession session;
				session.data = rpk_read_uint32(r);
				agentplayer_t ply = get_agentplayer(session);
				if(ply)	
					asyn_send(ply->con,wpk);
			}
			rpk_destroy(&r);
		}else if(cmd >= CMD_GAME2GATE && cmd < CMD_GAME2GATE_END)
		{
			if(cmd == CMD_GAME2GATE_BUSY)
				agent_game_busy(rpk);
		}
		else if(cmd >= CMD_GAME2C && cmd < CMD_GAME2C_END){
			sock_ident sock = TO_SOCK(MSG_IDENT(rpk));
			GET_AGENT_PLAYER;
			if(ply && ply->state == agent_playing)
			{
				//转发到gameserver
				send2game(wpk_create_by_rpacket(rpk));
			}
		}
	}
    return 1;
}


agentservice_t new_agentservice(uint8_t agentid,asynnet_t asynet){
	agentservice_t service = calloc(1,sizeof(*service));
	service->agentid = agentid;
	service->_idmgr = new_idmgr(1,MAX_ANGETPLAYER);
	service->msgdisp = new_msgdisp(asynet,3,
                                   CB_CONNECT(agent_connect),
                                   CB_DISCNT(agent_disconnected),
                                   CB_PROCESSPACKET(agent_processpacket)
                                   );
	service->thd = create_thread(THREAD_JOINABLE); 
	thread_start_run(service->thd,service_main,(void*)service);
	return service;
}


void destroy_agentservice(agentservice_t s)
{
	//destroy_agentservice应该在gateserver关闭时调用，所以这里不需要做任何释放操作了
	s->stop = 1;
	thread_join(s->thd);
}

agentservice_t get_thd_agentservice()
{
	return (agentservice_t)tls_get(AGETNSERVICE_TLS);
}
