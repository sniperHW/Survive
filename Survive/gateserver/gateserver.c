#include "agent.h"

/*
*  八核心服务器
*  1个线程跑监听
*  1个线程跑togrpgame
*  6个线程跑agent
*/

#define MAX_AGENT 8
static agent *agents[MAX_AGENT];

static void on_new_client(kn_stream_server_t _,kn_stream_conn_t conn){
	(void)_;
	//随机选择一个agent将conn交给他处理
}

static int agent_count;
static volatile int stop = 0;
static void sig_int(int sig){
	stop = 1;
}

int main(int argc,char **argv){

	signal(SIGINT,sig_int);
	int i = 0;
	agent_count = 6;//通过配置或启动参数获取
	for(; i < agent_count; ++i)
		agents[i] = start_agent(i);

	kn_proactor_t p = kn_new_proactor();
	//启动监听
	kn_sockaddr local;
	kn_addr_init_in(&local,argv[1],atoi(argv[2]));
	kn_new_stream_server(p,&local,on_new_client);
	
	while(!stop)
		kn_proactor_run(p,50);
		
	//for(i=0;i < MAX_AGENT; ++i)
	//	stop_agent(agents[i]);

	return 0;
}