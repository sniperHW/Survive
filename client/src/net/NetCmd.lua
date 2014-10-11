local cmdCA = 0     --client -> agent
local cmdAC = 100   --agent -> client
local cmdCS = 200   --client -> game
local cmdSC = 300   --game -> client
local cmdCG = 400   --client -> group
local cmdGC = 500   --group -> client

local function ENUM_CMD(cmdBegin)
    local cmd = cmdBegin
    return function() 
                cmd = cmd + 1 
                return cmd 
            end
end

--client <-> agent
local ENUM = ENUM_CMD(cmdCA)
CMD_CA_LOGIN        = ENUM()
CMD_CA_END          = ENUM()

ENUM = ENUM_CMD(cmdAC)
CMD_AC_END          = ENUM()


--client <-> game
ENUM = ENUM_CMD(cmdCS)
CMD_CS_MOV          = ENUM()
CMD_CS_USESKILL     = ENUM()
CMD_CS_END          = ENUM()

ENUM = ENUM_CMD(cmdSC)
CMD_SC_ENTERMAP     = ENUM()
CMD_SC_ENTERSEE     = ENUM()
CMD_SC_LEAVESEE     = ENUM()
CMD_SC_MOV          = ENUM()
CMD_SC_MOV_ARRI     = ENUM()
CMD_SC_MOV_FAILED   = ENUM()
CMD_SC_NOTIATK      = ENUM()
CMD_SC_NOTIATKSUFFER= ENUM()
CMD_SC_NOTISUFFER   = ENUM()
CMD_SC_ATTRUPDATE   = ENUM()
CMD_SC_END          = ENUM()

--client <-> group
ENUM = ENUM_CMD(cmdCG)
CMD_CG_CREATE       = ENUM()
CMD_CG_ENTERMAP     = ENUM()
CMD_CG_END          = ENUM()

ENUM = ENUM_CMD(cmdGC)
CMD_GC_CREATE       = ENUM()
CMD_GC_BEGINPLY     = ENUM()
CMD_GC_ATTRUPDATE   = ENUM()
CMD_GC_ERROR        = ENUM()
CMD_GC_END          = ENUM()  

CMD_CC_CONNECT_SUCCESS= 65534
CMD_CC_CONNECT_FAILED = 65533
CMD_CC_DISCONNECTED = 65532
return nil
