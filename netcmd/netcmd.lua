--[[
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
	CMD_CS_USESKILL,
	CMD_CS_END,

	CMD_SC_BEGIN = 300,
	CMD_SC_ENTERMAP,
	CMD_SC_ENTERSEE,
	CMD_SC_LEAVESEE,
	CMD_SC_MOV,
	CMD_SC_MOV_ARRI,
	CMD_SC_MOV_FAILED,
	CMD_SC_NOTIATK,        
	CMD_SC_NOTIATKSUFFER,   
	CMD_SC_NOTISUFFER,      
	CMD_SC_ATTRUPDATE,
	CMD_SC_END,

	//client <-> group
	CMD_CG_BEGIN = 400,
	CMD_CG_CREATE,
	CMD_CG_ENTERMAP,  
	CMD_CG_END,

	CMD_GC_BEGIN = 500,
	CMD_GC_CREATE,
	CMD_GC_BEGINPLY,
	CMD_GC_ATTRUPDATE,
	CMD_GC_ERROR,
	CMD_GC_END,

	//gate <-> group
	CMD_AG_BEGIN = 600,
	CMD_AG_LOGIN,                  
	CMD_AG_PLYLOGIN,
	CMD_AG_CLIENT_DISCONN,       
	CMD_AG_END,

	CMD_GA_BEGIN = 700,
	CMD_GA_NOTIFYGAME,
	CMD_GA_BUSY,
	CMD_GA_PLY_INVAILD,
	CMD_GA_CREATE,
	CMD_GA_END,

	//game <-> group

	CMD_GAMEG_BEGIN = 800,
	CMD_GAMEG_LOGIN,                  
	CMD_GAMEG_END,

	CMD_GGAME_BEGIN = 900,
	CMD_GGAME_CLIDISCONNECTED,
	//CMD_GGAME_ENTERMAP,
	//CMD_GGAME_LEAVEMAP,
	//CMD_GGAME_DESTROYMAP,
	CMD_GGAME_END,

	//game <-> gate

	CMD_AGAME_BEGIN = 1000,
	CMD_AGAME_LOGIN,                 
	CMD_AGAME_END,

	CMD_GAMEA_BEGIN = 1100,
	CMD_GAMEA_LOGINRET,              
	CMD_GAMEA_END,

	//dummy cmd
	DUMMY_ON_GATE_DISCONNECTED = 1200,
	DUMMY_ON_GAME_DISCONNECTED,
	DUMMY_ON_CHAT_CONNECTED,
	DUMMY_ON_DAEMON_DISCONNECTED,
	DUMMY_ON_ROUTER_CONNECTED,
	DUMMY_ON_ROUTER_DISCONNECTED,   
	DUMMY_ON_MG_DISCONNECTED,    //管理客户端断开连接	
	//rpc
	CMD_RPC_CALL = 1300,
	CMD_RPC_RESPONSE,
	
	//管理系统
	//router <-> daemon	
	CMD_MG_LOGIN = 1400, //登录管理系统
	CMD_MG_START,        //启动进程
	CMD_MG_STOP,         //关闭进程
	CMD_MG_KILL,         //杀死进程
	CMD_MG_GET_MACHINE_INFO,//获取机器进程信息
	CMD_GM_GLOBAL_INFO,  //全局信息
	CMD_GM_MACHINE_INFO, //机器进程信息
	CMD_GM_PROCESS_INFO, //具体进程信息	
};
#endif
]]--

local cmd_num = 0

local function SetCmdNum(num)
	cmd_num = num
	return cmd_num
end

local function NextCmdNum()
	cmd_num = cmd_num + 1
	return cmd_num
end

local netcmd = {
	--client <-> gate
	CMD_CA_BEGIN = SetCmdNum(0),
	CMD_CA_LOGIN = NextCmdNum(),
	CMD_CA_END = NextCmdNum(),
	
	
	--client <-> game
	CMD_CS_BEGIN = SetCmdNum(200),
	CMD_CS_MOV = NextCmdNum(),
	CMD_CS_USESKILL = NextCmdNum(),
	CMD_CS_END = NextCmdNum(),
	
	CMD_SC_BEGIN = SetCmdNum(300),
	CMD_SC_ENTERMAP = NextCmdNum(),
	CMD_SC_ENTERSEE = NextCmdNum(),
	CMD_SC_LEAVESEE = NextCmdNum(),
	CMD_SC_MOV = NextCmdNum(),
	CMD_SC_MOV_ARRI = NextCmdNum(),
	CMD_SC_MOV_FAILED = NextCmdNum(),
	CMD_SC_NOTIATK = NextCmdNum(),
	CMD_SC_NOTIATKSUFFER = NextCmdNum(),   
	CMD_SC_NOTISUFFER = NextCmdNum(),      
	CMD_SC_ATTRUPDATE = NextCmdNum(),
	CMD_SC_CREATE_ERROR = NextCmdNum(),	
	CMD_SC_END = NextCmdNum(),
	--client <-> group
	
	CMD_CG_BEGIN = SetCmdNum(400),
	CMD_CG_CREATE = NextCmdNum(),
	CMD_CG_ENTERMAP = NextCmdNum(),
	CMD_CG_END = NextCmdNum(), 
	
	CMD_GC_BEGIN = SetCmdNum(500),
	CMD_GC_CREATE = NextCmdNum(),
	CMD_GC_BEGINPLY = NextCmdNum(), 
	CMD_GC_ATTRUPDATE = NextCmdNum(), 
	CMD_GC_ERROR = NextCmdNum(), 
	CMD_GC_END = NextCmdNum(),
	--group <-> gate
	CMD_AG_BEGIN = 	SetCmdNum(600),
	CMD_AG_CLIENT_DISCONN = NextCmdNum(),
	CMD_AG_END = NextCmdNum(),
		
	CMD_GA_BEGIN = SetCmdNum(700),
	CMD_GA_NOTIFY_GAME = NextCmdNum(),
	CMD_GA_END = NextCmdNum(),
	
	--game <-> group

	CMD_GGAME_BEGIN = SetCmdNum(900),
	CMD_GGAME_CLIDISCONNECTED = NextCmdNum(),
	CMD_GGAME_END = NextCmdNum(),		 		
			
}

--用于生成netcmd.h文件
--[[local function GenC_NetCmd()
	local f = io.open("netcmd.h","w")	
	f:write("#ifndef _NETCMD_H\n#define _NETCMD_H\n")	
	f:write("enum{\n")	
	for k,v in pairs(netcmd) do
		if k ~= "GenC_NetCmd" then
			f:write("	" .. k .. " = " .. v .. ",\n")
		end
	end
	f:write("}\n")
	f:write("#endif\n")
	f:close()
end

netcmd.GenC_NetCmd = GenC_NetCmd
]]--

return netcmd


