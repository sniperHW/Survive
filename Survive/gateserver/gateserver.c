#include "agent.h"
#include "config.h"
#include "chanmsg.h"
#include "gateserver.h"
#include "togrpgame.h"

/*
*  八核心服务器
*  1个线程跑监听
*  1个线程跑togrpgame
*  6个线程跑agent
*/

#define MAX_AGENT 8
static agent *agents[MAX_AGENT]= {NULL};
IMP_LOG(gatelog);


void forward_agent(rpacket_t rpk,kn_stream_conn_t conn){
	struct chanmsg_rpacket *msg = calloc(1,sizeof(*msg));
	msg->chanmsg.msgtype = RPACKET;
	msg->rpk = rpk_create_by_other((struct packet*)rpk);
	if(conn){
		msg->game = calloc(1,sizeof(ident));
		*msg->game = kn_stream_conn_makeident(conn);	
	}
	int i = 0; 
	for(; i < MAX_AGENT; ++i){
		if(agents[i]){
			kn_channel_putmsg(agents[i]->chan,NULL,msg,chanmsg_rpacket_destroy);
		}
	}
}

static void on_new_client(kn_stream_server_t _,kn_stream_conn_t conn){
	(void)_;
	//随机选择一个agent将conn交给他处理
	uint8_t idx = rand()%g_config->agentcount;
	struct chanmsg_newclient *msg = calloc(1,sizeof(*msg));
	msg->chanmsg.msgtype = NEWCLIENT;
	msg->conn = conn;
	kn_channel_putmsg(agents[idx]->chan,NULL,msg,chanmsg_newclient_destroy);
}

static volatile int stop = 0;
static void sig_int(int sig){
	stop = 1;
}

int main(int argc,char **argv){
	LOG_GATE(LOG_INFO,"begin start gateserver\n");
	if(loadconfig() != 0){
		return 0;
	}
	signal(SIGPIPE,SIG_IGN);
	signal(SIGINT,sig_int);
	int i = 0;
	for(; i < g_config->agentcount; ++i)
		agents[i] = start_agent(i);

	kn_proactor_t p = kn_new_proactor();
	//启动监听
	kn_sockaddr local;
	kn_addr_init_in(&local,kn_to_cstr(g_config->toclientip),g_config->toclientport);
	
	if(!kn_new_stream_server(p,&local,on_new_client)){
		printf("create server on ip[%s],port[%u] error\n",kn_to_cstr(g_config->toclientip),g_config->toclientport);
		LOG_GATE(LOG_INFO,"create server on ip[%s],port[%u] error\n",kn_to_cstr(g_config->toclientip),g_config->toclientport);
		
		exit(0);
	}


	start_togrpgame();
	
	LOG_GATE(LOG_INFO,"gateserver start success\n");


	while(!stop)
		kn_proactor_run(p,50);
		
	//for(i=0;i < MAX_AGENT; ++i)
	//	stop_agent(agents[i]);

	return 0;
}
