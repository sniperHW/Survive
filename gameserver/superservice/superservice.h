#ifndef _SUPERSERVICE_H
#define _SUPERSERVICE_H

#include "core/asynnet/msgdisp.h"
#include "core/thread.h"
#include "llist.h"
#include "db/asyndb.h"
#include "../avatar.h"
#include "core/kn_string.h"
#include "common/cmd.h"

typedef struct superservice
{
	volatile uint8_t   stop;
	thread_t           thd;
	msgdisp_t          msgdisp;
	sock_ident         togate;   //到gate的套接口
	asyndb_t           asydb; 
}*superservice_t;


extern superservice_t g_superservice;

superservice_t new_superservice();

void   destroy_superservice(superservice_t*);

int32_t send2gate(wpacket_t);

void reg_super_cmd_handler(uint16_t cmd,cmd_handler_t handler);
void build_super_cmd_handler();

player_t create_player(string_t actname,uint32_t gateident);

player_t find_player_by_actname(string_t actname);

#endif
