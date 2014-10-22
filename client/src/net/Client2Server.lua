local netCmd = require "src.net.NetCmd"

function CMD_LOGIN(name, pass, logintype)		
	local wpk = GetWPacket()
    WriteUint16(wpk, netCmd.CMD_CA_LOGIN)
    WriteUint8(wpk, 1)
    WriteString(wpk, name)
    SendWPacket(wpk)		
end

function CMD_CREATE(avatartype,nickname,weapon)
    local wpk = GetWPacket()
    WriteUint16(wpk, netCmd.CMD_CG_CREATE)
    WriteUint8(wpk, avatartype)
    WriteString(wpk, nickname)
    WriteUint8(wpk, weapon)
    SendWPacket(wpk)
end

function CMD_ENTERMAP(maptype)
    local wpk = GetWPacket()
    WriteUint16(wpk, netCmd.CMD_CG_ENTERMAP)
    WriteUint8(wpk, 1)	
    SendWPacket(wpk)    
end

function CMD_MOV(pos)
    local wpk = GetWPacket()
    WriteUint16(wpk, netCmd.CMD_CS_MOV)
    WriteUint16(wpk, pos.x)
    WriteUint16(wpk, pos.y)
    SendWPacket(wpk)
end

function CMD_USESKILL(skillid,target)
    local wpk = GetWPacket()
    WriteUint16(wpk, netCmd.CMD_CS_USESKILL)
    WriteUint16(wpk, skillid)
	WriteUint32(wpk, target)
    WriteUint32(wpk, os.clock() * 1000)
    SendWPacket(wpk)
end

function CMD_USESKILL_DIR(skillid,dir,targets)
    local wpk = GetWPacket()
    WriteUint16(wpk, netCmd.CMD_CS_USESKILL)
    WriteUint16(wpk,dir) 
    WriteUint8(wpk,#targets)
    for k,v in pairs(targets) do
        WriteUint32(wpk,v)
    end   
    SendWPacket(wpk)	
end

function CMD_USESKILL_POINT(x,y,targets)
    local wpk = GetWPacket()
    WriteUint16(wpk, netCmd.CMD_CS_USESKILL)
    WriteUint16(wpk,x)
    WriteUint16(wpk,y) 
    WriteUint8(wpk,#targets)
    for k,v in pairs(targets) do
        WriteUint32(wpk,v)
    end       
    SendWPacket(wpk)
end



