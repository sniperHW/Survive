#ifndef _GATEPLAYER_H
#define _GATEPLAYER_H

#include "kn_string.h"
#include "kn_ref.h"
#include "common/agentsession.h"

enum
{
	agent_unusing = 0,  //没被分配
	agent_init,
	agent_verifying,    //等待账号验证
	agent_playing,      //正在游戏
	agent_creating,     //正在创建账号信息
};

typedef struct battlesession{
	ident     tomap;     //到地图服务器的连接
	uint16_t  mapid;     //地图示例id
	uint16_t  objid;     //地图中对象id
}battlesession;

//gateserver中的用户表示结构
typedef struct agentplayer{
	agentsession    session;
	uint16_t        identity;
	ident           toclient;      //到客户端的连接
	battlesession*  battlesession;
	uint16_t        groupid;       //玩家在groupserver上的对象id
	uint8_t         state;
	kn_string_t     actname;       //帐号名 
}agentplayer,*agentplayer_t;

#endif