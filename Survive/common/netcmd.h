#ifndef _NETCMD_H
#define _NETCMD_H


enum{
	//client <-> agent
	CMD_CA_BEGIN = 1,
	CMD_CA_LOGIN,
	CMD_CA_END,

	CMD_AC_BEGIN = CMD_CA_BEGIN + 1,
	CMD_AC_END,

	//client <-> game
	CMD_CS_BEGIN = CMD_AC_END + 1,
	CMD_CS_END,

	CMD_SC_BEGIN = CMD_CS_END + 1,
	CMD_SC_END,

	//client <-> group
	CMD_CG_BEGIN = CMD_SC_END + 1,
	CMD_CG_CREATE,
	CMD_CG_END,

	CMD_GC_BEGIN = CMD_CG_END + 1,
	CMD_GC_CREATE,
	CMD_GC_BEGINPLY,
	CMD_GC_END,

	//gate <-> group
	CMD_AG_BEGIN = CMD_GC_END + 1,
	CMD_AG_LOGIN,   //gateserver进程登陆到group
	CMD_AG_PLYLOGIN,
	CMD_AG_END,

	CMD_GA_BEGIN = CMD_AG_END + 1,
	CMD_GA_BUSY,
	CMD_GA_END,

	//game <-> group

	CMD_GAMEG_BEGIN = CMD_GA_END + 1,
	CMD_GAMEG_LOGIN, //gameserver进程登陆到group 
	CMD_GAMEG_END,

	CMD_GGAME_BEGIB = CMD_GAMEG_END + 1,
	CMD_GGAME_END,

	//game <-> gate

	CMD_AGAME_BEGIN = CMD_GAMEG_END + 1,
	CMD_AGAME_LOGIN, //gateserver进程登陆到game 
	CMD_AGAME_END,

	CMD_GAMEA_BEGIN = CMD_AGAME_END + 1,
	CMD_GAMEA_END,

	//dummy cmd
	DUMMY_ON_GATE_DISCONNECTED = CMD_GAMEA_END + 1,
	DUMMY_ON_GAME_DISCONNECTED,
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