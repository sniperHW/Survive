#ifndef _BATTLESERVICE_H
#define _BATTLESERVICE_H

#include "core/asynnet/msgdisp.h"
#include "core/thread.h"
#include "llist.h"
#include "db/asyndb.h"
#include "../avatar.h"
#include "core/kn_string.h"
#include "core/lua_util.h"
#include "core/timer.h"
#include "common/cmd.h"

#define	MAX_BATTLE_SERVICE 64//每线程运行一个battle service

typedef struct battleservice
{
	volatile uint8_t   stop;
	thread_t           thd;
	msgdisp_t          msgdisp;
	atomic_32_t        player_count;    //此service上的玩家数量
	luaObject_t        battlemgr;       //实际的战场由lua对象管理
}*battleservice_t;

extern battleservice_t g_battleservices[MAX_BATTLE_SERVICE];

battleservice_t new_battleservice();
void destroy_battleservice(battleservice_t);

void reg_battle_cmd_handler(uint16_t cmd,cmd_handler_t handler);
void build_battle_cmd_handler();
void register_battle_cfunction(lua_State *L);

battleservice_t get_battle_by_index(uint8_t);



#endif
