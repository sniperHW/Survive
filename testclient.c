#include <stdio.h>
#include <stdlib.h>
#include "core/netservice.h"
#include "common/cmd.h"

static volatile int8_t stop = 0;

static void stop_handler(int signo){
	printf("stop_handler\n");
    stop = 1;
}

void setup_signal_handler()
{
	struct sigaction act;
    bzero(&act, sizeof(act));
    act.sa_handler = stop_handler;
    sigaction(SIGINT, &act, NULL);
    sigaction(SIGTERM, &act, NULL);
}

int8_t on_process_packet(struct connection *c,rpacket_t r)
{
    //wpacket_t l_wpk = NEW_WPK(send_size);
    //wpk_write_binary(l_wpk,(void*)msg,send_size);
    //send_packet(c,l_wpk,NULL);
    //send_packet(c,wpk_create_by_rpacket(r));
    return 1;
}

void on_connect(SOCK s,struct sockaddr_in *addr_remote, void *ud,int err)
{
    if(s != INVALID_SOCK){
        struct connection * con = new_conn(s,0);
        struct netservice *tcpclient = (struct netservice *)ud;
		tcpclient->bind(tcpclient,con,65536,on_process_packet,NULL
						,0,NULL,0,NULL);
        //发送登录请求
        
        wpacket_t wpk = NEW_WPK(64);
        wpk_write_uint16(wpk,CMD_C2GATE_LOGIN);
        wpk_write_string(wpk,"huangwei");
        wpk_write_string(wpk,"198272");
        send_packet(con,wpk);
        //wpk_write_binary(wpk,(void*)msg,send_size);
        //send_packet(con,wpk);
    }
}


int main(int argc,char **argv)
{
	setup_signal_handler();
    InitNetSystem();
    struct netservice *tcpclient = new_service();
    tcpclient->connect(tcpclient,"127.0.0.1",8010,(void*)tcpclient,on_connect,10000);
	while(!stop){
        tcpclient->loop(tcpclient,50);
	}
	destroy_service(&tcpclient);
    CleanNetSystem();
    return 0;
}
