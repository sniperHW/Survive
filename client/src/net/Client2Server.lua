local netCmd = require "src.net.NetCmd"
UsePseudo = false
local Pseudo = require "src.pseudoserver.pseudoserver"

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
    WriteUint16(wpk, weapon)
    SendWPacket(wpk)
end

function CMD_ENTERMAP(maptype)
    local wpk = GetWPacket()
    WriteUint16(wpk, netCmd.CMD_CG_ENTERMAP)
    WriteUint8(wpk, maptype)	
    if UsePseudo then
        Pseudo.Send2Pseudo(wpk)
    else        
        SendWPacket(wpk)
    end   
end

function CMD_PMAP_BALANCE(maptype)
    local wpk = GetWPacket()
    WriteUint16(wpk, netCmd.CMD_CG_PMAP_BALANCE)
    WriteUint16(wpk, maptype)    
    SendWPacket(wpk)
end

function CMD_MOV(pos)
    local wpk = GetWPacket()
    WriteUint16(wpk, netCmd.CMD_CS_MOV)
    WriteUint16(wpk, pos.x)
    WriteUint16(wpk, pos.y)
    if UsePseudo then
        Pseudo.Send2Pseudo(wpk)
    else        
        SendWPacket(wpk)
    end    
end

function CMD_USESKILL(skillid,target)
    local wpk = GetWPacket()
    WriteUint16(wpk, netCmd.CMD_CS_USESKILL)
    WriteUint16(wpk, skillid)
    WriteUint32(wpk, os.clock() * 1000)        
	WriteUint32(wpk, target)
    if UsePseudo then
        Pseudo.Send2Pseudo(wpk)
    else        
        SendWPacket(wpk)
    end 
end

