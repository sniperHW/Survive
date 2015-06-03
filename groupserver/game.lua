local NetCmd = require "netcmd.netcmd"

local sock2game = {}
local name2game = {}

local function GetGameBySock(sock)
	return sock2game[sock]
end

local function RegRpcService(app)
	--gameserver登录到groupserver
	app:RPCService("GameLogin",function (sock,name,ip,port)
		if sock2game[sock] == nil and name2game[name] == nil then
			local game = {sock = sock,name = name,players={},plycount=0,ip=ip,port=port}
			sock.type = "game"
			sock2game[sock] = game
			name2game[name] = game
			log_groupserver:Log(CLog.LOG_INOF,string.format("%s Login Success",name))
			--通知gate有gameserver连上group	
			local wpk = CPacket.NewWPacket(128)
			wpk:Write_uint16(NetCmd.CMD_GA_NOTIFY_GAME)
			wpk:Write_string(name)
			wpk:Write_string(ip)
			wpk:Write_uint16(port)
			BoradCast2Gate(wpk)			
			return "Login Success"
		else
			return "Login failed"
		end
	end)
end

local function GetGames()
	local ret = {}
	for k,v in pairs(name2game) do
		table.insert(ret,{v.name,v.ip,v.port})
	end
	return ret
end

local function OnGameDisconnected(sock,errno)
	local game = sock2game[sock]
	if game then
		log_groupserver:Log(CLog.LOG_INOF,string.format("%s disconnected",game.name))
		for k,v in pairs(game.players) do
			v.gamesession = nil
			v.mapinstance = nil
			local wpk = CPacket.NewWPacket(64)
			wpk:Write_uint16(NetCmd.CMD_GC_BACK2MAIN)
			v:Send2Client(wpk)
			v.bag:SynBattleItem()							
		end

		if game.survive then
			game.OnGameDisconnected()
			game.survive = nil
		end
		sock2game[sock] = nil
		game.sock = nil
		name2game[game.name] = nil
	end	
end

local function Bind(game,player,sessionid)
	 game.players[sessionid] = player
	 game.plycount = game.plycount + 1
	 player.gamesession = {game=game,sessionid=sessionid}
end

local function UnBind(player)
	if player.gamesession then
		local game = player.gamesession.game
		if game then
			game.players[player.gamesession.sessionid] = nil
			game.plycount = game.plycount - 1
			player.gamesession = nil
		end
	end
end

local function GetMinGame()
	local g
	for k,v in pairs(sock2game) do
		if not g or g.plycount > v.plycount then
			g = v
		end
	end
	return g
end

return {
	GetGameBySock = GetGameBySock,
	Bind = Bind,
	UnBind = UnBind,
	OnGameDisconnected = OnGameDisconnected,
	RegRpcService = RegRpcService,
	GetGames   = GetGames,
	GetMinGame = GetMinGame,
}
