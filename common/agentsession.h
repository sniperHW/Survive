#ifndef _AGENTSESSION_H
#define _AGENTSESSION_H
#include <stdint.h>
#include "core/asynnet/asynnet.h"
#include "core/kn_string.h"

typedef struct agentsession{
	union{
		struct{
			uint32_t aid:3;            //agentservice的编号0-7
			uint32_t sessionid:14;     //用户在agentservice中的下标,1-8191
			uint32_t identity:15;      
		};
		uint32_t     data;
	};
}agentsession;

enum
{
	agent_unusing = 0,  //没被分配
	agent_init,
	agent_verifying,    //等待账号验证
	agent_playing,      //正在游戏
	agent_creating,     //正在创建账号信息
};

//gateserver中的用户表示结构
typedef struct agentplayer{
	ident        gameident;
	agentsession session;
	uint16_t     identity;
	uint8_t      state;
	sock_ident   con;        //到客户端的通信连接
	string_t     actname;    //账号名
	uint32_t     avatarid;   //战场中的角色id
}agentplayer,*agentplayer_t;

#endif
