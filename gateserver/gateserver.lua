local TcpServer = require "lua/tcpserver"
local App = require "lua/application"
local RPC = require "lua/rpc"
local Player = require "Survive/gateserver/gateplayer"
local NetCmd = require "Survive/netcmd/netcmd"
local MsgHandler = require "Survive/netcmd/msghandler"
local Sche = require "lua/sche"
local Socket = require "lua/socket"
local Db = require "Survive/common/db"

local togroup
local toinner = App.New()
local toclient = App.New()
local name2game = {}

function Send2Group(wpk)
	if togroup then
		togroup:Send(wpk)		
	end
end

--转发到gameserver
local function ForwardGame(sock,rpk)
	local player = Player.GetPlayerBySock(sock)
	if player and player.gamesession then		
		local wpk = CPacket.NewWPacket(rpk)
		wpk:Write_uint32(player.gamesession.id)
		player.gamesession.sock:Send(wpk)
	end	
end

--转发到groupserver
local function ForwardGroup(sock,rpk)
	if togroup then
		local player = Player.GetPlayerBySock(sock)
		if player and player.groupsession then
			local wpk = CPacket.NewWPacket(rpk)
			wpk:Write_uint16(player.groupsession)		
			togroup:Send(wpk)	
		end
	end
end

--处理来自客户端的网络消息
local function OnClientMsg(sock,rpk)
	local cmd = rpk:Peek_uint16()
	print("OnClientMsg",cmd)
	if cmd >= NetCmd.CMD_CG_BEGIN and cmd <= NetCmd.CMD_CG_END then
		ForwardGroup(sock,rpk)
	elseif cmd >= NetCmd.CMD_CS_BEGIN and cmd <= NetCmd.CMD_CS_END then
		ForwardGame(sock,rpk)
	else
		MsgHandler.OnMsg(sock,rpk)
	end
end

--处理来自内部服务器的网络消息
local function OnInnerMsg(sock,rpk)
	local cmd = rpk:Peek_uint16()
	if (cmd >= NetCmd.CMD_GC_BEGIN and cmd <= NetCmd.CMD_GC_END) or
	   (cmd >= NetCmd.CMD_SC_BEGIN and cmd <= NetCmd.CMD_SC_END) then
		--转发到客户端
		rpk:Read_uint16() --丢弃命令头
		local wpk = CPacket.NewWPacket(rpk:Read_string())
		--将wpk转发给所有需要接收的玩家
		local size = rpk:Read_uint16()
		for i = 1,size do
			local gatesession = rpk:Read_uint32()
			local ply = Player.GetPlayerById(gatesession)
			if ply then
				if cmd == NetCmd.CMD_SC_ENTERMAP then
					ply.gamesession = {sock=sock,id=rpk:Read_uint32()}
					print("CMD_SC_ENTERMAP",ply.gamesession.id)
				end
				ply:Send2Client(CPacket.NewWPacket(wpk))
			end
		end		
	else
		MsgHandler.OnMsg(sock,rpk)
	end
end


--连接gameserver并完成登录
local function connect_to_game(name,ip,port)
	if name2game[name] then
		return
	end
	Sche.Spawn(function ()
		while true do
			local sock = Socket.New(CSocket.AF_INET,CSocket.SOCK_STREAM,CSocket.IPPROTO_TCP)
			print("connect_to_game",name,ip,port)
			if not sock:Connect(ip,port) then
				sock:Establish(CSocket.rpkdecoder(65535))				
				toinner:Add(sock,OnInnerMsg,
							function (s,errno)
								Player.OnGameDisconnected(s)
								name2game[name].sock = nil
								print(name .. " disconnected")
								connect_to_game(name,ip,port)
							end)
				local rpccaller = RPC.MakeRPC(sock,"Login")
				local err,ret = rpccaller:Call("gate1")
				if err or ret == "Login failed" then
					if err then
						print(err)
					else
						print(ret)
					end
					sock:Close()
					break							
				end
				print("connect to " .. name .. " success")				
				if name2game[name] then
					name2game[name].sock = sock
				else
					name2game[name] = {sock = sock}
				end
				break	
			end
			print("try to connect to " .. name .. "after 1 sec")
			Sche.Sleep(1000)
		end
	end)
