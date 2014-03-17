#include "superservice.h"
#include "../battleservice/map.h"
#include "gamedb.h"
#include "hiredis.h"
#include <stdlib.h>
#include <stdio.h>
#include "common/tls_define.h"
#include "core/tls.h"
#include "../battleservice/battleservice.h"
#include "core/lua_util.h"
void remove_player(player_t ply);
//向gate发送短通告消息
void shortmsg2gate(uint16_t cmd,uint32_t gateident){
	wpacket_t wpk = wpk_create(64,0);
	wpk_write_uint16(wpk,cmd);
	wpk_write_uint32(wpk,gateident);
	send2gate(wpk);		
}

void load_ply_info_cb(struct db_result *result)
{
	//数据导入后的回调函数
	if(result){
		player_t ply = result->ud;
		if(result->result_set){
			redisReply *r = (redisReply*)result->result_set;	
			if(r->type != REDIS_REPLY_NIL){
				lua_State *L = tls_get(LUASTATE);
				if(0 != CALL_LUA_FUNC2(L,"CreateLuaPlayer",1,
						               PUSH_LUSRDATA(L,ply),
									   PUSH_TABLE3(L,
									   PUSH_STRING(L,r->element[0]->str),
									   PUSH_STRING(L,r->element[1]->str),
									   PUSH_STRING(L,r->element[2]->str))))
				{
					const char * error = lua_tostring(L, -1);
					lua_pop(L,1);
					printf("%s\n",error);
				}else
					ply->_luaply = create_luaObj(L,-1);							
			}else{
				//没有角色，通知客户端创建角色
				shortmsg2gate(CMD_GAME2C_CREATE,ply->_agentsession);					
			}
		}else{
			//数据库访问出错
			shortmsg2gate(CMD_GAME2GATE_BUSY,ply->_agentsession);	
			remove_player(ply);	
		}
	}
}

static int32_t load_player_info(player_t ply)
{
	if(ply->_status == normal){
		char str[256];
		snprintf(str,256,"hmget %s attr,bag,skill",to_cstr(ply->_actname));
		int32_t ret = gamedb_request(ply,new_dbrequest(str,load_ply_info_cb,ply,tls_get(MSGDISCP_TLS)));
		if(ret == 0){ 
			ply->_status = loading;
		}
		return ret;
	}
	return 0;
}

void player_login(rpacket_t rpk,player_t ply)
{
	uint32_t gateident = rpk_read_uint32(rpk);
	const char *actname = rpk_read_string(rpk);
	ply = find_player_by_actname(actname);
	if(ply){
		//对象还未销毁
		if(ply->_agentsession != 0){
			//通知gate直接断掉连接
			shortmsg2gate(CMD_GAME2GATE_INVID_CON,gateident);
		}else{
			//重新绑定
		}		
	}else{
		ply = create_player(actname,gateident);
		if(!ply){
			//通知玩家系统繁忙
			shortmsg2gate(CMD_GAME2GATE_BUSY,gateident);
			return;
		}
		if(0 != load_player_info(ply)){
			shortmsg2gate(CMD_GAME2GATE_BUSY,gateident);
			remove_player(ply);
		}
	}
}


//玩家请求登出
void player_logout(rpacket_t rpk,player_t ply)
{

}
