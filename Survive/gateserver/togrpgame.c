#include "togrpgame.h"
#include "chanmsg.h"
#include "kn_stream_conn.h"
#include "config.h"
#include "common/netcmd.h"

togrpgame*  g_togrpgame = NULL;
static kn_sockaddr groupaddr;
void forward_agent(rpacket_t rpk);

//处理来group和game的消息
static int on_packet(kn_stream_conn_t _,rpacket_t rpk){
	(void)_;
	printf("togrpgame on_packet\n");
	forward_agent(rpk);	
	return 1;
}

static void on_connect_failed(kn_stream_client_t c,kn_sockaddr *addr,int err,void *ud)
{
	printf("on_connect_failed\n");	
	if((remoteServerType)ud == GROUPSERVER){
		//记录日志
	}else if((remoteServerType)ud == GAMESERVER){
		//记录日志	
	}
	//重连
	kn_stream_connect(g_togrpgame->stream_client,NULL,&groupaddr,(void*)GROUPSERVER);
}

static void on_disconnected(kn_stream_conn_t conn,int err){
	if(conn == g_togrpgame->togroup){
		g_togrpgame->togroup = NULL;
		kn_stream_connect(g_togrpgame->stream_client,NULL,&groupaddr,(void*)GROUPSERVER);
	}else{
	
	}
}

static void on_connect(kn_stream_client_t c,kn_stream_conn_t conn,void *ud){
	if(0 != kn_stream_client_bind(g_togrpgame->stream_client,conn,0,65536,on_packet,on_disconnected,
			10*1000,NULL,0,NULL)){

		kn_stream_conn_close(conn);
		return;
	}
	if((remoteServerType)ud == GROUPSERVER){
		g_togrpgame->togroup = conn;
		printf("connect to group success\n");		
		wpacket_t wpk = NEW_WPK(64);
		wpk_write_uint16(wpk,CMD_AG_LOGIN);
		wpk_write_string(wpk,"gate1");
		kn_stream_conn_send(conn,wpk);		
	}else if((remoteServerType)ud == GAMESERVER){
		
	}
	
}

//处理来自channel的消息
static void on_channel_msg(kn_channel_t chan, kn_channel_t from,void *msg,void *_)
{
	(void)_;
	if(((struct chanmsg*)msg)->msgtype == FORWARD_GAME){
		struct chanmsg_forward_game *_msg = (struct chanmsg_forward_game*)msg;
		kn_stream_conn_t conn = cast2_kn_stream_conn(_msg->game);
		if(conn){
			kn_stream_conn_send(conn,_msg->wpk);
			_msg->wpk = NULL;
		}
	}else if(((struct chanmsg*)msg)->msgtype == FORWARD_GROUP){
		struct chanmsg_forward_group *_msg = (struct chanmsg_forward_group*)msg;
		if(g_togrpgame->togroup){
			printf("send 2 group\n");
			kn_stream_conn_send(g_togrpgame->togroup,_msg->wpk);
			_msg->wpk = NULL;
		}
	}
}

static void *service_main(void *ud){
	g_togrpgame->stream_client = kn_new_stream_client(g_togrpgame->p,on_connect,on_connect_failed);
	kn_addr_init_in(&groupaddr,kn_to_cstr(g_config->groupip),g_config->groupport);	
	kn_stream_connect(g_togrpgame->stream_client,NULL,&groupaddr,(void*)GROUPSERVER);
	while(!g_togrpgame->stop){
		kn_proactor_run(g_togrpgame->p,50);
	}
	return NULL;
}

int     start_togrpgame(){
	g_togrpgame = calloc(1,sizeof(*g_togrpgame));
	g_togrpgame->p = kn_new_proactor();
	g_togrpgame->t = kn_create_thread(THREAD_JOINABLE);
	g_togrpgame->stream_client = kn_new_stream_client(g_togrpgame->p,
							  on_connect,
							  on_connect_failed);	

	g_togrpgame->chan = kn_new_channel(kn_thread_getid(g_togrpgame->t));
	kn_channel_bind(g_togrpgame->p,g_togrpgame->chan,on_channel_msg,NULL);
	kn_thread_start_run(g_togrpgame->t,service_main,NULL);
	return 0;


}

void    stop_togrpgame(){
	g_togrpgame->stop = 1;
	kn_thread_join(g_togrpgame->t);
}