function CMD_USESKILL_DIR(skillid,dir,targets)
    local wpk = GetWPacket()
    WriteUint16(wpk, netCmd.CMD_CS_USESKILL)
    WriteUint16(wpk, skillid)
    WriteUint32(wpk, os.clock() * 1000)        
    WriteUint16(wpk,dir) 
    WriteUint8(wpk,#targets)
    for k,v in pairs(targets) do
        WriteUint32(wpk,v)
    end   
    if UsePseudo then
        Pseudo.Send2Pseudo(wpk)
    else        
        SendWPacket(wpk)
    end 	
end

function CMD_USESKILL_POINT(skillid, x,y,targets)
    local wpk = GetWPacket()
    WriteUint16(wpk, netCmd.CMD_CS_USESKILL) 
    WriteUint16(wpk, skillid)
    WriteUint32(wpk, os.clock() * 1000)       
    WriteUint16(wpk,x)
    WriteUint16(wpk,y) 
    WriteUint8(wpk,#targets)
    for k,v in pairs(targets) do
        WriteUint32(wpk,v)
    end       
    if UsePseudo then
        Pseudo.Send2Pseudo(wpk)
    else        
        SendWPacket(wpk)
    end 
end

function CMD_CG_USEITEM(pos)
        local wpk = GetWPacket()
        WriteUint16(wpk, netCmd.CMD_CG_USEITEM)
        WriteUint8(wpk,pos)
        SendWPacket(wpk)   
end

function CMD_CG_REMITEM(pos)
        local wpk = GetWPacket()
        WriteUint16(wpk, netCmd.CMD_CG_REMITEM)
        WriteUint8(wpk,pos)
        SendWPacket(wpk)   
end

function CMD_CG_SWAP(pos1,pos2)
        local wpk = GetWPacket()
        WriteUint16(wpk, netCmd.CMD_CG_SWAP)
        WriteUint8(wpk,pos1)
        WriteUint8(wpk,pos2)
        SendWPacket(wpk)   
end

function CMD_LEAVE_MAP()    --离开地图
    local wpk = GetWPacket()
    WriteUint16(wpk, netCmd.CMD_CG_LEAVEMAP)       
    if UsePseudo then
        Pseudo.Send2Pseudo(wpk)
    else        
        SendWPacket(wpk)
    end  
end

function CMD_ADDPOINT(power,endurance,constitution,agile,lucky,accurate)
    local wpk = GetWPacket()
    WriteUint16(wpk, netCmd.CMD_CG_ADDPOINT)   
    WriteUint16(wpk,power)
    WriteUint16(wpk,endurance)
    WriteUint16(wpk,constitution)
    WriteUint16(wpk,agile)
    WriteUint16(wpk,lucky)
    WriteUint16(wpk,accurate)
    SendWPacket(wpk)
end

function CMD_CHAT(target,str)
    local wpk = GetWPacket()
    WriteUint16(wpk, netCmd.CMD_CG_CHAT)
    WriteString(wpk,target or "all")   
    WriteString(wpk,str)
    SendWPacket(wpk) 
end

--1:fishing,2:gather,3:sit
function CMD_HOMEACTION(action)
    local wpk = GetWPacket()
    WriteUint16(wpk, netCmd.CMD_CG_HOMEACTION)   
    WriteUint8(wpk, action)
    SendWPacket(wpk) 
end

function CMD_HOMEBALANCE(action)
    local wpk = GetWPacket()
    WriteUint16(wpk, netCmd.CMD_CG_HOMEBALANCE)
    SendWPacket(wpk) 
end

--1:强化,2:锻造
function CMD_EQUIP_UPRADE(equip_pos)
    local wpk = GetWPacket()
    WriteUint16(wpk, netCmd.CMD_CG_EQUIP_UPRADE)
    --WriteUint8(wpk,type)
    WriteUint8(wpk, equip_pos)
    SendWPacket(wpk)     
end

function CMD_EQUIP_ADDSTAR(equip_pos)
    local wpk = GetWPacket()
    WriteUint16(wpk, netCmd.CMD_CG_EQUIP_ADDSTAR)
    WriteUint8(wpk, equip_pos)
    SendWPacket(wpk)     
end

function CMD_EQUIP_INSET(equip_pos,stone_pos,stone)
    local wpk = GetWPacket()
    WriteUint16(wpk, netCmd.CMD_CG_EQUIP_INSET)
    WriteUint8(wpk, equip_pos)
    WriteUint8(wpk, stone_pos)    
    WriteUint16(wpk, stone) 
    SendWPacket(wpk)     
end   

function CMD_CG_EQUIP_UNINSET(equip_pos,stone_pos)
    local wpk = GetWPacket()
    WriteUint16(wpk, netCmd.CMD_CG_EQUIP_UNINSET)
    WriteUint8(wpk, equip_pos)
    WriteUint8(wpk, stone_pos)
    SendWPacket(wpk)     
end

 function CMD_LOADBATTLEITEM(pos)
    local wpk = GetWPacket()
    WriteUint16(wpk, netCmd.CMD_CG_LOADBATTLEITEM)
    WriteUint8(wpk, pos)
    SendWPacket(wpk)     
end

 function CMD_UNLOADBATTLEITEM(pos)
    local wpk = GetWPacket()
    WriteUint16(wpk, netCmd.CMD_CG_UNLOADBATTLEITEM)
    WriteUint8(wpk, pos)
    SendWPacket(wpk)     
end
   
function CMD_UPGRADESKILL(skillid)
    local wpk = GetWPacket()
    WriteUint16(wpk, netCmd.CMD_CG_UPGRADESKILL)
    WriteUint16(wpk, skillid)
    SendWPacket(wpk)     
end

 function CMD_UNLOCKSKILL(skillid)
    local wpk = GetWPacket()
    WriteUint16(wpk, netCmd.CMD_CG_UNLOCKSKILL)
    WriteUint16(wpk, skillid)
    SendWPacket(wpk)     
end

 function CMD_EVERYDAYSIGN(skillid)
    local wpk = GetWPacket()
    WriteUint16(wpk, netCmd.CMD_CG_EVERYDAYSIGN)
    SendWPacket(wpk)     
end

 function CMD_EVERYDAYTASK(skillid)
    local wpk = GetWPacket()
    WriteUint16(wpk, netCmd.CMD_CG_EVERYDAYTASK)
    SendWPacket(wpk)     
end

function CMD_EVERYDAYTASK_GETAWARD(task)
    local wpk = GetWPacket()
    WriteUint16(wpk, netCmd.CMD_CG_EVERYDAYTASK_GETAWARD)
    WriteUint8(wpk,task)
    SendWPacket(wpk)     
end

function CMD_COMMIT_INTRODUCE_STEP(val)
    local wpk = GetWPacket()
    WriteUint16(wpk, netCmd.CMD_CG_COMMIT_INTRODUCE_STEP)
    WriteUint16(wpk,val)
    SendWPacket(wpk)     
end

 function CMD_COMMIT_COMMIT_SPVE(val)
    local wpk = GetWPacket()
    WriteUint16(wpk, netCmd.CMD_CG_COMMIT_SPVE)
    WriteUint16(wpk,val)
    SendWPacket(wpk)     
end

function CMD_ACHIEVE(val)
    local wpk = GetWPacket()
    WriteUint16(wpk, netCmd.CMD_CG_ACHIEVE)
    SendWPacket(wpk)     
end

function CMD_ACHIEVE_AWARD(id)
    local wpk = GetWPacket()
    WriteUint16(wpk, netCmd.CMD_CG_ACHIEVE_AWARD)
    WriteUint16(wpk,id)
    SendWPacket(wpk) 
end

function CMD_COMPOSITE(id,bagpos)
    local wpk = GetWPacket()
    WriteUint16(wpk, netCmd.CMD_CG_COMPOSITE)
    WriteUint16(wpk,id)
    WriteUint8(wpk, #bagpos)
    for i = 1, #bagpos do
        WriteUint8(wpk, bagpos[i])
    end
    SendWPacket(wpk) 
end

function CMD_PVE_GETAWARD()
    local wpk = GetWPacket()
    WriteUint16(wpk, netCmd.CMD_CG_PVE_GETAWARD)
    SendWPacket(wpk)    
end

--CMD_CG_STONE_COMPOSITE

function CMD_STONE_COMPOSITE(id,bagpos,all)
    local wpk = GetWPacket()
    WriteUint16(wpk, netCmd.CMD_CG_STONE_COMPOSITE)
    WriteUint16(wpk,id)
    WriteUint8(wpk, bagpos)
    WriteUint8(wpk,all)
    SendWPacket(wpk) 
end

function CMD_FRIEND_ADD(id,nickname)
    local wpk = GetWPacket()
    WriteUint16(wpk, netCmd.CMD_CG_FRIEND_ADD)
    WriteString(wpk,"friend")
    if id then
        WriteString("id")
        WriteUint32(wpk,id)        
    elseif nickname then
        WriteString("name")
        WriteString("nickname")
    end
    SendWPacket(wpk) 
end

function CMD_BLACK_ADD(id)
    local wpk = GetWPacket()
    WriteUint16(wpk, netCmd.CMD_CG_FRIEND_ADD)
    WriteString(wpk,"black")
    WriteString("id")
    WriteUint32(wpk,id)          
    SendWPacket(wpk) 
end

function CMD_FRIEND_REMOVE(id)
    local wpk = GetWPacket()
    WriteUint16(wpk, netCmd.CMD_CG_FRIEND_REMOVE)
    WriteString(wpk,"friend")    
    WriteUint32(wpk,id)
    SendWPacket(wpk) 
end

function CMD_BLACK_REMOVE(id)
    local wpk = GetWPacket()
    WriteUint16(wpk, netCmd.CMD_CG_FRIEND_REMOVE)
    WriteString(wpk,"black")
    WriteUint32(wpk,id)
    SendWPacket(wpk) 
end

function CMD_FRIEND_PEEKINFO(id)
    local wpk = GetWPacket()
    WriteUint16(wpk, netCmd.CMD_CG_FRIEND_PEEKINFO)
    WriteUint32(wpk,id)
    SendWPacket(wpk)     
end

function CMD_FRIEND_GETALL(id)
    local wpk = GetWPacket()
    WriteUint16(wpk, netCmd.CMD_CG_FRIEND_GETALL)
    SendWPacket(wpk)     
end

function CMD_SINGLE_USE_ITEM(bagpos)
    local wpk = GetWPacket()
    WriteUint16(wpk, netCmd.CMD_CG_SINGLE_USE_ITEM)
    WriteUint8(wpk, bagpos)
    SendWPacket(wpk)   
end

function CMD_SURVIVE_APPLY()
    local wpk = GetWPacket()
    WriteUint16(wpk, netCmd.CMD_CG_SURVIVE_APPLY)
    SendWPacket(wpk)   
end

function CMD_SURVIVE_CONFIRM(itemno)
    local wpk = GetWPacket()
    WriteUint16(wpk, netCmd.CMD_CG_SURVIVE_CONFIRM)
    WriteUint8(wpk,itemno)
    SendWPacket(wpk)   
end

function CMD_PICKUP(id)
    local wpk = GetWPacket()
    WriteUint16(wpk, netCmd.CMD_CS_PICKUP)
    WriteUint32(wpk,id)
    SendWPacket(wpk)   
end

function CMD_GETMAILLIST()
    local wpk = GetWPacket()
    WriteUint16(wpk, netCmd.CMD_CG_GETMAILLIST)
    SendWPacket(wpk)
end

function CMD_MAILMARKREAD(idx)
    local wpk = GetWPacket()
    WriteUint16(wpk, netCmd.CMD_CG_MAILMARKREAD)
    WriteString(wpk,idx)
    SendWPacket(wpk)
end

function CMD_MAILGETATTACH(idx)
    local wpk = GetWPacket()
    WriteUint16(wpk, netCmd.CMD_CG_MAILGETATTACH)
    WriteString(wpk,idx)
    SendWPacket(wpk)
end

function CMD_MAILDELETE(idx)
    local wpk = GetWPacket()
    WriteUint16(wpk, netCmd.CMD_CG_MAILDELETE)
    WriteString(wpk,idx)
    SendWPacket(wpk)
end


cc.Director:getInstance():getScheduler():scheduleScriptFunc(function () 
    if UsePseudo then
        Pseudo.TickPseudo()
    end
end, 0, false)
