local TcpServer = require "lua/tcpserver"
local App = require "lua/application"
local RPC = require "lua/rpc"
local NetCmd = require "Survive/netcmd/netcmd"
local MsgHandler = require "Survive/netcmd/msghandler"
local Db = require "Survive/common/db"
local Sche = require "lua/sche"
local Socket = require "lua/socket"
local Gate = require "Survive/gameserver/gate"
local Timer = require "lua/timer"
local Map = require "Survive/gameserver/map"

local togroup
local gameApp = App.New()

--注册gate模块的RPC服务
Gate.RegRpcService(gameApp)
--注册Map模块的RPC服务
Map.RegRpcService(gameApp)

local function connect_to_group()
	if togroup then
		print("togroup disconnected")
	end
	togroup = nil
	Sche.Spawn(function ()
		while true do
			local sock = Socket.New(CSocket.AF_INET,CSocket.SOCK_STREAM,CSocket.IPPROTO_TCP)
			if not sock:Connect("127.0.0.1",8811) then
				sock:Establish(CSocket.rpkdecoder(65535))
				gameApp:Add(sock,MsgHandler.OnMsg,connect_to_group)				
				--登录到groupserver
				local rpccaller = RPC.MakeRPC(sock,"GameLogin")
				local err,ret = rpccaller:Call("game1","127.0.0.1",8812)
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
				break
			end
			print("try to connect to group after 1 sec")
			Sche.Sleep(1000)
		end
	end)	
end

connect_to_group()
Db.Init()
gameApp:Run()


while not togroup or not Db.Finish() do
	Sche.Yield()
end

if TcpServer.Listen("127.0.0.1",8812,function (sock)
		sock:Establish(CSocket.rpkdecoder(65535))
		gameApp:Add(sock,MsgHandler.OnMsg,Gate.OnGateDisconnected)		
	end) then
	print("start server on 127.0.0.1:8812 error")
	stop_program()	
else
	print("start server on 127.0.0.1:8812")
end
