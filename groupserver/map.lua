local Game = require "groupserver.game"
local RPC = require "lua.rpc"
local LinkQue = require "lua.linkque"
local Sche = require "lua.sche"
local NetCmd = require "netcmd.netcmd"
local Bag = require "groupserver.bag"
local Achi = require "groupserver.achievement"
local Task = require "groupserver.everydaytask"
local Survive = require "groupserver.survive"
require "common.TableMap"


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
	if self.size == 0 then
		local m = maps[self.type]
		if m then
			print("release map instance",self.id) 
			m[self.id] = nil
		end
	end
end


--获取一个能容纳count个玩家的type类型地图实例 
local function GetInstanceByType(type,count)
	local m = maps[type]
	if m then
		for k,v in pairs(m) do
			if not v.game.sock then
				m[k] = nil
			elseif v.max - v.size >= count then
				return {v.game,v}
			end
		end
	end	
	--没有合适的实例,寻找一个人数最少的game,请求在上面创建地图
	return {Game.GetMinGame(),nil}
end

local function PackPlayer(ply)
	local gatesession = nil
	if ply.gatesession then
		gatesession = {name=ply.gatesession.gate.name,id=ply.gatesession.sessionid}
	end
	return 	{
			nickname=ply.nickname,
			actname=ply.actname,
			gatesession = gatesession,
			groupsession = ply.groupsession,
			avatid = ply.avatarid,--暂时设置
			fashion = ply.bag:GetItemId(Bag.fashion),
			weapon = {id = ply.bag:GetItemId(Bag.weapon),count = ply.bag:GetItemCount(Bag.weapon),attr = ply.bag:GetItemAttr(Bag.weapon)},			
			attr = ply.attr:Pack2Game(),
			skills = ply.skills:GetSkills(),
			battleitem = ply.bag:FetchBattleItem()
		}	
end

local function EnterMapOpen(ply,maptype,mapdef)
	print("EnterMapOpen")
	local m = GetInstanceByType(maptype,1)
	if not m[1] then
		return false,"no instance"
	end	
	local game = m[1]
	local instance = m[2]	
	local plys = {PackPlayer(ply)}
	local mapid = 0
	if instance then
		print("got instance",instance.id)
		mapid = instance.id
		instance:AddPlyCount(1)
	end
	local rpccaller = RPC.MakeRPC(game.sock,"EnterMap")	
	local err,ret = rpccaller:CallSync(mapid,maptype,plys)
	if err or not ret[1] then
		if instance then
			instance:SubPlyCount(1)
		end
		--notify ply entermap failed
		return false,err or ret[2]
	end
	mapid = ret[2]
	local gameids = ret[3]
	log_groupserver:Log(CLog.LOG_ERROR,string.format("EnterMapOpen %s gameid %d gamename [%s]",ply.actname,gameids[1],game.name))
	Game.Bind(game,ply,gameids[1])
	if not instance then
		log_groupserver:Log(CLog.LOG_ERROR,string.format("EnterMapOpen create new map [%d] instance %d",maptype,mapid))			
		instance = mapinstance:new(game,1,mapdef["MaxPly"],mapid,maptype)
		local m = maps[maptype]
		if not m then
			m = {}
			maps[maptype] = m
		end
		m[mapid] = instance
	end
	ply.mapinstance = instance
	ply.status = playing
	return true
end

local function EnterMapPersonal(ply,maptype,mapdef)
	--notify client approve 
	local wpk = CPacket.NewWPacket(64)
	wpk:Write_uint16(NetCmd.CMD_GC_ENTERPSMAP)
	wpk:Write_uint16(maptype)
	ply:Send2Client(wpk)	
end

local MapReqQues = {}
local ReqQue = {}
function ReqQue:new(maptype,mapdef)
	local o = {}   
	setmetatable(o, self)
	self.__index = self
	o.que = LinkQue.New()
	o.maxWait = mapdef["MaxWait"] or 5000
	o.plyMax = mapdef["MaxPly"]
	o.maptype = maptype
	MapReqQues[maptype]  = o
	return o
end

function ReqQue:Push(ply)
	ply.status = queueing
	ply.ReqTick = C.GetSysTick()
	self.que:Push(ply)
end

function ReqQue:Remove(ply)
	self.que:Remove(ply)
	ply.ReqTick = nil
end

