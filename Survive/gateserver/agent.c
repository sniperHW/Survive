#include "agent.h"

//处理来自客户端的网络包
static int on_packet(kn_stream_conn_t con,rpacket_t rpk){


}

//处理来自channel的消息
static void on_channel_msg(kn_channel_t chan, kn_channel_t from,void *msg,void *_)
{
	(void)_;

}

static void on_redis_connect(redisconn_t conn,int err,void *ud){
	if(conn) ((agent*)ud)->redis = conn;
	else{
		//重连
	}
}

static	void on_redis_disconnected(redisconn_t conn,void *ud){
	((agent*)ud)->redis = NULL;
	//重连
}

static void *service_main(void *ud){
	printf("agent service运行\n");	
	agent *agent = (agent*)ud;

	if(0 != kn_redisAsynConnect(agent->p,
		"127.0.0.1",8010,
		on_redis_connect,
		on_redis_disconnected,
		agent)){
		//记录日志
		return NULL;
	}
	while(!agent->stop){
		kn_proactor_run(agent->p,50);
	}
	return NULL;
}


agent *start_agent(uint8_t idx){
	agent *agent = calloc(1,sizeof(*agent));
	agent->idx = idx;
	agent->p = kn_new_proactor();
	agent->t = kn_create_thread(JOINABLE);
	kn_new_stream_server(agent->p,NULL,NULL);
	agent->chan = kn_new_channel(kn_thread_getid(agent->t));
	kn_channel_bind(agent->p,agent->chan,on_channel_msg);
	kn_thread_start_run(agent->t,service_main,agent);
	return agent;
}

void   stop_agent(agent *agent){
	agent->stop = 1;
	kn_thread_join(agent->t);
	//stop_agent应该在进程结束时调用，不做任何收尾工作了
}