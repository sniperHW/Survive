#ifndef _AGENTSERVICE_H
#define _AGENTSERVICE_H

#include "common/agentsession.h"
#include "core/asynnet/msgdisp.h"
#include "core/thread.h"
#include "core/idmgr.h"
#include "core/tls.h"
#include "common/tls_define.h"

#define MAX_ANGETPLAYER   8191

#define MAX_AGENT 32


typedef struct agentservice
{
	volatile uint8_t stop;
	uint8_t     agentid;        //0-7
	thread_t    thd;            //运行本agentservice的线程
	msgdisp_t   msgdisp;
	agentplayer players[MAX_ANGETPLAYER+1];//0不能用，作为非法值
	uint16_t    identity;
	idmgr_t     _idmgr;
}*agentservice_t;

agentservice_t new_agentservice(uint8_t agentid,asynnet_t asynet);
void           stop_agentservice(agentservice_t);

extern agentservice_t g_agents[MAX_AGENT];

//获得当前线程的agentservice
static inline agentservice_t get_thd_agentservice(){
	return (agentservice_t)tls_get(AGETNSERVICE_TLS);
}

static inline agentservice_t get_agent_byindex(uint8_t idx){
	return g_agents[idx];
}


agentplayer_t get_agentplayer(agentsession session);

void send2player(agentplayer_t,wpacket_t);



#endif
