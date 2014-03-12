#ifndef _AVATAR_H
#define _AVATAR_H

#include "core/asynnet/msgdisp.h"
#include "common/agentsession.h"
#include "core/refbase.h"
#include "core/kn_string.h"
#include "core/rpacket.h"
#include "core/wpacket.h"

#define MAX_PLAYER    8191*8  //superservice最多容纳8191*8个玩家对象

typedef struct avatarid{	
	union{
		struct{
			uint32_t battleservice_id:5; //最多允许32个battleservice       
			uint32_t map_id:9;           //一个battleservice最大允许创建512张地图
			uint32_t ojb_index:10;       //每张地图最多允许1023个对象
			uint32_t check:8;            //一个简单的校验值
		};
		uint32_t     data;
	};
}avatarid;

enum{
	normal  = 0,   
	playing = 1,   //战场中
	queueing,      //战场排队中   
	logout,        //请求登出
};

typedef struct player{
	struct refbase ref;
	agentsession _agentsession;
	string_t     _actname;
	msgdisp_t    _msgdisp;
	uint16_t     _index;
	uint8_t      _status;
}player,*player_t;

static inline avatarid rpk_read_avatarid(rpacket_t rpk)
{
	avatarid _avatarid;
	_avatarid.data = rpk_read_uint32(rpk);
	return _avatarid;
}

static inline avatarid rpk_reverse_read_avatarid(rpacket_t rpk)
{
	avatarid _avatarid;
	_avatarid.data = reverse_read_uint32(rpk);
	return _avatarid;	
}

static inline void wpk_write_avatarid(wpacket_t wpk,avatarid _avatarid)
{
	wpk_write_uint32(wpk,_avatarid.data);
}

player_t idx2player(uint16_t index);

//增加玩家对象的引用计数
void     player_incref(player_t _player);

//减少玩家对象的引用计数
void     player_decref(player_t _player);

#endif