function ReqQue:ProcessEnter()
	local size = self.que:Len()
	if size > self.plyMax then size = self.plyMax end
	local plys = {}
	local tmp = {}	
	for i = 1,size do
		local ply = self.que:Pop()
		ply.ReqTick = nil
		local gsession =  ply.gatesession
		if gsession then
			gsession = {name=gsession.gate.name,id=gsession.sessionid}
		else
			gsession = nil
		end
		table.insert(plys,PackPlayer(ply))
		table.insert(tmp,ply)
	end
	local game = Game.GetMinGame()
	local err,ret
	if game then
		local rpccaller = RPC.MakeRPC(game.sock,"EnterMap")	
		err,ret = rpccaller:CallSync(0,self.maptype,plys)
	end
	if not game or err or not ret[1] then
		if err then
			print(err)
		end
		for k,v in pairs(tmp) do
			v.status = playing
		end
		tmp = {}
		return
	end	
	local mapid = ret[2]
	local gameids = ret[3] 	
	instance = mapinstance:new(game,size,self.plyMax,mapid,self.maptype)
	local m = maps[self.maptype]
	if not m then
		m = {}
		maps[self.maptype] = m
	end
	m[mapid] = instance
	for i=1,size do
		Game.Bind(game,tmp[i],gameids[i])
		tmp[i].mapinstance = instance
		tmp[i].status = playing
		if self.maptype == 203 then  
			tmp[i].achieve:OnEvent(Achi.AchiType.ACHI_5PVE)
			tmp[i].task:OnEvent(Task.TaskType.PVE5)
		elseif self.maptype == 204 then
			tmp[i].achieve:OnEvent(Achi.AchiType.ACHI_5PVP)
			tmp[i].task:OnEvent(Task.TaskType.PVP5)
		end
		log_groupserver:Log(CLog.LOG_ERROR,string.format("EnterMapMutil %s gameid %d gamename [%s]",tmp[i].actname,gameids[1],game.name))
	end
	log_groupserver:Log(CLog.LOG_ERROR,string.format("EnterMapMutil create new map [%d] instance %d",self.maptype,mapid))			
end

function ReqQue:Tick()
	while true do
		if self.que:Len() >= self.plyMax then
			self:ProcessEnter()
		else	
			break
		end
	end
	local tick = C.GetSysTick()
	local f = self.que:Front()
	if f and tick >= f.ReqTick + self. maxWait then
		self:ProcessEnter()
	end
end

local function EnterMapMutil(ply,maptype,mapdef)
	local q = MapReqQues[maptype] or ReqQue:new(maptype,mapdef)
	q:Push(ply)
	return true
end

local function EnterMap(ply,type)
	print("EnterMap",type)
	local mapdef = TableMap[type]
	if not mapdef then
		--print("EnterMap1",type)
		return false,"undefine map type:" .. type
	end

	local fishing_start =  ply.attr:Get("fishing_start")
	local gather_start =  ply.attr:Get("gather_start")
	local sit_start = ply.attr:Get("sit_start")
	if (fishing_start and fishing_start ~=0) or (gather_start and gather_start ~= 0) or (sit_start and sit_start ~=0) then
	    	--print("EnterMap2",type)
	    	return false,"alreay in fishing or gather"
	end
	--print("EnterMap3",mapdef.type)
	local playtype = mapdef["PlayType"]
	if type == 206 then
		Transfer(ply,nil,nil)
	elseif playtype == "open" then
		return 	EnterMapOpen(ply,type,mapdef)
	elseif playtype == "personal"  then
		return EnterMapPersonal(ply,type,mapdef)
	elseif playtype == "mutil" then
		return EnterMapMutil(ply,type,mapdef)
	else
		--print("EnterMap4",type)
		return false,"undefine playtype"
	end
end

local function LeaveMap(ply)
	local err,ret
	local rpccaller = RPC.MakeRPC(ply.gamesession.game.sock,"LeaveMap")	
	err,ret = rpccaller:CallSync(ply.gamesession.sessionid)
	if not err then
		if type(ply.mapinstance) ~= "number" then
			ply.mapinstance:SubPlyCount(1)
		end
		Game.UnBind(ply)
		ply.mapinstance = nil
		local wpk = CPacket.NewWPacket(256)
		wpk:Write_uint16(NetCmd.CMD_GC_BACK2MAIN)
		ply:Send2Client(wpk)	
		ply.bag:SynBattleItem()	
		--print("leave map success")
	end
	return ret
end

Sche.Spawn( function ()
	while true do
		for k,v in pairs(MapReqQues) do
			local ret,err = pcall(v.Tick,v)
			if not ret then
				log_groupserver:Log(CLog.LOG_ERROR,err)
			end
		end
		Sche.Sleep(1000)
	end
end)

return {
	EnterMap = EnterMap,
	LeaveMap = LeaveMap,
}