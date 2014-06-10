#ifndef _AGENT_H
#define _AGENT_H

//每个agent管理一组客户端连接,由单独的线程运行

#include "kn_stream_conn_server.h"
#include "kn_thread.h"
#include "kendynet.h"
#include "gateplayer.h"
#include "common/agentsession.h"

typedef struct agent{
	uint8_t            idx;
	kn_proactor_t      p;
	kn_thread_t        t;
	kn_channel_t       chan;
	redisconn_t        redis;
	kn_stream_server_t server;
	volatile uint8_t   stop;
	agentplayer_t      players[4096];
};

agent *start_agent(uint8_t idx);
void   stop_agent(agent*);


#endif