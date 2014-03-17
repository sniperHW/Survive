#include "superservice.h"
#include "../battleservice/map.h"
#include "gamedb.h"
#include <stdlib.h>
#include <stdio.h>
#include "common/tls_define.h"
#include "core/tls.h"
#include "../battleservice/battleservice.h"
#include "core/lua_util.h"
#include "core/asynnet/asyncall.h"


struct st_ply{
	player_t player;
	string_t attr;
	string_t skill;
	string_t item;
};

struct st_enter_context
{
	 asyncall_context base_context;
	 uint32_t battleid;
	 uint16_t len;
	 struct st_ply plys[];
};

void st_enter_context_free(asyncall_context_t c)
{
	struct st_enter_context *context = (struct st_enter_context*)c;
	uint16_t i = 0;
	for(; i < context->len;++i){ 
		if(context->plys[i].attr) release_string(context->plys[i].attr);
		if(context->plys[i].skill) release_string(context->plys[i].skill);
		if(context->plys[i].item) release_string(context->plys[i].item);
	}	
	free(context);	
}

static int enter_battle_map(lua_State *L){
	uint8_t  serviceid = (uint8_t)lua_tonumber(L,-1);
	uint32_t battleid = (uint32_t)lua_tonumber(L,-2);
	int len = lua_objlen(L,-3);
	struct st_enter_context *context = calloc(1,sizeof(*context)+sizeof(struct st_ply)*len);
	context->battleid = battleid;
	context->len = (uint16_t)len;
	int i = 1;
	for(; i <= len; ++i)
	{
		lua_rawgeti(L,-3-i+1,i);
		luaObject_t o = create_luaObj(L,-1);
		context->plys[i-1].player = GET_OBJ_FIELD(o,"ply",player_t,lua_touserdata);
		context->plys[i-1].attr = new_string(GET_OBJ_FIELD(o,"attr",const char *,lua_tostring));
		context->plys[i-1].skill = new_string(GET_OBJ_FIELD(o,"skill",const char *,lua_tostring));
		context->plys[i-1].item = new_string(GET_OBJ_FIELD(o,"item",const char *,lua_tostring));
		release_luaObj(o);
	}
	
	battleservice_t service = get_battle_by_index(serviceid);
	((struct asyncall_context*)context)->fn_free = st_enter_context_free;
	
	msgdisp_t from = (msgdisp_t)tls_get(MSGDISCP_TLS);
	msgdisp_t to = service->msgdisp;
	if(0 != ASYNCALL3(from,to,asyncall_enter_battle,context,NULL,battleid,context->plys,len))
	{
		st_enter_context_free((struct asyncall_context*)context);
	}
	return 0;	
}


void reg_super_clua_function(lua_State *L)
{
	lua_register(L,"enter_battle_map",&enter_battle_map);
}
