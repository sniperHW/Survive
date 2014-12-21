local Name2idx = require "src.net.name2idx"
local netCmd = require "src.net.NetCmd"

local NetHandler = NetHandler or {}
function RegNetHandler(handle, cmd)
    NetHandler[cmd] = handle
end

local PseudoNetHandler = {}

local function SuperReg(func,cmd)
	RegHandler(func,cmd)
	PseudoNetHandler[cmd] = func
end

local function ReadAttr(rpk)
	local attr = {}
	local size = ReadUint8(rpk)
	--print(size)
	for i=1,size do
		local k = ReadUint8(rpk)
		local attrname = Name2idx.name(k)
		if attrname then
			attr[attrname] = ReadUint32(rpk)
			--print(attrname,attr[attrname])
		end
	end	
	return attr
end

SuperReg(function (rpk)
	local packet = {}
	packet.bag = {}
	--背包位置
	local size = ReadUint8(rpk)
	for i=1,size do
		local idx = ReadUint8(rpk)
		local item = {}
		item.id = ReadUint16(rpk)
		item.count = ReadUint16(rpk)
		item.bagpos = idx
		local attrsize = ReadUint8(rpk)
		if attrsize > 0 then
			item.attr = {}
			for j=1,attrsize do
				local idx = ReadUint8(rpk)
				item.attr[idx] = ReadUint32(rpk)
			end
		end

		packet.bag[i] = item		
	end	
	NetHandler[netCmd.CMD_GC_BAGUPDATE](packet)
end,netCmd.CMD_GC_BAGUPDATE)

SuperReg(function (rpk)
	local packet = {}
	packet.avatarid = ReadUint16(rpk)
	packet.nickname = ReadString(rpk)
	--角色基本属性
	packet.attr = ReadAttr(rpk)
	--背包
	packet.bag = {}
	packet.bag.bagsize = ReadUint8(rpk)
	--背包位置
	local size = ReadUint8(rpk)
	for i=1,size do
		local bagpos = ReadUint8(rpk)
		local item = {}
		item.id = ReadUint16(rpk)
		item.count = ReadUint16(rpk)
		item.bagpos = bagpos
		local attrsize = ReadUint8(rpk)
		if attrsize > 0 then
			item.attr = {}
			for j=1,attrsize do
				local idx = ReadUint8(rpk)
				item.attr[idx] = ReadUint32(rpk)
			end
		end
		packet.bag[i] = item
	end	
	--技能
	packet.skill = {}
	size = ReadUint16(rpk)
	for i=1,size do
		local skill = {}
		skill.id = ReadUint16(rpk)
		skill.level = ReadUint8(rpk)
		packet.skill[skill.id] = skill
	end
	packet.everydaysign = {}
    	packet.everydaysign.daycount = ReadUint8(rpk)
    	packet.everydaysign.count = ReadUint8(rpk)
    	packet.everydaysign.signAble = ReadUint8(rpk)

	packet.server_timestamp = ReadUint32(rpk)	
	NetHandler[netCmd.CMD_GC_BEGINPLY](packet)
end,netCmd.CMD_GC_BEGINPLY)

SuperReg(function (rpk)
	local packet = {}
	packet.atkerid = ReadUint32(rpk)
	packet.skillid = ReadUint16(rpk)
	packet.success = ReadUint8(rpk)
	if packet.success == 1 then
		packet.point = {}
		packet.point.x = ReadUint16(rpk)
		packet.point.y = ReadUint16(rpk)
	elseif packet.success == 2 then
		packet.dir = ReadUint16(rpk)
	end
	NetHandler[netCmd.CMD_SC_NOTIATK](packet)
end,netCmd.CMD_SC_NOTIATK)

SuperReg(function (rpk)
	local packet = {}
	packet.atktime = ReadInt32(rpk)	
	packet.atkerid = ReadUint32(rpk)
	packet.skillid = ReadUint16(rpk)
	packet.suffererid = ReadUint32(rpk)
    	packet.hpchange = ReadInt32(rpk)
	packet.atktime = ReadInt32(rpk)
    NetHandler[netCmd.CMD_SC_NOTIATKSUFFER](packet)
end,netCmd.CMD_SC_NOTIATKSUFFER)

