local Game = require "Survive/groupserver/game"
local RPC = require "lua/rpc"


--地图实例
--[[
local mapinstance = {
	game,     --所在gameserver
	size,     --玩家数量
	max,      --玩家上限
	id,       --实例id,在gameserver上唯一
	type,     --地图类型
}
]]--
local maps = {} --所有的地图实例

local mapinstance = {}

function mapinstance:new(game,size,max,id,type)
  local o = {}   
  setmetatable(o, self)
  self.__index = self
  o.game = game
  o.size = size
  o.id = id
  o.type = type
  o.max = max
  return o
end

function mapinstance:AddPlyCount(count)
	self.size = self.size + count
end

function mapinstance:SubPlyCount(count)
	self.size = self.size - count
end


--获取一个能容纳count个玩家的type类型地图实例 
local function GetInstanceByType(type,count)
	local m = maps[type]
	if m then
		for k,v in pairs(m) do
			if v.max - v.size >= count then
				return {v.game,v}
			end
		end
	end	
	--没有合适的实例,寻找一个人数最少的game,请求在上面创建地图
	return {Game.GetMinGame(),nil}
end


local function EnterMap(ply,type)
	print("EnterMap")
	--暂时不处理需要配对进入的地图类型
	local m = GetInstanceByType(type,1)
	if not m[1] then
		return false,"no instance"
	end	
	local game = m[1]
	local instance = m[2]	
	local plys = {
		{
			nickname=ply.nickname,
			actname=ply.actname,
			gatesession = {name=ply.gatesession.gate.name,id=ply.gatesession.sessionid},
			groupsession = ply.groupsession,
			avatid = 1,--暂时设置
			attr = ply.attr:Pack2Game()
		}		
	}
	local mapid = 0
	if instance then
		mapid = instance.id
		instance:AddPlyCount(1)
	end
	local rpccaller = RPC.MakeRPC(game.sock,"EnterMap")	
	local err,ret = rpccaller:Call(mapid,type,plys)
	if err or not ret[1] then
		if instance then
			instance:SubPlyCount(1)
		end
		return false,err or ret[2]
	end
	mapid = ret[2]
	gameids = ret[3]
	Game.Bind(game,ply,gameids[1])
	if not instance then
		print("create new map instance",mapid)
		instance = mapinstance:new(game,1,100,mapid,type)
		local m = maps[type]
		if not m then
			m = {}
			maps[type] = m
		end
		m[instance] = instance
		
	end
	return true
end


return {
	EnterMap = EnterMap,
}


--[[
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

	local game = Game.GetMinGame()
	if not game then
		return nil
	end
	
	return {game,0}
end

local function onGameDisconnect(game)
	for k,v in pairs(gamemaps[game]) do
		local type = v.type
		for k1,v1 in pairs(maps[type]) do
			if v1.game == game then
				maps[type][k1] = nil
			end
		end
	end	
	gamemaps[game] = nil 
end

local function addInstance(game,type,mapid,plymax,plycount)
	local instance = {game=game,mapid=mapid,plycount=plycount,plymax=plymax,type=type}	
	local m = maps[type]
	if not m then
		m = {}
		maps[type] = m
	end
	m[mapid] = instance	
	local g = gamemaps[game]
	if not g then
		g = {}
		gamemaps[game] = g
	end	
	g[mapid] = instance
	GroupApp.grouplog(LOG_INFO,"addInstance " .. type .. " " .. mapid)
	if not game.onGameDisconnect then
		game.onGameDisconnect = onGameDisconnect
	end
end

local function remInstance(game,type,mapid)
	local m = maps[type]
	if m then
		m[mapid] = nil
	end	
	local g = gamemaps[game]
	if g then
		local m = g.maps[mapid]
		g.maps[mapid] = nil
	end
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

--local Cjson = require "cjson"
local function enterMap(ply,type)
	--暂时不处理需要配对进入的地图类型
	local m = getInstanceByType(type,1)
	if not m then
		return false
	end	
	local mapid = m[2]
	local game = m[1]
	local gate = Gate.GetGateByConn(ply.agent.conn)	
	local paramply = {
		{
			nickname=ply.nickname,
			actname=ply.actname,
			gate = {name=gate.name,id=ply.agent.id},
			groupid = ply.groupid,
			avatid = 1,--暂时设置
			attr = ply.attr:Pack2Game()
		}
	}
	local param = {mapid,type,paramply}
	local r = Rpc.RPCCall(game.conn,"EnterMap",param,{OnRPCResponse=function (_,ret,err)
		if err then
			if mapid ~= 0 then 
				subMapPlyCount(type,mapid,1) 
			end	
			Game.RemoveGamePly(ply,game)			
			GroupApp.grouplog(LOG_INFO,ply.actname .. " enter map " .. type .. " error:" .. err)
		else
			if mapid == 0 then
				mapid = ret[1]
				addInstance(game,type,mapid,200,1)
				addMapPlyCount(type,mapid,1)
			end
			ply.game = {conn=game.conn,id=ret[2][1]}
		end
		ply.status = stat_playing
	end})
	if r then
		if mapid ~= 0 then  
			addMapPlyCount(type,mapid,1)
		end
		Game.InsertGamePly(ply,game)	
	end
	return r
end

return {
	GetInstanceByType = getInstanceByType,
	AddInstance = addInstance,
	OnGameDisconnect = onGameDisconnect,
	AddMapPlyCount = addMapPlyCount,
	SubMapPlyCount = subMapPlyCount,
	RemInstance = remInstance,
	EnterMap = enterMap,
}]]--
