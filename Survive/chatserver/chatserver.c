#include "kendynet.h"
#include "chatserver.h"
#include "config.h"
#include "lua_util.h"
#include "stream_conn.h"
#include "common/netcmd.h"
#include "common/cmdhandler.h"
#include "common/common_c_function.h"

IMP_LOG(chatlog);

#define MAXCMD 65535
static cmd_handler_t handler[MAXCMD] = {NULL};
__thread engine_t t_engine = NULL;

static int on_game_packet(stream_conn_t conn,packet_t pk){
	rpacket_t rpk = (rpacket_t)pk;
	uint16_t cmd = rpk_read_uint16(rpk);
	process_cmd(cmd,conn,rpk);
	return 1;
}

static void on_game_disconnected(stream_conn_t conn,int err){
	process_cmd(DUMMY_ON_GAME_DISCONNECTED,conn,NULL);
}


static void on_new_game(handle_t s,void *_){
	stream_conn_t game = new_stream_conn(s,65536,RPACKET);
	if(0 != stream_conn_associate(t_engine,game,on_game_packet,on_game_disconnected))
		stream_conn_close(game);
}

static int on_gate_packet(stream_conn_t conn,packet_t pk){
	rpacket_t rpk = (rpacket_t)pk;
	uint16_t cmd = rpk_read_uint16(rpk);
	process_cmd(cmd,conn,rpk);
	return 1;
}

static void on_gate_disconnected(stream_conn_t conn,int err){
	process_cmd(DUMMY_ON_GATE_DISCONNECTED,conn,NULL);
}


static void on_new_gate(handle_t s,void *_){
	stream_conn_t gate = new_stream_conn(s,65536,RPACKET);
	if(0 != stream_conn_associate(t_engine,gate,on_gate_packet,on_gate_disconnected))
		stream_conn_close(gate);
}

static void sig_int(int sig){
	kn_stop_engine(t_engine);
}


int main(int argc,char **argv){
	signal(SIGPIPE,SIG_IGN);	
	if(loadconfig() != 0){
		return 0;
	}
	signal(SIGINT,sig_int);
	t_engine = kn_new_engine();	
	if(!init())
		return 0;
	kn_engine_run(t_engine);
	return 0;	
}
