function CMD_LOGIN(name, pass, logintype)		
	local wpk = GetWPacket()
    WriteUint16(wpk, CMD_CA_LOGIN)
    WriteUint8(wpk, 1)
    WriteString(wpk, name)
    SendWPacket(wpk)		
end

function CMD_CREATE(avatartype,nickname,weapon)
	local wpk = new_wpk()
	wpk_write_uint8(avatartype)
	wpk_write_string(nickname)
	wpk_wriate_uint8(weapon)		
end

function CMD_ENTERMAP(maptype)
    local wpk = GetWPacket()
    WriteUint16(wpk, CMD_CG_ENTERMAP)
    WriteUint8(wpk, 1)	
    SendWPacket(wpk)    
end

function CMD_MOV(pos)
    local wpk = GetWPacket()
    WriteUint16(wpk, CMD_CS_MOV)
    WriteUint16(wpk, pos.x)
    WriteUint16(wpk, pos.y)
    SendWPacket(wpk)
end

function CMD_USESKILL(skillid,target)
    local wpk = GetWPacket()
    WriteUint16(wpk, CMD_CS_USESKILL)
    WriteUint16(wpk, skillid)
	WriteUint32(wpk, target)
    SendWPacket(wpk)
end

function CMD_USESKILL_DIR(skillid,dir)
    local wpk = GetWPacket()
    WriteUint16(wpk, CMD_CS_USESKILL)
    WriteUint8(dir)    
    SendWPacket(wpk)	
end

function CMD_USESKILL_POINT(x,y)
    local wpk = GetWPacket()
    WriteUint16(wpk, CMD_CS_USESKILL)
    WriteUint16(x)
    WriteUint16(y)  
    SendWPacket(wpk)
end



