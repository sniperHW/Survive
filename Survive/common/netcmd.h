#ifndef _NETCMD_H
#define _NETCMD_H


enum{
	//client <-> agent
	CMD_CA_BEGIN = 0,
	CMD_CA_LOGIN,
	CMD_CA_END,

	CMD_AC_BEGIN = 100,
	CMD_AC_END,

	//client <-> game
	CMD_CS_BEGIN = 200,
	CMD_CS_MOV,
	CMD_CS_END,

	CMD_SC_BEGIN = 300,
	CMD_SC_ENTERMAP,
	CMD_SC_ENTERSEE,
	CMD_SC_LEAVESEE,
	CMD_SC_MOV,
	CMD_SC_MOV_ARRI,
	CMD_SC_MOV_FAILED,
	CMD_SC_END,

	//client <-> group
	CMD_CG_BEGIN = 400,
	CMD_CG_CREATE,
	CMD_CG_ENTERMAP,  //请求进入地图
	CMD_CG_END,

	CMD_GC_BEGIN = 500,
	CMD_GC_CREATE,
	CMD_GC_BEGINPLY,
	CMD_GC_ERROR,
	CMD_GC_END,

	//gate <-> group
	CMD_AG_BEGIN = 600,
	CMD_AG_LOGIN,                     //gateserver进程登陆到group
	CMD_AG_PLYLOGIN,
	CMD_AG_CLIENT_DISCONN,            //客户端连接断开 
	CMD_AG_END,

	CMD_GA_BEGIN = 700,
	CMD_GA_NOTIFYGAME,
	CMD_GA_BUSY,
	CMD_GA_PLY_INVAILD,
	CMD_GA_CREATE,
	CMD_GA_END,

	//game <-> group

	CMD_GAMEG_BEGIN = 800,
	CMD_GAMEG_LOGIN,                  //gameserver进程登陆到group 
	CMD_GAMEG_END,

	CMD_GGAME_BEGIN = 900,
	//CMD_GGAME_ENTERMAP,
	//CMD_GGAME_LEAVEMAP,
	//CMD_GGAME_DESTROYMAP,
	CMD_GGAME_END,

	//game <-> gate

	CMD_AGAME_BEGIN = 1000,
	CMD_AGAME_LOGIN,                 //gateserver进程登陆到game 
	CMD_AGAME_CLIENT_DISCONN,        //客户端连接断开   
	CMD_AGAME_END,

	CMD_GAMEA_BEGIN = 1100,
	CMD_GAMEA_LOGINRET,              //gameserver对gate login的响应
	CMD_GAMEA_END,

	//dummy cmd
	DUMMY_ON_GATE_DISCONNECTED = 1200,
	DUMMY_ON_GAME_DISCONNECTED,
	
	//rpc
	CMD_RPC_CALL = 1300,
	CMD_RPC_RESPONSE,
};



/*enum{
	//客户端到服务端
	CMD_CS_BEGPLY = 1,//玩家请求进入地图场景,
	CMD_CS_MOV,       //主角移动

	//服务端到客户端
	CMD_SC_BEGPLY,    //通知玩家进入地图场景成功，可以创建地图和主角
	CMD_SC_ENTERSEE,  //对象进入主角视野
	CMD_SC_LEVSEE,    //对象离开主角视野
	CMD_SC_ENDPLY,    //主角离开场景地图
	CMD_SC_MOV,       //对象移动

};*/





#endif
