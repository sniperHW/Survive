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


void forward_agent(packet_t rpk,stream_conn_t conn){
	struct chanmsg_rpacket *msg = calloc(1,sizeof(*msg));
	msg->chanmsg.msgtype = PACKET;
	msg->rpk = (packet_t)rpk_copy_create(rpk);
	if(conn){
		msg->game = calloc(1,sizeof(ident));
		*msg->game = make_ident((refobj*)conn);	
	}
	int i = 0; 
	for(; i < MAX_AGENT; ++i){
		if(agents[i]){
			mail2toagent(agents[i],msg,chanmsg_rpacket_destroy);
		}
	}
}

static void on_new_client(handle_t s,void *_){
	(void)_;
	printf("on_new_client\n");
	//随机选择一个agent将conn交给他处理
	uint8_t idx = rand()%g_config->agentcount;
	struct chanmsg_newclient *msg = calloc(1,sizeof(*msg));
	msg->chanmsg.msgtype = NEWCLIENT;
	msg->conn = new_stream_conn(s,4096,RPACKET);;
	mail2toagent(agents[idx],msg,chanmsg_newclient_destroy);
}

static engine_t  e = NULL;
static void sig_int(int sig){
	kn_stop_engine(e);
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

	e = kn_new_engine();
	//启动监听
	kn_sockaddr local;
	kn_addr_init_in(&local,kn_to_cstr(g_config->toclientip),g_config->toclientport);	
	handle_t l = kn_new_sock(AF_INET,SOCK_STREAM,IPPROTO_TCP);
	if(0 != kn_sock_listen(e,l,&local,on_new_client,NULL)){
		printf("create server on ip[%s],port[%u] error\n",kn_to_cstr(g_config->toclientip),g_config->toclientport);
		LOG_GATE(LOG_INFO,"create server on ip[%s],port[%u] error\n",kn_to_cstr(g_config->toclientip),g_config->toclientport);
		
		exit(0);
	}
	start_togrpgame();
	LOG_GATE(LOG_INFO,"gateserver start success\n");
	kn_engine_run(e);
	return 0;
}
