local cmd_num = 0

local function SetCmdNum(num)
	cmd_num = num
	return cmd_num
end

local function NextCmdNum()
	cmd_num = cmd_num + 1
	return cmd_num
end

local netCmd = {
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
	CMD_SC_BUFFBEGIN = NextCmdNum(),
	CMD_SC_BUFFEND = NextCmdNum(),
	--CMD_SC_CREATE_ERROR = NextCmdNum(),	
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

	CMD_CC_CONNECT_SUCCESS= 65534,
	CMD_CC_CONNECT_FAILED = 65533,
	CMD_CC_DISCONNECTED = 65532
}

return netCmd
