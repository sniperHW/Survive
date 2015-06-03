log_gateserver = CLog.New("gateserver")
local TcpServer = require "lua.tcpserver"
local App = require "lua.application"
local RPC = require "lua.rpc"
local Player = require "gateserver.gateplayer"
local NetCmd = require "netcmd.netcmd"
local MsgHandler = require "netcmd.msghandler"
local Sche = require "lua.sche"
local Socket = require "lua.socket"
local Db = require "common.db"
local Config = require "common.config"


local ret,err = Config.Init("测试1服","127.0.0.1",6379)
if ret then
	local togroup
	local toinner = App.New()
	local toclient = App.New()
	local name2game = {}

	local redis_ip = Config.Get("db")[1]
	local redis_port = Config.Get("db")[2]

	local group_ip = Config.Get("group")[1]
	local group_port = Config.Get("group")[2]

	local ip = Config.Get("gate1")[1]
	local port = Config.Get("gate1")[2]

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
						--print("CMD_SC_ENTERMAP",ply.gamesession.id)
					elseif cmd == NetCmd.CMD_GC_BACK2MAIN then
						print("CMD_CG_LEAVEMAP")
						ply.gamesession = nil
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
		Sche.Spawn(function ()
			while true do
				if name2game[name] and name2game[name].sock then
					return
				end		
				local sock = Socket.Stream.New(CSocket.AF_INET)
				--print("connect_to_game",name,ip,port)
				if not sock:Connect(ip,port) then
					sock:Establish(CSocket.rpkdecoder(65535))				
					toinner:Add(sock,OnInnerMsg,
								function (s,errno)
									Player.OnGameDisconnected(s)
									name2game[name].sock = nil
									log_gateserver:Log(CLog.LOG_INFO,string.format("gameserver %s disconnected",name))
									connect_to_game(name,ip,port)
								end)
					local rpccaller = RPC.MakeRPC(sock,"Login")
					local err,ret = rpccaller:CallSync("gate1")
					if err or ret == "Login failed" then
						if err then
							log_gateserver:Log(CLog.LOG_INFO,string.format("login to gameserver %s failed:%s",name,err))
						else
							log_gateserver:Log(CLog.LOG_INFO,string.format("login to gameserver %s failed:%s",name,ret))
						end
						sock:Close()
						break							
					end
					log_gateserver:Log(CLog.LOG_INFO,string.format("connect to gameserver %s success",name))			
					if name2game[name] then
						name2game[name].sock = sock
					else
						name2game[name] = {sock = sock}
					end
					break	
				else
					sock:Close()
				end
				--print("try to connect to " .. name .. "after 1 sec")
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
		local type = rpk:Read_uint8()
		local actname = rpk:Read_string()
		local player = Player.GetPlayerBySock(sock) or Player.NewGatePly(sock)
		if not player then
			--通知服务器繁忙
			log_gateserver:Log(CLog.LOG_INFO,string.format("CMD_CA_LOGIN reach max gate player count %s",actname))
			sock:Close()
			return
		end
		player.actname = actname
		if player.status then
			log_gateserver:Log(CLog.LOG_INFO,string.format("CMD_CA_LOGIN %s invaild status ",actname,player.status))
			sock:Close()
			return
		end
		player.status = Player.verifying
		local err,result = Db.CommandSync("get " .. actname)		
		if not Player.IsVaild(player) then
			Player.ReleasePlayer(player) --玩家连接已经提前断开
			return
		end
		if err then
			log_gateserver:Log(CLog.LOG_INFO,string.format("CMD_CA_LOGIN %s db error %s",actname,err))
			player.status = nil
			sock:Close()
			return	
		end
		local chaid = result or 0
		chaid = tonumber(chaid)
		if not togroup then
			--通知系统繁忙
			player.status = nil
			sock:Close()
			return
		else
			--验证通过,登录到group
			local rpccaller = RPC.MakeRPC(togroup,"PlayerLogin")
			player.status = Player.login2group
			local err,ret = rpccaller:CallSync(actname,chaid,player.sessionid)			
			if err then
				log_gateserver:Log(CLog.LOG_INFO,string.format("CMD_CA_LOGIN %s PlayerLogin rpc error %s",actname,err))
				player.status = nil
				sock:Close()
				return
			else
				if ret[1] then
					player.groupsession = ret[2]
					if not Player.IsVaild(player) then
						Player.ReleasePlayer(player) --玩家连接已经提前断开
						return
					end						
					if ret[3] then
						--通知客户端创建角色						
						local wpk = CPacket.NewWPacket(64)
						wpk:Write_uint16(NetCmd.CMD_GC_CREATE)
						sock:Send(wpk)						
						player.status = Player.createcha					
					else
						player.status = Player.playing
						log_gateserver:Log(CLog.LOG_INFO,string.format("CMD_CA_LOGIN %s ok playing",actname))
					end
					return 
				else
					--断开连接
					player.status = nil
					sock:Close()
					return
				end	
			end		
		end	
	end)


	--连接groupserver并完成登录
	local function connect_to_group()
		if togroup then
			Player.OnGroupDisconnected()
			log_gateserver:Log(CLog.LOG_INFO,string.format("groupserver disconnected"))
		end
		togroup = nil
		Sche.Spawn(function ()
			while true do
				local sock = Socket.Stream.New(CSocket.AF_INET)
				if not sock:Connect(group_ip,group_port) then
					sock:Establish(CSocket.rpkdecoder(65535))
					toinner:Add(sock,OnInnerMsg,connect_to_group)								
					--登录到groupserver
					local rpccaller = RPC.MakeRPC(sock,"GateLogin")
					local err,ret = rpccaller:CallSync("gate1")
					if err or ret == "Login failed" then
						if err then
							log_gateserver:Log(CLog.LOG_INFO,string.format("login group failed:%s",err))
						else
							log_gateserver:Log(CLog.LOG_INFO,string.format("login group failed:%s",ret))
						end
						sock:Close()
						Exit()	
					end
					togroup = sock
					log_gateserver:Log(CLog.LOG_INFO,"connect to group success")
					for k,v in pairs(ret) do
						connect_to_game(v[1],v[2],v[3])
					end					
					break
				else
					sock:Close()
				end
				Sche.Sleep(1000)
			end
		end)	
	end


	Db.Init(redis_ip,redis_port)
	connect_to_group()
	while not togroup or not Db.Finish() do
		Sche.Yield()
	end

	--在连接上groupserver和db初始化完成后才启动对客户端的监听

	if TcpServer.Listen(ip,port,function (sock)
			sock:Establish(CSocket.rpkdecoder(4096),1024)
			toclient:Add(sock,OnClientMsg,Player.OnPlayerDisconnected,60000)		
		end) then
		log_gateserver:Log(CLog.LOG_ERROR,string.format("start server on %s:%d error",ip,port))

	else
		log_gateserver:Log(CLog.LOG_ERROR,string.format("start server on %s:%d success",ip,port))
	end

else
	log_gateserver.Log(CLog.LOG_ERROR,"get config error:" .. err)
	Exit()		
end
