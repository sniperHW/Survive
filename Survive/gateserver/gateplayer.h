#ifndef _GATEPLAYER_H
#define _GATEPLAYER_H

#include "kn_string.h"
#include "kn_refobj.h"
#include "common/agentsession.h"
#include "stream_conn.h"

typedef enum{
	ply_init = 1,             //连接建立，等待玩家输入用户名密码  
	ply_wait_verify,          //玩家已经输入用户名和密码等待验证完成
	ply_wait_group_confirm,   //验证完毕等待group确认
	ply_create,               //创建角色
	ply_playing,              //玩家正常游戏中
	ply_destroy,              //正在销毁对象 
}plystate;


typedef struct agentplayer{
	refobj           ref;
	agentsession     agentsession;
	stream_conn_t    toclient;
	ident            togame;
	uint32_t         gameid;
	uint32_t         groupid;
	kn_string_t      actname;
	plystate         state;
}agentplayer,*agentplayer_t;

#endif
