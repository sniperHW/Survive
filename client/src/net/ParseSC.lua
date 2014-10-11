local Name2idx = require "src.net.name2idx"

local NetHandler = NetHandler or {}
function RegNetHandler(handle, cmd)
    NetHandler[cmd] = handle
end

local function ReadAttr(rpk)
	local attr = {}
	local size = ReadUint8(rpk)
	for i=1,size do
		local attrname = Name2idx.name(ReadUint8(rpk))
		attr[attrname] = ReadUint32(rpk)
	end	
	return attr
end

RegHandler(function (rpk)
	local packet = {}
	packet.avatarid = ReadUint16(rpk)
	packet.nickname = ReadString(rpk)
	
	--角色基本属性
	packet.attr = ReadAttr(rpk)
	
	--背包
	packet.bag = {}
	packet.bag.bagsize = ReadUint8(rpk)
	--6个战场带入物品的背包索引
	for i=1,6 do
		local name = "battle" .. i
		packet.bag[name] = ReadUint8(rpk)
	end
	--背包位置
	local size = ReadUint8(rpk)
	for i=1,size do
		local idx = ReadUint8(rpk)
		local item = {}
		item.id = ReadUint16(rpk)
		item.count = ReadUint16(rpk)
		local attrsize = ReadUint8(rpk)
		if attrsize > 0 then
			item.attr = {}
			for j=1,attrsize do
				local idx = ReadUint8(rpk)
				item.attr[idx] = ReadUint32(rpk)
			end
		end
		packet.bag[idx] = item		
	end	
	--技能
	packet.skill = {}
	size = ReadUint16(rpk)
	for i=1,size do
		local skill = {}
		skill.id = ReadUint16(rpk)
		skill.level = ReadUint16(rpk)
		packet.skill[skill.id] = skill
	end	
	
	NetHandler[CMD_GC_BEGINPLY](packet)
end,CMD_GC_BEGINPLY)

RegHandler(function (rpk)
	local packet = {}
	packet.atkerid = ReadUint32(rpk)
	packet.skillid = ReadUint16(rpk)
    packet.success = (ReadUint8(rpk) == 1)	
    NetHandler[CMD_SC_NOTIATK](packet)
end,CMD_SC_NOTIATK)

RegHandler(function (rpk)
	local packet = {}
	packet.atkerid = ReadUint32(rpk)
	packet.skillid = ReadUint16(rpk)
	packet.suffererid = ReadUint32(rpk)
    packet.hpchange = ReadInt32(rpk)
	
    NetHandler[CMD_SC_NOTIATKSUFFER](packet)
end,CMD_SC_NOTIATKSUFFER)

RegHandler(function (rpk)
	local packet = {}
	packet.atkerid = ReadUint32(rpk)
	packet.skillid = ReadUint16(rpk)
	packet.suffererid = ReadUint32(rpk)
    packet.hpchange = ReadInt32(rpk)
	
    NetHandler[CMD_SC_NOTISUFFER](packet)
end,CMD_SC_NOTISUFFER)

--通知创建角色
RegHandler(function (rpk)
    local packet = {}
    
    NetHandler[CMD_GC_CREATE](packet)
end,CMD_GC_CREATE)

RegHandler(function (rpk)
	local packet = {}
	packet.maptype = ReadUint16(rpk)	
	--属性
	packet.attr = ReadAttr(rpk)
	packet.selfid = ReadUint32(rpk)		
	
    NetHandler[CMD_SC_ENTERMAP](packet)
end,CMD_SC_ENTERMAP)

--移动失败
RegHandler(function (rpk)
    local packet = {}
    
    NetHandler[CMD_SC_MOV_FAILED](packet)
end,CMD_SC_MOV_FAILED)

--移动成功
RegHandler(function (rpk)
	local packet = {}
	packet.id = ReadUint32(rpk)
	packet.x = ReadUint16(rpk)
	packet.y = ReadUint16(rpk)
	
    NetHandler[CMD_SC_MOV](packet)
end,CMD_SC_MOV)

--进入视野
RegHandler(function (rpk)
	local packet = {}
	packet.id = ReadUint32(rpk)
	packet.avattype = ReadUint8(rpk)
	packet.avatid = ReadUint16(rpk)
	packet.name = ReadString(rpk)
	packet.x = ReadUint16(rpk)
	packet.y = ReadUint16(rpk)
	packet.dir = ReadUint8(rpk)
	
	--属性
	packet.attr = ReadAttr(rpk)

    NetHandler[CMD_SC_ENTERSEE](packet)	
end,CMD_SC_ENTERSEE)

--离开视野
RegHandler(function (rpk)
	local packet = {}
	packet.id = ReadUint32(rpk)
	
    NetHandler[CMD_SC_LEAVESEE](packet)
end,CMD_SC_LEAVESEE)


--属性更新
RegHandler(function (rpk)
	packet.attr = ReadAttr(rpk)
end,CMD_GC_ATTRUPDATE)

RegHandler(function (rpk)
	packet.id = ReadUint32(rpk)
	packet.attr = ReadAttr(rpk)	
end,CMD_SC_ATTRUPDATE)

