#include "lua_util.h"
#include "kendynet.h"
#include "rpacket.h"
#include "wpacket.h"
#include "stream_conn.h"

static engine_t g_engine;

int lua_send(lua_State *L){
	stream_conn_t conn = lua_touserdata(L,1);
	wpacket_t wpk = lua_touserdata(L,2);
	if(0 == stream_conn_send(conn,(packet_t)wpk))
		lua_pushboolean(L,1);
	else
		lua_pushboolean(L,0);
	return 1;
}
