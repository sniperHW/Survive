#include "superservice.h"
#include "../battleservice/map.h"

void load_ply_info_cb(struct db_result *result)
{
	//数据导入后的回调函数
	player_t ply = result->ud;
	if(result->err == 0){
		//成功，通知gate
	}else{
		//失败,通知gate

		//释放player
	}
}

static void load_player_info(player_t ply);

void player_login(rpacket_t rpk,player_t ply)
{
	uint32_t gateident = rpk_read_uint32(rpk);
	string_t actname = rpk_read_string(rpk);
	player_t ply = find_player_by_actname(actname);
	if(ply){
		//对象还未销毁，重新绑定关系
		
	}else{
		ply = create_player(actname,gateident);
		if(!ply){
			//通知玩家系统繁忙
			wpacket_t wpk = wpk_create(64,0);
			wpk_write_uint16(wpk,CMD_GAME2GATE_BUSY);
			wpk_write_uint32(wpk.gateident);
			send2gate(wpk);
			return;
		}
		load_player_info(ply);//从数据库导入玩家信息
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
