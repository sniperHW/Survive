#ifndef _TOGRPGAME_H
#define _TOGRPGAME_H

#include "kn_thread.h"
#include "kn_thread_mailbox.h"
#include "kendynet.h"
#include "stream_conn.h"

//到group和game的连接处理服务,运行在独立的线程中

typedef struct togrpgame{
	engine_t            p;
	kn_thread_t         t;
	kn_thread_mailbox_t mailbox;
	stream_conn_t       togroup;
}togrpgame;


int     start_togrpgame();
void    stop_togrpgame();
int     mail2togrpgame(void*,void (*fn_destroy)(void*));

extern togrpgame * g_togrpgame;

#endif
