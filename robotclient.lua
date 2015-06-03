local NetCmd = require "netcmd.netcmd"
local App = require "lua.application"
local socket = require "lua.socket"
local sche = require "lua.sche"
local MsgHandler = require "netcmd.msghandler"
local Name2idx = require "common.name2idx"


local function ReadAttr(rpk)
	local attr = {}
	local size = rpk:Read_uint8(rpk)
	for i=1,size do
		local attrname = Name2idx.Name(rpk:Read_uint8())
		attr[attrname] = rpk:Read_uint32()
	end	
	return attr
end


local Robot = App.New()

MsgHandler.RegHandler(NetCmd.CMD_GC_CREATE,function (sock,rpk)
	local wpk = CPacket.NewWPacket(64)
	wpk:Write_uint16(NetCmd.CMD_CG_CREATE)	
	wpk:Write_uint8(math.random(1,2))
	wpk:Write_string(sock.actname)
	wpk:Write_uint16(5001)
	sock:Send(wpk)
end)

MsgHandler.RegHandler(NetCmd.CMD_GC_BACK2MAIN,function (sock,rpk)
end)


MsgHandler.RegHandler(NetCmd.CMD_SC_ENTERMAP,function (sock,rpk)
	local ply = sock.ply
	if ply then
		ply.map = rpk:Read_uint16()
		--角色基本属性
		ply.attr = ReadAttr(rpk)		

		ply.battleitems = {}
		local size = rpk:Read_uint8()
		for i=1,size do
			local pos = rpk:Read_uint8()
			local item = {}
			item.id = rpk:Read_uint16()
			item.count = rpk:Read_uint16()
			ply.battleitems[pos] = item
		end
		ply.id  = rpk:Read_uint32()
	end
end)

local function Mov(sock)
	local x = math.random(10,400)--math.random(10,400)
	local y = math.random(10,200)--math.random(10,200)
	local wpk = CPacket.NewWPacket(64)
	wpk:Write_uint16(NetCmd.CMD_CS_MOV)
	wpk:Write_uint16(x)
	wpk:Write_uint16(y)
	sock:Send(wpk)	
end

local function LeaveMap(sock)
	local wpk = CPacket.NewWPacket(64)
	wpk:Write_uint16(NetCmd.CMD_CG_LEAVEMAP)
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
			ply.teamid = rpk:Read_uint16()
			ply.pos = {}
			ply.pos.x = rpk:Read_uint16()
			ply.pos.y = rpk:Read_uint16()
			ply.dir = rpk:Read_uint8()
			local attr = ReadAttr(rpk)
			for k,v in pairs(attr) do
				print(k,v)
			end
			Mov(sock)
			--LeaveMap(sock)				
		end
	end
end)

MsgHandler.RegHandler(NetCmd.CMD_SC_MOV_FAILED,function (sock,rpk)
	Mov(sock)
end)

MsgHandler.RegHandler(NetCmd.CMD_SC_MOV_ARRI,function (sock,rpk)
	Mov(sock)
end)

MsgHandler.RegHandler(NetCmd.CMD_SC_MOV,function (sock,rpk)

end)

MsgHandler.RegHandler(NetCmd.CMD_SC_LEAVESEE,function (sock,rpk)
	local id = rpk:Read_uint32(rpk)
end)


MsgHandler.RegHandler(NetCmd.CMD_GC_BEGINPLY,function (sock,rpk)
	print("CMD_GC_BEGINPLY")
	local ply = {}
	
	ply.avatarid = rpk:Read_uint16()
	ply.nickname = rpk:Read_string()
	--角色基本属性
	ply.attr = ReadAttr(rpk)
	
	--背包
	ply.bag = {}
	ply.bag.bagsize = rpk:Read_uint8()
	--背包位置
	local size = rpk:Read_uint8()	
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
	--技能
	ply.skill = {}	
	size = rpk:Read_uint16()
	for i=1,size do
		local skill = {}
		skill.id = rpk:Read_uint16()
		skill.level = rpk:Read_uint16()
		ply.skill[skill.id] = skill
	end		
	
	--packet.everydaysign = {}
    	--packet.everydaysign.daycount = rpk:Read_uint8()
    	--packet.everydaysign.count = rpk:Read_uint8()
    	--packet.everydaysign.signAble = rpk:Read_uint8()

	--packet.server_timestamp = rpk:Read_uint32()	
	rpk:Read_uint8()
	rpk:Read_uint8()
	rpk:Read_uint8()
	rpk:Read_uint32()

	print(ply.nickname .. " begin play")
	--sock:Close()
	sock.ply = ply
	local wpk = CPacket.NewWPacket(64)
	wpk:Write_uint16(NetCmd.CMD_CG_ENTERMAP)	
	wpk:Write_uint8(201)
	sock:Send(wpk)	
end)


function ConnectAndLogin(name)
	local client = socket.New(CSocket.AF_INET,CSocket.SOCK_STREAM,CSocket.IPPROTO_TCP)
	--if client:Connect("121.41.37.227",8010) then
	if client:Connect("192.168.0.87",8010) then
		print("connect to 127.0.0.1:8810 error")
		return
	end
	client:Establish(CSocket.rpkdecoder())
	Robot:Add(client,MsgHandler.OnMsg,
		      function () 
		      	sche.Spawn(ConnectAndLogin,name)
		      	collectgarbage("collect")
		      end
	)
	local wpk = CPacket.NewWPacket(64)
	wpk:Write_uint16(NetCmd.CMD_CA_LOGIN)
	wpk:Write_uint8(1)
	wpk:Write_string(name)
	client.actname = name
	client:Send(wpk)	

end


for i=1,50 do
	local name = "test" .. i
	sche.Spawn(ConnectAndLogin,name)
end