SuperReg(function (rpk)
	local packet = {}
	packet.atktime = ReadInt32(rpk)	
	packet.atker = ReadUint32(rpk)
	packet.skillid = ReadUint16(rpk)
	packet.atkerpos = {}
	packet.atkerpos.x = ReadUint16(rpk)
	packet.atkerpos.y = ReadUint16(rpk)	
	packet.suffers = {}
	local size = ReadUint8(rpk)
	for i = 1,size do
		local suffer = {}
	        	suffer.id = ReadUint32(rpk)
	        	suffer.hpchange = ReadInt32(rpk)
		local pos = {}
		pos.x = ReadUint16(rpk)
		pos.y = ReadUint16(rpk)
	        	suffer.pos = pos
		packet.suffers[i] = suffer
	end
    	NetHandler[netCmd.CMD_SC_NOTIATKSUFFER2](packet)
end,netCmd.CMD_SC_NOTIATKSUFFER2)

SuperReg(function (rpk)
	local packet = {}
	packet.atktime = ReadInt32(rpk)
	packet.atker = ReadUint32(rpk)	
	packet.skillid = ReadUint16(rpk)	
	packet.suffererid = ReadUint32(rpk)
    	packet.hpchange = ReadInt32(rpk)
    	packet.bRepel = ReadUint8(rpk)
	if packet.bRepel == 1 then
		packet.point = {}
		packet.point.x = ReadUint16(rpk)
		packet.point.y = ReadUint16(rpk)
	end
	NetHandler[netCmd.CMD_SC_NOTISUFFER](packet)
end,netCmd.CMD_SC_NOTISUFFER)

--通知创建角色
SuperReg(function (rpk)
    local packet = {}
    
    NetHandler[netCmd.CMD_GC_CREATE](packet)
end,netCmd.CMD_GC_CREATE)

SuperReg(function (rpk)
	--print("CMD_SC_ENTERMAP begin")
	local packet = {}
	packet.maptype = ReadUint16(rpk)	
	--属性
	packet.attr = ReadAttr(rpk)
	packet.battleitems = {}
	local size = ReadUint8(rpk)
	print(size)
	for i=1,size do
		local pos = ReadUint8(rpk)
		local item = {}
		item.id = ReadUint16(rpk)
		item.count = ReadUint16(rpk)
		--print(pos,item.id,item.count)
		packet.battleitems[pos] = item
	end	
	packet.selfid = ReadUint32(rpk)		
	--print("CMD_SC_ENTERMAP end")
	---print("CMD_SC_ENTERMAP",packet)
	
    NetHandler[netCmd.CMD_SC_ENTERMAP](packet)
end,netCmd.CMD_SC_ENTERMAP)

--移动失败
SuperReg(function (rpk)
    local packet = {}
    
    NetHandler[netCmd.CMD_SC_MOV_FAILED](packet)
end,netCmd.CMD_SC_MOV_FAILED)

SuperReg(function (rpk)
    local packet = {}
    packet.op = ReadUint8(rpk)
    NetHandler[netCmd.CMD_GC_NOTIOPSUCCESS](packet)
end,netCmd.CMD_GC_NOTIOPSUCCESS)

--移动成功
SuperReg(function (rpk)
	local packet = {}
	packet.id = ReadUint32(rpk)
	packet.x = ReadUint16(rpk)
	packet.y = ReadUint16(rpk)
	
    NetHandler[netCmd.CMD_SC_MOV](packet)
end,netCmd.CMD_SC_MOV)

SuperReg(function (rpk)
	local packet = {}
	packet.dir = ReadUint16(rpk)
    NetHandler[netCmd.CMD_SC_DIR](packet)
end,netCmd.CMD_SC_DIR)

--进入视野
SuperReg(function (rpk)
	print("packet----------enter see hahah")
	local packet = {}
	packet.id = ReadUint32(rpk)
	packet.avattype = ReadUint8(rpk)
	packet.avatid = ReadUint16(rpk)
	packet.name = ReadString(rpk)
	packet.teamid = ReadUint16(rpk)
	packet.x = ReadUint16(rpk)
	packet.y = ReadUint16(rpk)
	packet.dir = ReadUint16(rpk)

	--属性
	packet.attr = ReadAttr(rpk)
	packet.fashion = ReadUint16(rpk)
	local weapon = {}
	weapon.id = ReadUint16(rpk)
	if weapon.id > 0 then
		weapon.count = ReadUint16(rpk)
		local attrsize = ReadUint8(rpk)
		if attrsize > 0 then
			weapon.attr = {}
			for j=1,attrsize do
				local idx = ReadUint8(rpk)
				weapon.attr[idx] = ReadUint32(rpk)
			end
		end
		packet.weapon = weapon
	end
	print("packet----------enter see:"..packet.id)

    NetHandler[netCmd.CMD_SC_ENTERSEE](packet)	
end,netCmd.CMD_SC_ENTERSEE)

