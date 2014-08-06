#ifndef _AGENT_H
#define _AGENT_H

//每个agent管理一组客户端连接,由单独的线程运行

//#include "kn_stream_conn_server.h"
#include "kn_thread.h"
#include "kendynet.h"
#include "gateplayer.h"
#include "common/agentsession.h"
#include "common/idmgr.h"
#include "kn_thread_mailbox.h"
#include "kn_redis.h"
#define MAX_AGENT_PLAYER 4096

typedef struct agent{
	uint8_t            idx;
	engine_t           p;
	kn_thread_t        t;
	kn_thread_mailbox_t mailbox;
	redisconn_t        redis;
	idmgr_t            idmgr;
	agentplayer_t      players[MAX_AGENT_PLAYER];
}agent;

agent *start_agent(uint8_t idx);
void   stop_agent(agent*);
int    mail2toagent(agent*,void*,void (*fn_destroy)(void*));


#endif
