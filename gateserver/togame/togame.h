#ifndef _TOGAME_H
#define _TOGAME_H

#include "common/agentsession.h"
#include "core/asynnet/msgdisp.h"
#include "core/thread.h"

typedef struct toGame
{
	volatile uint8_t stop;
	thread_t    thd;            //运行本agentservice的线程
	struct      llist idpool;
	msgdisp_t   msgdisp;
	sock_ident  togame;
}*toGame_t;

void send2game(wpacket_t wpk);

int32_t start_togame_service(asynnet_t asynet);

void    stop_togame_service();

#endif
