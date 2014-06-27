#include <stdio.h>
#include "kendynet.h"
#include "kn_stream_conn_client.h"
#include "Survive/common/netcmd.h"

static kn_stream_client_t c;
static kn_sockaddr remote;

static int  on_packet(kn_stream_conn_t conn,rpacket_t rpk){
	//kn_stream_conn_send(conn,wpk_create_by_rpacket(rpk));
	
	uint16_t cmd = rpk_read_uint16(rpk);
	
	if(cmd == CMD_GC_CREATE){
			printf("notify create character\n");
			wpacket_t wpk = NEW_WPK(64);
			wpk_write_uint16(wpk,CMD_CG_CREATE);
			wpk_write_string(wpk,"huangwei");
			kn_stream_conn_send(conn,wpk);
	}
	return 1;
}

static void on_disconnected(kn_stream_conn_t conn,int err){
	printf("on_disconnected\n");
}

static void on_connected(kn_stream_client_t client,kn_stream_conn_t conn,void *_){
	((void)_);
	kn_stream_client_bind(client,conn,0,1024,on_packet,on_disconnected,
						  0,NULL,0,NULL);
	wpacket_t wpk = NEW_WPK(64);
	wpk_write_uint16(wpk,CMD_CA_LOGIN);
	wpk_write_uint8(wpk,2);
	wpk_write_string(wpk,"kenny");
	kn_stream_conn_send(conn,wpk);							  
}

static void on_connect_failed(kn_stream_client_t client,kn_sockaddr *addr,int err,void *_)
{	
		((void)_);
		printf("connect_fail\n");
}

int main(int argc,char **argv)
{
	kn_proactor_t p = kn_new_proactor();
	kn_addr_init_in(&remote,argv[1],atoi(argv[2]));		
	c = kn_new_stream_client(p,on_connected,on_connect_failed);
	kn_stream_connect(c,NULL,&remote,NULL);
	
	while(1){
		kn_proactor_run(p,50);
	}
	return 0;
}
