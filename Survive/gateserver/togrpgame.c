#include "togrpgame.h"
#include "chanmsg.h"
#include "kn_stream_conn.h"
#include "config.h"
#include "common/netcmd.h"

struct st_2gameconn{
	kn_stream_conn_t conn;
	char             name[256];	
};

struct connect_st{
	kn_sockaddr addr;
	uint16_t    type;//GROUPSERVER/GAMESERVER
};

#define MAX_GAME_CONN 4096

togrpgame*  g_togrpgame = NULL;
void forward_agent(rpacket_t rpk);

static struct st_2gameconn* g_togames[MAX_GAME_CONN]; 


static kn_stream_conn_t GetGame(const char *name){
	int i = 0;
	for( ; i < MAX_GAME_CONN; ++i){
		if(g_togames[i] && strcmp(g_togames[i]->name,name) == 0){
			return g_togames[i]->conn;
		}
	}
	return NULL;	
}

static int AddGame(kn_stream_conn_t conn,const char *name){
	if(GetGame(name)) return -1;
	struct st_2gameconn *st = calloc(1,sizeof(*st));
	st->conn = conn;
	strcpy(st->name,name);
	int i = 0;
	for( ; i < MAX_GAME_CONN; ++i){	
		if(!g_togames[i]){
			g_togames[i] = st;
			return 0;
		}
	}
	free(st);
	return -1;
}

static void RemGame(kn_stream_conn_t conn){
	int i = 0;
	for( ; i < MAX_GAME_CONN; ++i){
		if(g_togames[i] && g_togames[i]->conn == conn){
			free(g_togames[i]);
			g_togames[i] = NULL;
			return;
		}
	}
}


void GA_NOTIFYGAME(rpacket_t rpk);
void GAMEA_LOGINRET(kn_stream_conn_t conn,rpacket_t rpk);

//处理来group和game的消息
static int on_packet(kn_stream_conn_t conn,rpacket_t rpk){
	printf("togrpgame on_packet\n");
	
	uint16_t cmd = rpk_peek_uint16(rpk);
	printf("%d\n",cmd);
	if(cmd == CMD_GA_NOTIFYGAME){
		rpk_read_uint16(rpk);
		GA_NOTIFYGAME(rpk);
	}else if(cmd == CMD_GAMEA_LOGINRET){
		rpk_read_uint16(rpk);
		GAMEA_LOGINRET(conn,rpk);
	}else
		forward_agent(rpk);	
	return 1;
}

static int  cb_timer(kn_timer_t timer)//如果返回1继续注册，否则不再注册
{
	struct connect_st *st = kn_timer_getud(timer);
	kn_stream_connect(g_togrpgame->stream_client,NULL,&st->addr,(void*)st);
	free(timer);
	return 0;
}

static void on_connect_failed(kn_stream_client_t c,kn_sockaddr *addr,int err,void *ud)
{
	printf("on_connect_failed\n");
	struct connect_st *st = (struct connect_st*)ud;	
	if((remoteServerType)st->type == GROUPSERVER){
		//记录日志
	}else if((remoteServerType)st->type == GAMESERVER){
		//记录日志	
	}
	//5秒后重连
	kn_reg_timer(g_togrpgame->p,5000,cb_timer,st);
}

static void on_disconnected(kn_stream_conn_t conn,int err){
	remoteServerType type = (remoteServerType)kn_stream_conn_getud(conn);
	if(type == GROUPSERVER){
		g_togrpgame->togroup = NULL;
		struct connect_st *st = calloc(1,sizeof(*st));
		st->type = GROUPSERVER;
		kn_addr_init_in(&st->addr,kn_to_cstr(g_config->groupip),g_config->groupport);	
		kn_reg_timer(g_togrpgame->p,5000,cb_timer,st);
	}else if(type == GAMESERVER){
		RemGame(conn);
		kn_sockaddr *remoteaddr = kn_stream_conn_remote_addr(conn);
		struct connect_st *st = calloc(1,sizeof(*st));
		st->addr = *remoteaddr;
		st->type = GAMESERVER;
		kn_reg_timer(g_togrpgame->p,5000,cb_timer,st);
	}
}

static void on_connect(kn_stream_client_t c,kn_stream_conn_t conn,void *ud){
	do{
		if(0 != kn_stream_client_bind(g_togrpgame->stream_client,conn,0,65536,on_packet,on_disconnected,
				10*1000,NULL,0,NULL)){
			kn_stream_conn_close(conn);
			break;
		}
		struct connect_st *st = (struct connect_st *)ud;
		if((remoteServerType)st->type == GROUPSERVER){
			g_togrpgame->togroup = conn;
			kn_stream_conn_setud(conn,(void*)GROUPSERVER);
			printf("connect to group success\n");		
			wpacket_t wpk = NEW_WPK(64);
			wpk_write_uint16(wpk,CMD_AG_LOGIN);
			wpk_write_string(wpk,"gate1");
			kn_stream_conn_send(conn,wpk);		
		}else if((remoteServerType)st->type == GAMESERVER){
			kn_stream_conn_setud(conn,(void*)GAMESERVER);
			printf("connect to game success\n");		
			wpacket_t wpk = NEW_WPK(64);
			wpk_write_uint16(wpk,CMD_AGAME_LOGIN);
			wpk_write_string(wpk,"gate1");
			kn_stream_conn_send(conn,wpk);			
		}
	}while(0);
	free(ud);
}

void GA_NOTIFYGAME(rpacket_t rpk){
	uint8_t size = rpk_read_uint8(rpk);
	uint8_t i = 0;
	for( ; i < size; ++i){
		const char *ip = rpk_read_string(rpk);
		uint16_t   port = rpk_read_uint16(rpk);
		struct connect_st *st = calloc(1,sizeof(*st));
		kn_addr_init_in(&st->addr,ip,port);
		st->type = GAMESERVER;	
		kn_stream_connect(g_togrpgame->stream_client,NULL,&st->addr,(void*)st);		
	}
}

void GAMEA_LOGINRET(kn_stream_conn_t conn,rpacket_t rpk){
	uint8_t ret = rpk_read_uint8(rpk);
	if(ret){
		kn_stream_conn_close(conn);
	}else{
		struct st_2gameconn *st = calloc(1,sizeof(*st));
		st->conn = conn;
		const char *name = rpk_read_string(rpk);
		strcpy(st->name,name);
		if(0 != AddGame(conn,name)){
			printf("login %s success\n",name);
			free(st);
			kn_stream_conn_close(conn);
		}
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
	
	struct connect_st *st = calloc(1,sizeof(*st));
	kn_addr_init_in(&st->addr,kn_to_cstr(g_config->groupip),g_config->groupport);
	st->type = GROUPSERVER;	
	kn_stream_connect(g_togrpgame->stream_client,NULL,&st->addr,(void*)st);
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

