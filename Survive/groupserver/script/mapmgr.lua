local Rpc = require "script/rpc"
local Gate = require "script/gate"
local Game = require "script/game"
--gameserver上的一个地图实例
local mapinstance = {
	game,     --所在gameserver
	plycount, --玩家数量
	plymax,   --玩家上限
	mapid,    --实例id,在gameserver上唯一
	type,
}

local gamemaps = {} --gameserver上的所有map实例
local maps = {}     --所有map实例


--获取一个能容纳plycount个玩家的type类型地图实例
--返回{game,mapid}
--如果找不到合适的实例game为运行着最少实例的gameserver,mapid为0
local function getInstanceByType(type,plycount)
	local m = maps[type]
	if m then
		for k,v in pairs(m) do
			if v.plymax - v.plycount >= plycount then
				return {v.game,v.mapid}
			end
		end
	end
	
	if not gamemaps then
		return nil
	end
	
	local min = 65535
	local game = nil
	for k,v in pairs(gamemaps) do
		if v.size < min then
			min = v.size
			game = k
		end
	end
	
	if not game then
		return nil
	end
	return {game,0}
end

local function addInstance(game,type,mapid,plymax,plycount)
	local instance = {game=game,mapid=mapid,plycount=plycount,plymax=plymax,type=type}	
	local m = maps[type]
	if not m then
		m = {}
	end
	m[mapid] = instance	
	local g = gamemaps[game]
	if not g then
		g = {size=0,maps={}}
	end	
	g.maps[mapid] = instance
	g.size = g.size + 1
end

local function remInstance(game,type,mapid)
	local m = maps[type]
	if m then
		m[mapid] = nil
	end	
	local g = gamemaps[game]
	if g then
		local m = g.maps[mapid]
		g.size = g.size - m.plycount
		g.maps[mapid] = nil
	end
end

local function onGameDisconnect(game)
	gamemaps[game] = nil 
end

local function onGameConnect(game)
	gamemaps[game] = {size = 0}
end

local function addMapPlyCount(type,mapid,count)
	local m = maps[type]
	if m then
		local ins = m[mapid]
		if ins then
			ins.plycount = ins.plycount + count
			return true
		end
	end
	return false
end

local function subMapPlyCount(type,mapid,count)
	local m = maps[type]
	if m then
		local ins = m[mapid]
		if ins then
			ins.plycount = ins.plycount - count
			if ins.plycount == 0 then
				--没玩家了，销毁实例
				m[mapid] = nil
			end
			return true
		end
	end
	return false	
end

local function addGamePlyCount(game,count)
	local g = gamemaps[game]
	if g then
		g.size = g.size + count
		return true
	end
	return false
end

local function subGamePlyCount(game,count)
	local g = gamemaps[game]
	if g then
		g.size = g.size - count
		return true
	end
	return false
end

local function enterMap(ply,type)
	print("enterMap")
	--暂时不处理需要配对进入的地图类型
	local m = getInstanceByType(type,1)
	if not m then
		return false
	end	
	local mapid = m[2]
	local game = m[1]
	local gate = Gate.GetGateByConn(ply.gate.conn)	
	local paramply = {
		chaname=plychaname,
		gate = {name=gate.name,id=ply.gate.id},
		groupid = ply.groupid,
	}
	local param = {paramply}
	return Rpc.RPCCall(game.conn,"EnterMap",param,{OnRPCResponse=function (_,ret,err)
		if err then	
		
		else
			if mapid == 0 then
				mapid = ret[1]
				addInstance(game,type,mapid,32,1)
			else
				addMapPlyCount(type,mapid,1)
				addGamePlyCount(game,1)
			end
			ply.game = {conn=game.conn,id=ret[2][1]}
			Game.insertGamePly(ply,game)	
		end
		ply.status = stat_playing
	end})
end

return {
	GetInstanceByType = getInstanceByType,
	AddInstance = addInstance,
	OnGameDisconnect = onGameDisconnect,
	AddMapPlyCount = addMapPlyCount,
	SubMapPlyCount = subMapPlyCount,
	AddGamePlyCount = addGamePlyCount,
	SubGamePlyCount = subGamePlyCount,
	RemInstance = remInstance,
	EnterMap = enterMap,
	OnGameConnect = onGameConnect,
}
