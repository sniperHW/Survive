#include "agent.h"
#include "chanmsg.h"
#include "gateserver.h"
#include "toinner.h"

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
	uint32_t aid = reverse_read_uint32((rpacket_t)rpk);
	rpk_dropback((rpacket_t)rpk,sizeof(aid));
	aid &= 0x7;
	printf("forward aid:%d\n",aid);
	if(agents[aid]){
		struct chanmsg_rpacket *msg = calloc(1,sizeof(*msg));
		msg->chanmsg.msgtype = PACKET;
		msg->rpk = (packet_t)rpk_copy_create(rpk);
		if(conn){
			msg->game = calloc(1,sizeof(ident));
			*msg->game = make_ident((refobj*)conn);	
		}			
		mail2toagent(agents[aid],msg,chanmsg_rpacket_destroy);		
	}
}

static void on_new_client(handle_t s,void *_){
	(void)_;
	//随机选择一个agent将conn交给他处理
	uint8_t idx = rand()%1;
	struct chanmsg_newclient *msg = calloc(1,sizeof(*msg));
	msg->chanmsg.msgtype = NEWCLIENT;
	msg->conn = new_stream_conn(s,4096,new_rpk_decoder(4096));
	mail2toagent(agents[idx],msg,chanmsg_newclient_destroy);
}

static engine_t  e = NULL;
static void sig_int(int sig){
	kn_stop_engine(e);
}

int main(int argc,char **argv){
	LOG_GATE(LOG_INFO,"begin start gateserver\n");
	signal(SIGPIPE,SIG_IGN);
	signal(SIGINT,sig_int);
	int i = 0;
	for(; i < 1; ++i)
		agents[i] = start_agent(i);

	e = kn_new_engine();
	//启动监听
	kn_sockaddr local;
	kn_addr_init_in(&local,"127.0.0.1",8010);	
	handle_t l = kn_new_sock(AF_INET,SOCK_STREAM,IPPROTO_TCP);
	if(0 != kn_sock_listen(e,l,&local,on_new_client,NULL)){
		printf("create server on ip[%s],port[%u] error\n","127.0.0.1",8010);
		LOG_GATE(LOG_INFO,"create server on ip[%s],port[%u] error\n","127.0.0.1",8010);
		
		exit(0);
	}
	start_toinner();
	LOG_GATE(LOG_INFO,"gateserver start success\n");
	kn_engine_run(e);
	return 0;
}
