#ifndef _AVATAR_H
#define _AVATAR_H

#include "core/asynnet/msgdisp.h"
#include "common/agentsession.h"
#include "core/refbase.h"
#include "core/kn_string.h"
#include "core/rpacket.h"
#include "core/wpacket.h"
#include "core/lua_util.h"
#include "core/rbtree.h"

#define MAX_PLAYER    8191*8  //superservice最多容纳8191*8个玩家对象

enum{
	normal  = 0,   
	playing = 1,   //战场中
	loading,       //导入角色数据中
	queueing,      //战场排队中   
	logout,        //请求登出
};

typedef uint32_t avatarid;

typedef struct player{
	struct refbase ref;
	struct rbnode _rbnode;
	uint32_t      _agentsession;
	string_t      _actname;
	uint8_t       _status;
	luaObject_t   _luaply;
	//以下字段表示玩家在战场地图中的信息
	//int8_t       _battleserviceid;
	//int16_t      _mapid;
	//avatarid     _avatid;
}player,*player_t;

//增加玩家对象的引用计数
void     player_incref(player_t _player);

//减少玩家对象的引用计数
void     player_decref(player_t _player);

#endif
