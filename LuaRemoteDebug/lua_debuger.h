#ifndef _LUA_DEBUGER_H
#define _LUA_DEBUGER_H

#include "kendynet.h"
#include "lua/lua_util.h"
#include "rpacket.h"
#include "kn_stream_conn_server.h"

int ldebuger_init();

void ldebuger_processcmd(kn_stream_conn_t,rpacket_t);

#endif
