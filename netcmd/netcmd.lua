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
	CMD_SC_NOTIATKSUFFER2 = NextCmdNum(),
	CMD_SC_ATTRUPDATE = NextCmdNum(),
	CMD_SC_BUFFBEGIN = NextCmdNum(),
	CMD_SC_BUFFEND = NextCmdNum(),
	CMD_SC_DIR = NextCmdNum(),
	--CMD_SC_CREATE_ERROR = NextCmdNum(),	
	CMD_SC_END = NextCmdNum(),
	--client <-> group
	
	CMD_CG_BEGIN = SetCmdNum(400),
	CMD_CG_CREATE = NextCmdNum(),
	CMD_CG_ENTERMAP = NextCmdNum(),
	CMD_CG_LEAVEMAP = NextCmdNum(),
	CMD_CG_PMAP_BALANCE = NextCmdNum(),
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
	CMD_CC_CONNECT_SUCCESS = 65534,
   	CMD_CC_CONNECT_FAILED = 65533,
   	CMD_CC_DISCONNECTED = 65532, 	 				
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


