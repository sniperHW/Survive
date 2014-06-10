#ifndef _TOGRPGAME_H
#define _TOGRPGAME_H

#include "kn_stream_conn_client.h"
#include "kn_thread.h"
#include "kendynet.h"

//到group和game的连接处理服务,运行在独立的线程中

typedef struct togrpgame{
	kn_proactor_t       p;
	kn_thread_t         t;
	kn_channel_t        chan;
	volatile uint8_t    stop;
	kn_stream_conn_t    togroup;
	kn_stream_client_t  stream_client;
}togrpgame;


int     start_togrpgame();
void    stop_togrpgame();

extern togrpgame * g_togrpgame;

#endif
