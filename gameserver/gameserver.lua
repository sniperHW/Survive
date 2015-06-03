log_gameserver = CLog.New("gameserver")
local TcpServer = require "lua.tcpserver"
local App = require "lua.application"
local RPC = require "lua.rpc"
local NetCmd = require "netcmd.netcmd"
local MsgHandler = require "netcmd.msghandler"
local Sche = require "lua.sche"
local Socket = require "lua.socket"
local Gate = require "gameserver.gate"
local Timer = require "lua.timer"
local Map = require "gameserver.map"
local Config = require "common.config"

--App.SetMaxRecverPerSocket(65535)
local ret,err = Config.Init("测试1服","127.0.0.1",6379)
if ret then

	local group_ip = Config.Get("group")[1]
	local group_port = Config.Get("group")[2]

	local ip = Config.Get("game1")[1]
	local port = Config.Get("game1")[2]

	local gameApp = App.New()

	--注册gate模块的RPC服务
	Gate.RegRpcService(gameApp)
	--注册Map模块的RPC服务
	Map.RegRpcService(gameApp)

	local function connect_to_group()
		if togroup then
			log_gameserver:Log(CLog.LOG_INFO,string.format("groupserver disconnected"))
		end
		togroup = nil
		Sche.Spawn(function ()
			while true do
				local sock = Socket.Stream.New(CSocket.AF_INET)
				if not sock:Connect(group_ip,group_port) then
					sock:Establish(CSocket.rpkdecoder(65535))
					gameApp:Add(sock,MsgHandler.OnMsg,connect_to_group)				
					--登录到groupserver
					local rpccaller = RPC.MakeRPC(sock,"GameLogin")
					local err,ret = rpccaller:CallSync("game1",ip,port)
					if err or ret == "Login failed" then
						if err then
							log_gameserver:Log(CLog.LOG_INFO,string.format("GameLogin RPC error:%s",err))
						else
							log_gameserver:Log(CLog.LOG_INFO,string.format("GameLogin RPC error:%s","Login failed"))
						end
						sock:Close()
						Exit()	
					end
					togroup = sock
					log_gameserver:Log(CLog.LOG_INFO,string.format("connect to groupserver success"))				
					break
				else
					sock:Close()
				end
				Sche.Sleep(1000)
			end
		end)	
	end

	connect_to_group()
	--gameApp:Run()

	function Send2Group(wpk)
		if togroup then
			togroup:Send(wpk)
		end
	end


	while not togroup do
		Sche.Yield()
	end

	--[[Sche.Spawn( function ()
		while true do
			collectgarbage("collect")
			Sche.Sleep(5000)
		end
	end)]]--

	if TcpServer.Listen(ip,port,function (sock)
			sock:Establish(CSocket.rpkdecoder(65535))
			gameApp:Add(sock,MsgHandler.OnMsg,Gate.OnGateDisconnected)		
		end) then
		log_gameserver:Log(CLog.LOG_ERROR,string.format("start server %s:%d error",ip,port))
		Exit()	
	else
		log_gameserver:Log(CLog.LOG_INFO,string.format("start server on %s:%d",ip,port))
	end

else
	log_gameserver:Log(CLog.LOG_ERROR,"get config error:" .. err)
	Exit()		
end