end


--定义网络命令处理器

MsgHandler.RegHandler(NetCmd.CMD_GA_NOTIFY_GAME,function (sock,rpk)
	local name = rpk:Read_string()
	local ip = rpk:Read_string()
	local port = rpk:Read_uint16()
	connect_to_game(name,ip,port)		
end)

MsgHandler.RegHandler(NetCmd.CMD_CA_LOGIN,function (sock,rpk)
	print("CMD_CA_LOGIN")
	local type = rpk:Read_uint8()
	local actname = rpk:Read_string()
	local player = Player.GetPlayerBySock(sock) or Player.NewGatePly(sock)
	if not player then
		--通知服务器繁忙
		return
	end
	if player.status then
		return
	end
	player.status = Player.verifying
	local err,result = Db.Command("get " .. actname)		
	if not Player.IsVaild(player) then
		Player.ReleasePlayer(player) --玩家连接已经提前断开
		return
	end
	if err then
		player.status = nil	
	end
	local chaid = 0
	if result then
		chaid = result
	end
	if not togroup then
		--通知系统繁忙
		player.status = nil
	else
		--验证通过,登录到group
		local rpccaller = RPC.MakeRPC(togroup,"PlayerLogin")
		player.status = Player.login2group
		local err,ret = rpccaller:Call(actname,chaid,player.sessionid)
		if not Player.IsVaild(player) then
			Player.ReleasePlayer(player) --玩家连接已经提前断开
			return
		end					
		if err then
			player.status = nil
		else
			if ret[1] then
				player.groupsession = ret[2]
				if ret[3] then
					--通知客户端创建角色						
					local wpk = CPacket.NewWPacket(64)
					wpk:Write_uint16(NetCmd.CMD_GC_CREATE)
					sock:Send(wpk)						
					player.status = Player.createcha					
				else
					player.status = Player.playing
				end
			else
				--断开连接
				sock:Close()
			end	
		end		
	end	
end)


--连接groupserver并完成登录
local function connect_to_group()
	if togroup then
		Player.OnGroupDisconnected()
		print("togroup disconnected")
	end
	togroup = nil
	Sche.Spawn(function ()
		while true do
			local sock = Socket.New(CSocket.AF_INET,CSocket.SOCK_STREAM,CSocket.IPPROTO_TCP)
			if not sock:Connect("127.0.0.1",8811) then
				sock:Establish(CSocket.rpkdecoder(65535))
				toinner:Add(sock,OnInnerMsg,connect_to_group)								
				--登录到groupserver
				local rpccaller = RPC.MakeRPC(sock,"GateLogin")
				local err,ret = rpccaller:Call("gate1")
				if err or ret == "Login failed" then
					if err then
						print(err)
					else
						print(ret)
					end
					sock:Close()
					stop_program()	
				end
				togroup = sock
				print("connect to group success")
				for k,v in pairs(ret) do
					connect_to_game(v[1],v[2],v[3])
				end					
				break
			end
			print("try to connect to group after 1 sec")
			Sche.Sleep(1000)
		end
	end)	
end

Db.Init()
connect_to_group()
toinner:Run()
toclient:Run()


while not togroup or not Db.Finish() do
	Sche.Yield()
end

--在连接上groupserver和db初始化完成后才启动对客户端的监听

if TcpServer.Listen("192.168.0.87",8810,function (sock)
		sock:Establish(CSocket.rpkdecoder(4096))
		print("client connected")
		toclient:Add(sock,OnClientMsg,Player.OnPlayerDisconnected)		
	end) then
	print("start server on 192.168.0.87:8810 error")
	stop_program()	
else
	print("start server on 192.168.0.87:8810")
end
