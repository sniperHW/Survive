#include <stdio.h>
#include "kendynet.h"
#include "kn_stream_conn_client.h"
#include "Survive/common/netcmd.h"

static kn_sockaddr remote;
char **actname;

int  x_size = 30;
int  y_size = 30;

struct ply{
	const char *actname;
	uint32_t    id;
};

void mov(kn_stream_conn_t conn){
	int x = rand()%x_size;
	int y = rand()%y_size;
	
	wpacket_t wpk = NEW_WPK(64);
	wpk_write_uint16(wpk,CMD_CS_MOV);
	wpk_write_uint16(wpk,x);
	wpk_write_uint16(wpk,y);
	printf("%d\n",x);
	printf("%d\n",y);
	kn_stream_conn_send(conn,wpk);	
}


static int  on_packet(kn_stream_conn_t conn,rpacket_t rpk){
	
	uint16_t cmd = rpk_read_uint16(rpk);
	struct ply *ply = (struct ply *)kn_stream_conn_getud(conn);
	if(cmd == CMD_GC_CREATE){
			printf("notify create character\n");
			wpacket_t wpk = NEW_WPK(64);
			wpk_write_uint16(wpk,CMD_CG_CREATE);
			wpk_write_string(wpk,ply->actname);
			kn_stream_conn_send(conn,wpk);
	}else if(cmd == CMD_GC_BEGINPLY){
		printf("BeginPly\n");
		wpacket_t wpk = NEW_WPK(64);
		wpk_write_uint16(wpk,CMD_CG_ENTERMAP);
		kn_stream_conn_send(conn,wpk);
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

static void on_disconnected(kn_stream_conn_t conn,int err){
	printf("on_disconnected\n");
}

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
}


int main(int argc,char **argv)
{	
	
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
	kn_proactor_t p = kn_new_proactor();
	kn_addr_init_in(&remote,argv[1],atoi(argv[2]));
	for(i = 0;i < size; ++i){		
		kn_stream_client_t c = kn_new_stream_client(p,on_connected,on_connect_failed);
		struct ply *ply = calloc(1,sizeof(*ply));
		ply->actname = actname[i];
		kn_stream_connect(c,NULL,&remote,ply);
	}
		
	while(1){
		kn_proactor_run(p,50);
	}
	return 0;
}
