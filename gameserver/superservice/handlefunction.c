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
			player_decref(ply);	
		}
		player_decref(ply);
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
			player_incref(ply);//增加引用计数，防止ply被意外释放
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
			player_decref(ply);
		}
	}
}


//玩家请求登出
void player_logout(rpacket_t rpk,player_t ply)
{

}


/*请求进入战场，如果请求进入的是大地图则选择一个让玩家进入。
* 否则进入配对系统，配对完成后进入
*/
void enter_battle(rpacket_t rpk,player_t ply)
{
	uint16_t mapid = rpk_read_uint16(rpk);
	struct mapdefine *mapdef = get_mapdefine_byid(mapid);
	if(mapdef){
		if(mapdef->maptype == map_open){
			//开放地图
			uint32_t battleservid = get_openinstance_byid(mapid);
			if(battleservid == 0){
				//随机挑选一个battleservice
			}else{
				battleservice_t battle = get_battle_by_index((uint8_t)(battleservid >> 16));
				uint32_t mapindex = battleservid/65536;
				//让玩家进入battle的mapindex
			}		
		}else{
			//进入配对系统
		}
	}
}
