#ifndef _CMD_H
#define _CMD_H

#include "core/kn_string.h"
/*
*   命令码的定义
*/

enum{
	//客户端到网关
	CMD_C2GATE = 0,

	CMD_C2GATE_LOGIN,     //玩家登录
	CMD_C2GATE_CREATE,    //创建角色
	CMD_C2GATE_RECONNECT, //连接短暂掉了之后的重连
	
	CMD_C2GATE_END,

	//客户端到游戏服务器
	CMD_C2GAME = 100,
	CMD_ENTER_BATTLE,  //请求进入战场
	
	CMD_C2BATTLE,
	CMD_C2GAME_MOVE,   //客户端移动请求
	CMD_C2BATTLE_END,
	CMD_C2GAME_END,
	
	
	//网关到客户端
	CMD_GATE2C = 200,
	
	CMD_GATE2C_BUSY, //服务器繁忙
	CMD_GATE2C_VERIFY_FAILED,//帐号验证失败
	CMD_GATE2_END,
	
	//游戏服到客户端	
	CMD_GAME2C = 300,

	CMD_GAME2C_ENTERVIEW, //对象进入视野
	CMD_GAME2C_LEAVEVIEW, //对象离开视野
	
	CMD_GAME2C_END,

	//网关到游戏服
	CMD_GATE2GAME = 400,
	
	CMD_GATE2GAME_CDISCONNECT, //客户端连接断开
	CMD_GATE2GAME_LOGIN,
	
	CMD_GATE2GAME_END,

	//游戏服到网关
	CMD_GAME2GATE = 500,
	
	CMD_GAME2GATE_BUSY,
	
	CMD_GAME2GATE_END,
	
	MAX_CMD = 1024
};

struct rpacket;

enum{
	FN_C=1,
	FN_LUA,
};

struct player;

typedef struct cmd_handler{
	uint8_t _type;
	union{
		void (*_fn)(struct rpacket*,struct player*);//for C function
		string_t lua_fn;             //for lua function
	};
}*cmd_handler_t;

void call_handler(cmd_handler_t,struct rpacket*,struct player*);



#endif
