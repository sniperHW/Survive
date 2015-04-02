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
	CMD_CS_PICKUP    = NextCmdNum(),  
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
	CMD_SC_NOTIATKSUFFER2 = NextCmdNum(),
	CMD_SC_ATTRUPDATE = NextCmdNum(),
	CMD_SC_BUFFBEGIN = NextCmdNum(),
	CMD_SC_BUFFEND = NextCmdNum(),
	CMD_SC_DIR = NextCmdNum(),
	CMD_SC_NOTI_5PVE_ROUND = NextCmdNum(),
	CMD_SC_5PVE_RESULT = NextCmdNum(),
	CMD_SC_5PVP_RESULT = NextCmdNum(),
	CMD_SC_TRANSFERMOVE = NextCmdNum(),
	CMD_SC_BAGUPDATE = NextCmdNum(),
	CMD_SC_BOOM = NextCmdNum(),
	CMD_SC_SURVIVE_WIN = NextCmdNum(),
	CMD_SC_UPDATEWEAPON = NextCmdNum(),
	--CMD_SC_CREATE_ERROR = NextCmdNum(),	
	CMD_SC_END = NextCmdNum(),
	--client <-> group
	
	CMD_CG_BEGIN = SetCmdNum(400),
	CMD_CG_CREATE = NextCmdNum(),
	CMD_CG_ENTERMAP = NextCmdNum(),
	CMD_CG_LEAVEMAP = NextCmdNum(),
	CMD_CG_PVE_GETAWARD = NextCmdNum(),
	CMD_CG_USEITEM = NextCmdNum(),
	CMD_CG_REMITEM = NextCmdNum(),
	CMD_CG_SWAP = NextCmdNum(),
	CMD_CG_ADDPOINT = 	NextCmdNum(),
	CMD_CG_CHAT = NextCmdNum(),
	CMD_CG_HOMEACTION = NextCmdNum(),
	CMD_CG_HOMEBALANCE = NextCmdNum(),
	CMD_CG_EQUIP_UPRADE = NextCmdNum(),
	CMD_CG_EQUIP_ADDSTAR = NextCmdNum(),
	CMD_CG_EQUIP_INSET = NextCmdNum(),
	CMD_CG_EQUIP_UNINSET = NextCmdNum(),
	CMD_CG_LOADBATTLEITEM = NextCmdNum(),
	CMD_CG_UNLOADBATTLEITEM = NextCmdNum(),
	CMD_CG_UPGRADESKILL = NextCmdNum(),
	CMD_CG_UNLOCKSKILL = NextCmdNum(),
	CMD_CG_EVERYDAYSIGN = NextCmdNum(),
	CMD_CG_EVERYDAYTASK = NextCmdNum(),
	CMD_CG_EVERYDAYTASK_GETAWARD = NextCmdNum(),
	CMD_CG_COMMIT_INTRODUCE_STEP = NextCmdNum(), --提交新手引导步骤
	CMD_CG_COMMIT_SPVE = NextCmdNum(),                        --提交单人PVE关卡
	CMD_CG_ACHIEVE = NextCmdNum(),
	CMD_CG_ACHIEVE_AWARD = NextCmdNum(),
	CMD_CG_COMPOSITE = NextCmdNum(),                              --合成
	CMD_CG_FRIEND_ADD = NextCmdNum(),                             --添加好友/黑名单
	CMD_CG_FRIEND_REMOVE = NextCmdNum(),                      --移除好友/黑名单
	CMD_CG_FRIEND_PEEKINFO = NextCmdNum(),                    --查看好友信息
	CMD_CG_FRIEND_GETALL     = NextCmdNum(),                     --获得好友列表
	CMD_CG_STONE_COMPOSITE = NextCmdNum(),                  --宝石合成
	CMD_CG_SINGLE_USE_ITEM = NextCmdNum(),
	CMD_CG_SURVIVE_APPLY = NextCmdNum(),
	CMD_CG_SURVIVE_CONFIRM = NextCmdNum(),
	CMD_CG_GETMAILLIST = NextCmdNum(),
	CMD_CG_MAILMARKREAD = NextCmdNum(),
	CMD_CG_MAILGETATTACH = NextCmdNum(),
	CMD_CG_MAILDELETE = NextCmdNum(),
	CMD_CG_END = NextCmdNum(), 
	
	CMD_GC_BEGIN = SetCmdNum(500),
	CMD_GC_CREATE = NextCmdNum(),
	CMD_GC_BEGINPLY = NextCmdNum(), 
	CMD_GC_ATTRUPDATE = NextCmdNum(), 
	CMD_GC_BACK2MAIN = NextCmdNum(),
	CMD_GC_ENTERPSMAP = NextCmdNum(),
	CMD_GC_BAGUPDATE = NextCmdNum(),
	CMD_GC_ERROR = NextCmdNum(), 
	CMD_GC_HOMEACTION_RET = NextCmdNum(),
	CMD_GC_HOMEBALANCE_RET = NextCmdNum(),
	CMD_GC_SKILLUPDATE = NextCmdNum(),
	CMD_GC_ADDSKILL = NextCmdNum(),	
	CMD_GC_NOTIOPSUCCESS = NextCmdNum(),
	CMD_GC_EVERYDAYSIGN = NextCmdNum(),
	CMD_GC_EVERYDAYTASK = NextCmdNum(),
	CMD_GC_EVERTDAYTASK_AWARD = NextCmdNum(),
	CMD_GC_ACHIEVE = NextCmdNum(),
	CMD_GC_FRIEND_LIST = NextCmdNum(),
	CMD_GC_FRIEND_INFO = NextCmdNum(),
	CMD_GC_CREATE_ERROR = NextCmdNum(),
	CMD_GC_SURVIVE_APPLY = NextCmdNum(),
	CMD_GC_SURVIVE_CONFIRM = NextCmdNum(),
	CMD_GC_MAILLIST = NextCmdNum(),
	CMD_GC_NEWMAIL = NextCmdNum(),
	CMD_GC_CHAT = NextCmdNum(),	
	CMD_GC_END = NextCmdNum(),
	--group <-> gate
	CMD_AG_BEGIN = 	SetCmdNum(600),
	CMD_AG_CLIENT_DISCONN = NextCmdNum(),
	CMD_AG_END = NextCmdNum(),
		
	CMD_GA_BEGIN = SetCmdNum(700),
	CMD_GA_NOTIFY_GAME = NextCmdNum(),
	CMD_GA_END = NextCmdNum(),
	
	--game <-> group

	CMD_GGAME_BEGIN = SetCmdNum(800),
	CMD_GGAME_CLIDISCONNECTED = NextCmdNum(),
	CMD_GGAME_END = NextCmdNum(),

	CMD_GAMEG_BEGIN = SetCmdNum(900),
	CMD_GAMEG_SURVIVE_FINISH = NextCmdNum(),
	CMD_GAMEG_PVPAWARD = NextCmdNum(),
	CMD_GAMEG_5PVEAWARD = NextCmdNum(),
	CMD_GAMEG_KICK = NextCmdNum(),
	CMD_GAMEG_END = NextCmdNum(),

	--dummy			 		
	CMD_CC_CONNECT_SUCCESS = 65534,
   	CMD_CC_CONNECT_FAILED = 65533,
   	CMD_CC_DISCONNECTED = 65532, 
   	CMD_CC_SPVE_RESULT = 65531,
   	CMD_CC_PING = 65530 	 				
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

noti_equipupgrade_success = 1
noti_equipaddstar_success = 2
noti_equipinst_success = 3
noti_equipuninst_success = 4

return netcmd