--离开视野
SuperReg(function (rpk)
	local packet = {}
	packet.id = ReadUint32(rpk)
	
    NetHandler[netCmd.CMD_SC_LEAVESEE](packet)
end,netCmd.CMD_SC_LEAVESEE)


--属性更新
SuperReg(function (rpk)
    local packet = {}
	packet.attr = ReadAttr(rpk)
    NetHandler[netCmd.CMD_GC_ATTRUPDATE](packet) 
end,netCmd.CMD_GC_ATTRUPDATE)

SuperReg(function (rpk)
    local packet = {}
	packet.id = ReadUint32(rpk)
	packet.attr = ReadAttr(rpk)	
    NetHandler[netCmd.CMD_SC_ATTRUPDATE](packet) 
end,netCmd.CMD_SC_ATTRUPDATE)

SuperReg(function (rpk)
	local packet = {}
	packet.id = ReadUint32(rpk)
	packet.buffid = ReadUint16(rpk)	
	NetHandler[netCmd.CMD_SC_BUFFBEGIN](packet)

end,netCmd.CMD_SC_BUFFBEGIN)

SuperReg(function (rpk)
	local packet = {}
	packet.id = ReadUint32(rpk)
	packet.buffid = ReadUint16(rpk)	
	NetHandler[netCmd.CMD_SC_BUFFEND](packet)
end,netCmd.CMD_SC_BUFFEND)

SuperReg(function (rpk)
	local packet = {}
	NetHandler[netCmd.CMD_GC_BACK2MAIN](packet)
	UsePseudo = false
end, netCmd.CMD_GC_BACK2MAIN)

SuperReg(function (rpk)
	local packet = {}
	packet.maptype = ReadUint16(rpk)
	UsePseudo = true
	NetHandler[netCmd.CMD_GC_ENTERPSMAP](packet)
end, netCmd.CMD_GC_ENTERPSMAP)

SuperReg(function (rpk)
    local packet = {}
    packet.start_time = ReadUint32(rpk)
    if packet.start_time then
    	packet.action = ReadUint8(rpk)
    end
    NetHandler[netCmd.CMD_GC_HOMEACTION_RET](packet)
end,netCmd.CMD_GC_HOMEACTION_RET)

SuperReg(function (rpk)
    local packet = {}
    packet.action = ReadUint8(rpk)
    packet.reward = ReadUint32(rpk)
    packet.reward_item = {0,0}
    packet.reward_item[1] = ReadUint16(rpk)
    packet.reward_item[2] = ReadUint32(rpk)
    NetHandler[netCmd.CMD_GC_HOMEBALANCE_RET](packet)
end,netCmd.CMD_GC_HOMEBALANCE_RET)

SuperReg(function (rpk)
    local packet = {}
    packet.skillid = ReadUint16(rpk)
    packet.lev = ReadUint8(rpk)
    NetHandler[netCmd.CMD_GC_SKILLUPDATE](packet)
end,netCmd.CMD_GC_SKILLUPDATE)	

SuperReg(function (rpk)
    local packet = {}
    packet.skillid = ReadUint16(rpk)
    packet.lev = ReadUint8(rpk)
    NetHandler[netCmd.CMD_GC_ADDSKILL](packet)
end,netCmd.CMD_GC_ADDSKILL)

SuperReg(function (rpk)
    local packet = {}
    packet.daycount = ReadUint8(rpk)
    packet.count = ReadUint8(rpk)
    packet.signAble = ReadUint8(rpk)
    --packet.skillid = ReadUint16(rpk)
    --packet.lev = ReadUint8(rpk)
    NetHandler[netCmd.CMD_GC_EVERYDAYSIGN](packet)
end,netCmd.CMD_GC_EVERYDAYSIGN)	

SuperReg(function (rpk)
    local packet = {}
    
    local count = 	ReadUint8(rpk)
    packet.tasks = {}
    for i=1,count do
    	packet.tasks[i] = {}
    	packet.tasks[i].count = ReadUint8(rpk)
    	packet.tasks[i].awarded =  ReadUint8(rpk)
    end
    NetHandler[netCmd.CMD_GC_EVERYDAYTASK](packet)
end,netCmd.CMD_GC_EVERYDAYTASK)	

SuperReg(function (rpk)
    local packet = {}
    packet.id = ReadUint8(rpk)
    NetHandler[netCmd.CMD_GC_EVERTDAYTASK_AWARD](packet)
end,netCmd.CMD_GC_EVERTDAYTASK_AWARD)			

function OnPseudoServerPacket(rpk)
	local cmd = ReadUint16(rpk)
	local func = PseudoNetHandler[cmd]
	if func then
		func(rpk)
	end
end