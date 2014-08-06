#include "togrpgame.h"
#include "chanmsg.h"
#include "stream_conn.h"
#include "config.h"
#include "common/netcmd.h"

struct st_2gameconn{
	stream_conn_t    conn;
	char             name[256];	
};

#define MAX_GAME_CONN 4096
togrpgame*  g_togrpgame = NULL;
void forward_agent(rpacket_t rpk,stream_conn_t);

static struct st_2gameconn* g_togames[MAX_GAME_CONN]; 
static stream_conn_t GetGame(const char *name){
	int i = 0;
	for( ; i < MAX_GAME_CONN; ++i){
		if(g_togames[i] && strcmp(g_togames[i]->name,name) == 0){
			return g_togames[i]->conn;
		}
	}
	return NULL;	
}

static int AddGame(stream_conn_t conn,const char *name){
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

static void RemGame(stream_conn_t conn){
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
void GAMEA_LOGINRET(stream_conn_t conn,rpacket_t rpk);

//处理来group和game的消息
static int on_packet(stream_conn_t conn,packet_t pk){
	rpacket_t rpk = (rpacket_t)pk;
	uint16_t cmd = rpk_peek_uint16(rpk);
	printf("togrpgame on_packet:%u\n",cmd);
	if(cmd == CMD_GA_NOTIFYGAME){
		rpk_read_uint16(rpk);
		GA_NOTIFYGAME(rpk);
	}else if(cmd == CMD_GAMEA_LOGINRET){
		rpk_read_uint16(rpk);
		GAMEA_LOGINRET(conn,rpk);
	}else{		
		if(cmd == CMD_SC_ENTERMAP)
			forward_agent(rpk,conn);
		else
			forward_agent(rpk,NULL);
	}	
	return 1;
}


int mail2togrpgame(void *mail,void (*fn_destroy)(void*)){
	while(is_empty_ident((ident)g_togrpgame->mailbox)){
		__sync_synchronize();
		kn_sleepms(1);
	}
	return kn_send_mail(g_togrpgame->mailbox,mail,fn_destroy);
}

struct recon_ctx{
	handle_t     sock;
	kn_sockaddr  addr;
	void (*cb_connect)(handle_t,int,void*,kn_sockaddr*);
};


static void on_game_disconnected(stream_conn_t c,int err){
	RemGame(c);	
}


static int  cb_timer(kn_timer_t timer)//如果返回1继续注册，否则不再注册
{
	struct recon_ctx *recon = (struct recon_ctx*)kn_timer_getud(timer);
	kn_sock_connect(g_togrpgame->p,recon->sock,&recon->addr,NULL,recon->cb_connect,NULL);
	free(recon);
	return 0;
}

static void cb_connect_game(handle_t s,int err,void *ud,kn_sockaddr *addr)
{
	if(err == 0){
		//success
		stream_conn_t conn = new_stream_conn(s,65536,RPACKET);
		stream_conn_associate(g_togrpgame->p,conn,on_packet,on_game_disconnected);
		printf("connect to game success\n");		
		wpacket_t wpk = wpk_create(64);
		wpk_write_uint16(wpk,CMD_AGAME_LOGIN);
		wpk_write_string(wpk,"gate1");
		stream_conn_send(conn,(packet_t)wpk);			
	}else{
		//failed
		kn_close_sock(s);
		struct recon_ctx *recon = calloc(1,sizeof(*recon));
		recon->sock = kn_new_sock(AF_INET,SOCK_STREAM,IPPROTO_TCP);
		recon->addr = *addr;
		recon->cb_connect = cb_connect_game;
		kn_reg_timer(g_togrpgame->p,5000,cb_timer,recon);
	}
}

static void cb_connect_group(handle_t s,int err,void *ud,kn_sockaddr*);
static void on_group_disconnected(stream_conn_t c,int err){
	g_togrpgame->togroup = NULL;
	struct recon_ctx *recon = calloc(1,sizeof(*recon));
	recon->sock = kn_new_sock(AF_INET,SOCK_STREAM,IPPROTO_TCP);
	recon->cb_connect = cb_connect_group;
	recon->addr = *kn_sock_addrpeer(stream_conn_gethandle(c));
	kn_reg_timer(g_togrpgame->p,5000,cb_timer,recon);
}

static void cb_connect_group(handle_t s,int err,void *ud,kn_sockaddr *addr)
{
	if(err == 0){
		//success
		g_togrpgame->togroup = new_stream_conn(s,65536,RPACKET);
		stream_conn_associate(g_togrpgame->p,g_togrpgame->togroup,on_packet,on_group_disconnected);
		printf("connect to group success\n");		
		wpacket_t wpk = wpk_create(64);
		wpk_write_uint16(wpk,CMD_AG_LOGIN);
		wpk_write_string(wpk,"gate1");
		stream_conn_send(g_togrpgame->togroup,(packet_t)wpk);			
	}else{
		printf("connect to group failed,try after 5 sec\n");
		//failed
		kn_close_sock(s);
		struct recon_ctx *recon = calloc(1,sizeof(*recon));
		recon->sock = kn_new_sock(AF_INET,SOCK_STREAM,IPPROTO_TCP);
		recon->addr = *addr;
		recon->cb_connect = cb_connect_group;
		kn_reg_timer(g_togrpgame->p,5000,cb_timer,recon);		
	}		
}


void GA_NOTIFYGAME(rpacket_t rpk){
	uint8_t size = rpk_read_uint8(rpk);
	uint8_t i = 0;
	printf("NOTIFYGAME:%d\n",size);
	for( ; i < size; ++i){
		const char *ip = rpk_read_string(rpk);
		uint16_t   port = rpk_read_uint16(rpk);
		kn_sockaddr addr;
		kn_addr_init_in(&addr,ip,port);
		handle_t sock = kn_new_sock(AF_INET,SOCK_STREAM,IPPROTO_TCP);
		kn_sock_connect(g_togrpgame->p,sock,&addr,NULL,cb_connect_game,NULL);		
	}
}

void GAMEA_LOGINRET(stream_conn_t conn,rpacket_t rpk){
	uint8_t ret = rpk_read_uint8(rpk);
	if(ret){
		stream_conn_close(conn);
	}else{
		struct st_2gameconn *st = calloc(1,sizeof(*st));
		st->conn = conn;
		const char *name = rpk_read_string(rpk);
		strcpy(st->name,name);
		if(0 != AddGame(conn,name)){
			printf("login %s success\n",name);
			free(st);
			stream_conn_close(conn);
		}
	}
}

//处理来自channel的消息
static void on_mail(kn_thread_mailbox_t *_,void *msg)//(kn_channel_t chan, kn_channel_t from,void *msg,void *_)
{
	(void)_;
	if(((struct chanmsg*)msg)->msgtype == FORWARD_GAME){
		struct chanmsg_forward_game *_msg = (struct chanmsg_forward_game*)msg;
		stream_conn_t conn = (stream_conn_t)cast2refobj(_msg->game);//cast2_kn_stream_conn(_msg->game);
		if(conn){
			stream_conn_send(conn,_msg->wpk);
			_msg->wpk = NULL;
		}
	}else if(((struct chanmsg*)msg)->msgtype == FORWARD_GROUP){
		struct chanmsg_forward_group *_msg = (struct chanmsg_forward_group*)msg;
		if(g_togrpgame->togroup){
			printf("send 2 group\n");
			stream_conn_send(g_togrpgame->togroup,_msg->wpk);
			_msg->wpk = NULL;
		}
	}
}

static void *service_main(void *ud){	
	kn_setup_mailbox(g_togrpgame->p,MODE_FAIR,on_mail);
	g_togrpgame->mailbox = kn_self_mailbox();
	
	kn_sockaddr addr;
	kn_addr_init_in(&addr,kn_to_cstr(g_config->groupip),g_config->groupport);
	handle_t sock = kn_new_sock(AF_INET,SOCK_STREAM,IPPROTO_TCP);
	kn_sock_connect(g_togrpgame->p,sock,&addr,NULL,cb_connect_group,NULL);
	kn_engine_run(g_togrpgame->p);
	return NULL;
}

int start_togrpgame(){
	g_togrpgame = calloc(1,sizeof(*g_togrpgame));
	g_togrpgame->p = kn_new_engine();
	g_togrpgame->t = kn_create_thread(THREAD_JOINABLE);
	kn_thread_start_run(g_togrpgame->t,service_main,NULL);
	return 0;


}

void    stop_togrpgame(){
	kn_stop_engine(g_togrpgame->p);
	kn_thread_join(g_togrpgame->t);
}

