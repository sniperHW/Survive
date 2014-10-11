local TcpServer = require "lua/tcpserver"
local App = require "lua/application"
local RPC = require "lua/rpc"
local Player = require "Survive/groupserver/groupplayer"
local NetCmd = require "Survive/netcmd/netcmd"
local MsgHandler = require "Survive/netcmd/msghandler"
local Db = require "Survive/common/db"
local Sche = require "lua/sche"
local Gate = require "Survive/groupserver/gate"
local Game = require "Survive/groupserver/game"

Db.Init()
while not Db.Finish() do
	Sche.Yield()
end

local groupApp = App.New()
--注册Gate模块提供的RPC服务
Gate.RegRpcService(groupApp)
--注册Game模块提供的RPC服务	
Game.RegRpcService(groupApp)
--注册Player模块提供的RPC服务
Player.RegRpcService(groupApp)

local success
local function on_disconnected(sock,errno)
	if sock.type == "gate" then
		Gate.OnGateDisconnected(sock,errno)
	elseif sock.type == "game" then
		Game.OnGameDisconnected(sock,errno)
	end
end

groupApp:Run(function ()
	success = not TcpServer.Listen("127.0.0.1",8811,function (sock)
		sock:Establish(CSocket.rpkdecoder(65535))
		groupApp:Add(sock,MsgHandler.OnMsg,on_disconnected)		
	end)
end)

if not success then
	print("start server on 127.0.0.1:8811 error")
	stop_program()		
else
	print("start server on 127.0.0.1:8811")
end

