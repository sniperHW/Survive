#include <stdio.h>
#include "kendynet.h"
#include "stream_conn.h"
#include "Survive/common/netcmd.h"

static kn_sockaddr remote;
char **actname;
engine_t g_engine;

int  x_size = 30;
int  y_size = 30;

struct ply{
	const char *actname;
	uint32_t    id;
};

void mov(stream_conn_t conn){
	int x = rand()%x_size;
	int y = rand()%y_size;
	
	wpacket_t wpk = wpk_create(64);
	wpk_write_uint16(wpk,CMD_CS_MOV);
	wpk_write_uint16(wpk,x);
	wpk_write_uint16(wpk,y);
	printf("%d\n",x);
	printf("%d\n",y);
	stream_conn_send(conn,(packet_t)wpk);	
}


static int  on_packet(stream_conn_t conn,packet_t pk){
	printf("on_packet\n");
	rpacket_t rpk = (rpacket_t)pk;
	uint16_t cmd = rpk_read_uint16(rpk);
	struct ply *ply = (struct ply *)stream_conn_getud(conn);
	if(cmd == CMD_GC_CREATE){
			printf("notify create character\n");
			wpacket_t wpk = wpk_create(64);
			wpk_write_uint16(wpk,CMD_CG_CREATE);
			wpk_write_string(wpk,ply->actname);
			stream_conn_send(conn,(packet_t)wpk);
			printf("CMD_GC_CREATE\n");
	}else if(cmd == CMD_GC_BEGINPLY){
		printf("BeginPly\n");
		wpacket_t wpk = wpk_create(64);
		wpk_write_uint16(wpk,CMD_CG_ENTERMAP);
		stream_conn_send(conn,(packet_t)wpk);
	}else if(cmd == CMD_SC_ENTERMAP){
		rpk_read_uint16(rpk);
		ply->id = rpk_read_uint32(rpk);
	}else if(cmd == CMD_SC_ENTERSEE){
		uint32_t id = rpk_read_uint32(rpk);
		if(id == ply->id){
			mov(conn);
		}
	}else if(cmd == CMD_SC_MOV_ARRI || cmd == CMD_SC_MOV_FAILED){
		if(cmd == CMD_SC_MOV_FAILED) printf("mov failed\n");
		mov(conn);
	}
	return 1;
}

static void on_disconnected(stream_conn_t conn,int err){
	printf("on_disconnected\n");
}


static void cb_connect(handle_t s,int err,void *ud,kn_sockaddr *addr){
	if(0 == err){
		struct ply *ply = (struct ply *)ud;	
		stream_conn_t conn = new_stream_conn(s,4096,RPACKET);
		stream_conn_associate(g_engine,conn,on_packet,on_disconnected);			
		stream_conn_setud(conn,ply);					  
		wpacket_t wpk = wpk_create(64);
		wpk_write_uint16(wpk,CMD_CA_LOGIN);
		wpk_write_uint8(wpk,2);
		wpk_write_string(wpk,ply->actname);
		stream_conn_send(conn,(packet_t)wpk);			
	}else{
		free(ud);
		printf("connect_fail\n");
	}


}
/*
static void on_connected(kn_stream_client_t client,kn_stream_conn_t conn,void *ud){
	struct ply *ply = (struct ply *)ud;
	kn_stream_client_bind(client,conn,0,1024,on_packet,on_disconnected,
						  0,NULL,0,NULL);
	kn_stream_conn_setud(conn,ply);					  
	wpacket_t wpk = NEW_WPK(64);
	wpk_write_uint16(wpk,CMD_CA_LOGIN);
	wpk_write_uint8(wpk,2);
	wpk_write_string(wpk,ply->actname);
	kn_stream_conn_send(conn,wpk);							  
}

static void on_connect_failed(kn_stream_client_t client,kn_sockaddr *addr,int err,void *_)
{	
		((void)_);
		printf("connect_fail\n");
}*/

static void sig_int(int sig){
	kn_stop_engine(g_engine);
}


int main(int argc,char **argv)
{	
	signal(SIGPIPE,SIG_IGN);
	signal(SIGINT,sig_int);	
	const char *actprefix   = argv[3];
	int         beg = atoi(argv[4]);
	int         end = atoi(argv[5]);
	
	int         size = end-beg+1;
	actname     = calloc(size,sizeof(*actname));
	int         i = 0;
	for(;beg <= end; ++beg,++i){
		char *tmp = calloc(64,1);
		snprintf(tmp,64,"%s%d",actprefix,beg);
		actname[i] = tmp;
	}
	g_engine = kn_new_engine();
	kn_addr_init_in(&remote,argv[1],atoi(argv[2]));
	for(i = 0;i < size; ++i){				
		handle_t l = kn_new_sock(AF_INET,SOCK_STREAM,IPPROTO_TCP);
		struct ply *ply = calloc(1,sizeof(*ply));
		ply->actname = actname[i];
		kn_sock_connect(g_engine,l,&remote,NULL,cb_connect,ply);
	}
		
	kn_engine_run(g_engine);
	
	return 0;
}
