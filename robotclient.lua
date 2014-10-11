local NetCmd = require "Survive/netcmd/netcmd"
local App = require "lua/application"
local socket = require "lua/socket"
local sche = require "lua/sche"
local MsgHandler = require "Survive/netcmd/msghandler"
local Name2idx = require "Survive/common/name2idx"


local function ReadAttr(rpk)
	local attr = {}
	local size = rpk:Read_uint8(rpk)
	for i=1,size do
		local attrname = Name2idx.Name(rpk:Read_uint8())
		attr[attrname] = rpk:Read_uint32()
	end	
	--print("attr size:",size)
	return attr
end


local Robot = App.New()

MsgHandler.RegHandler(NetCmd.CMD_GC_CREATE,function (sock,rpk)
	print("CMD_GC_CREATE")
	local wpk = CPacket.NewWPacket(64)
	wpk:Write_uint16(NetCmd.CMD_CG_CREATE)	
	wpk:Write_uint8(1)
	wpk:Write_string(sock.actname)
	wpk:Write_uint8(1)
	sock:Send(wpk)
end)


MsgHandler.RegHandler(NetCmd.CMD_SC_ENTERMAP,function (sock,rpk)
	local ply = sock.ply
	if ply then
		ply.map = rpk:Read_uint16()
		--角色基本属性
		ply.attr = ReadAttr(rpk)		
		for k,v in pairs(ply.attr) do
			print(k .. ":" .. v)
		end		
		ply.id  = rpk:Read_uint32()
		print("self id:" .. ply.id) 
	end
end)

local function Mov(sock)
	local x = math.random(10,400)
	local y = math.random(10,200)
	local wpk = CPacket.NewWPacket(64)
	wpk:Write_uint16(NetCmd.CMD_CS_MOV)
	wpk:Write_uint16(x)
	wpk:Write_uint16(y)
	print("MoveTo",x,y)
	sock:Send(wpk)	
end

MsgHandler.RegHandler(NetCmd.CMD_SC_ENTERSEE,function (sock,rpk)
	local ply = sock.ply
	if ply then
		local id = rpk:Read_uint32(rpk)
		if id == ply.id then
			rpk:Read_uint8()
			rpk:Read_uint16()
			local nickname = rpk:Read_string()
			ply.pos = {}
			ply.pos.x = rpk:Read_uint16()
			ply.pos.y = rpk:Read_uint16()
			ply.dir = rpk:Read_uint8()
			print("self enter see",nickname,string.len(nickname))
			--Mov(sock)				
		else
			print("enter see",id)
		end
	end
end)

MsgHandler.RegHandler(NetCmd.CMD_SC_MOV_FAILED,function (sock,rpk)
	print("CMD_SC_MOV_FAILED")
	Mov(sock)
end)

MsgHandler.RegHandler(NetCmd.CMD_SC_MOV_ARRI,function (sock,rpk)
	print("CMD_SC_MOV_ARRI")
	Mov(sock)
end)

MsgHandler.RegHandler(NetCmd.CMD_SC_MOV,function (sock,rpk)

end)

MsgHandler.RegHandler(NetCmd.CMD_SC_LEAVESEE,function (sock,rpk)
	local id = rpk:Read_uint32(rpk)
	print("leave see",id)
end)


MsgHandler.RegHandler(NetCmd.CMD_GC_BEGINPLY,function (sock,rpk)
	print("CMD_GC_BEGINPLY")
	local ply = {}
	
	ply.avatarid = rpk:Read_uint16()
	--print("avatarid:" .. ply.avatarid)
	ply.nickname = rpk:Read_string()
	--print("nickname:" .. ply.nickname)
	--角色基本属性
	ply.attr = ReadAttr(rpk)
	
	--for k,v in pairs(ply.attr) do
	--	print(k .. ":" .. v)
	--end
	--背包
	ply.bag = {}
	ply.bag.bagsize = rpk:Read_uint8()
	print("bagsize:" .. ply.bag.bagsize)
	--6个战场带入物品的背包索引
	for i=1,6 do
		local name = "battle" .. i
		ply.bag[name] = rpk:Read_uint8()
	end
	--print("here1")
	--背包位置
	local size = rpk:Read_uint8()
	print("bag size:",size)		
	for i=1,size do
		local idx = rpk:Read_uint8()
		local item = {}
		item.id = rpk:Read_uint16()
		item.count = rpk:Read_uint16()
		local attrsize = rpk:Read_uint8()
		if attrsize > 0 then
			item.attr = {}
			for j=1,attrsize do
				local idx = rpk:Read_uint8()
				item.attr[idx] = rpk:Read_uint32()
			end
		end
		ply.bag[idx] = item		
	end	
	--print("here2")		
	--技能
	ply.skill = {}	
	size = rpk:Read_uint16()
	print("skill size:" .. size)
	for i=1,size do
		local skill = {}
		skill.id = rpk:Read_uint16()
		skill.level = rpk:Read_uint16()
		ply.skill[skill.id] = skill
	end		
	
	print(ply.nickname .. " begin play")
	sock.ply = ply
	local wpk = CPacket.NewWPacket(64)
	wpk:Write_uint16(NetCmd.CMD_CG_ENTERMAP)	
	wpk:Write_uint8(1)
	sock:Send(wpk)	
	
end)

Robot:Run(function ()
	for i=101,101 do
		sche.Spawn(function () 
			local client = socket.New(CSocket.AF_INET,CSocket.SOCK_STREAM,CSocket.IPPROTO_TCP)
			if client:Connect("192.168.0.87",8810) then
				print("connect to 127.0.0.1:8810 error")
				return
			end
			client:Establish(CSocket.rpkdecoder())
			Robot:Add(client,MsgHandler.OnMsg,function () print("robot" .. i .. " disconnected") end)
			local wpk = CPacket.NewWPacket(64)
			wpk:Write_uint16(NetCmd.CMD_CA_LOGIN)
			wpk:Write_uint8(1)
			wpk:Write_string("robot" .. i)
			client.actname = "robot" .. i
			client:Send(wpk)
		end)	
	end
end)



