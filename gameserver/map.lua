package.cpath = "Survive/?.so"
local Avatar = require "Survive/gameserver/avatar"
local Player = require "Survive/gameserver/gameplayer"
local Que = require "lua/queue"
local Cjson = require "cjson"
local Gate = require "Survive/gameserver/gate"
local Attr = require "Survive/gameserver/attr"
local Skill = require "Survive/gameserver/skill"
local Aoi = require "aoi"
local Astar = require "astar"
local Timer = require "lua/timer"
local NetCmd = require "Survive/netcmd/netcmd"
local MsgHandler = require "Survive/netcmd/msghandler"
local IdMgr = require "Survive/common/idmgr"
local Sche = require "lua/sche"

local mapdef = {
	[1] = {
		gridlength = 100,          --管理格大小
		xcount,
		ycount,
		radius = 100,              --视距大小
		coli   = "./Survive/gameserver/fightMap.meta",   --寻路碰撞文件
		astar  = nil,
	},
}

for k,v in ipairs(mapdef) do
	v.astar,v.xcount,v.ycount = Astar.create(v.coli)
	if not v.astar then
		print("astar init error:" .. v.coli)
	end
end

local function GetDefByType(type)
	return mapdef[type]
end

local maps = {} --所有的地图实例
local mapidx = IdMgr.New(65535)

local function GetMapById(id)
	id = bit32.rshift(id,16)
	--print("mapid",id)
	return maps[id]
end

local map = {
	maptype,
	mapid,
	astar,
	aoi,
	avatars,
	freeidx,
	plycount,      
	movingavatar, 
	movtimer,
}

function map:new(mapid,maptype)
	local o = {}   
	setmetatable(o, self)
	self.__index = self
	o.mapid = mapid
	o.maptype = maptype
	o.movingavatar = {}
	o.avatars = {}
	o.freeidx = IdMgr.New(4096)
	local mapdef = GetDefByType(maptype)	
	o.astar = mapdef.astar
	o.aoi = Aoi.create_map(mapdef.gridlength,mapdef.radius,0,0,mapdef.xcount-1,mapdef.ycount-1)
	o.movtimer = Timer.New():Register(function () o:process_mov() return true end,100)
	o.plycount = 0
	Sche.Spawn(function () o.movtimer:Run() end)
	maps[mapid] = o  
	return o
end

function map:GetAvatar(id)
	return self.avatars[id]
end

function map:entermap(plys)
	if self.freeidx:Len() < #plys then
		return nil
	else
		local gameids = {}
		for _,v in pairs(plys) do
			local avatid = v.avatid
			local gate = Gate.GetGateByName(v.gatesession.name)
			if not gate then
				table.insert(gameids,false)
			else
				local id = self.freeidx:Get()
				local ply = Player.New(bit32.lshift(self.mapid,16) + id,avatid)
				Gate.Bind(gate,ply,v.gatesession.id)
				self.avatars[ply.id] = ply
				ply.map = self
				ply.nickname = v.nickname
				ply.actname = v.actname
				ply.groupsession = v.groupsession
				ply.attr = Attr.New():Init(ply,v.attr)
				ply.skillmgr = Skill.New()
				table.insert(gameids,ply.id)
				ply.pos = {220,120}
				ply.dir = 5
				ply:on_entermap()	
				self.plycount = self.plycount + 1
				Aoi.enter_map(self.aoi,ply.aoi_obj,ply.pos[1],ply.pos[2])
				print(ply.actname .. " enter map",ply.id)
			end
		end 
		return gameids
	end
end

function map:leavemap(id)
	local ply = self:GetAvatar(id)
	if ply then
		ply:Release(self.freeidx)
		self.plycount = self.plycount - 1
		self.avatars[id] = nil
		return true
	end
	return false
end

function map:findpath(from,to)
	return Astar.findpath(self.astar,from[1],from[2],to[1],to[2])
end

function map:beginMov(avatar)
	if not self.movingavatar[avatar.id] then
		self.movingavatar[avatar.id] = avatar
	end
end

function map:Release()
	for k,v in ipairs(self.avatars) do
		v:Release(self.freeidx)
	end
	Aoi.destroy_map(self.aoi)
	self.movtimer:Stop()
	maps[self.mapid] = nil
end

function map:process_mov()
	local stops = {}
	for k,v in pairs(self.movingavatar) do
		if v:process_mov() then
			table.insert(stops,k)
		end
	end
	
	for k,v in pairs(stops) do
		self.movingavatar[v] = nil
	end
	return 1 
end

local function GetPlayerById(id)
	local m = GetMapById(id) 
	if m then
		return m:GetAvatar(id)
	else
		print("m nil")
		return nil
	end	
end

--注册RPC服务
local function RegRpcService(app)
	app:RPCService("EnterMap",function (sock,mapid,type,plys)
		print("EnterMap",type)
		local plyids
		local m
		if mapid == 0 then
			mapid = mapidx:Get()
			if not mapid then
				return {false,"game busy"}
			end
			m = map:new(mapid,type)
		else
			m = maps[mapid] 
			if not m then
				return {false,"invaild mapid"}				
			end
		end
		plyids = m:entermap(plys)
		if not plyids and mapid == 0 then
			m:Release()
			return {false,"enter failed"}
		end
		return {true,mapid,plyids} 			
	end)
	
	app:RPCService("LeaveMap",function (sock,id)
		local m = GetMapById(id)
		if m and m:leavemap(id) then
			if m.plycount == 0 then
				--清除地图
			end
			return true
		end
		return false
	end)
	--客户端连接重新建立 
	app:RPCService("CliReConn",function (sock,id,gatesession)
		local ply = GetPlayerById(id)
		if ply and ply.gatesession then
			return false
		end
		local gate = Gate.GetGateByName(gatesession.name)
		if not gate then
			return false
		end
		Gate.Bind(gate,ply,gatesession.id)
		ply:ReConnect()
		return true
	end)
end

MsgHandler.RegHandler(NetCmd.CMD_CS_MOV,function (sock,rpk)
	--print("CMD_CS_MOV")
	local id = rpk:Reverse_read_uint32()
	local ply = GetPlayerById(id)
	if ply then
		local x = rpk:Read_uint16()
		local y = rpk:Read_uint16()
		ply:Mov(x,y)
	end
end)

MsgHandler.RegHandler(NetCmd.CMD_CS_USESKILL,function (sock,rpk)
	local id = rpk:Reverse_read_uint32()
	local ply = GetPlayerById(id)
	if ply then
		ply:UseSkill(rpk)
	end
end)

--客户端的连接断开
MsgHandler.RegHandler(NetCmd.CMD_GGAME_CLIDISCONNECTED,function (sock,rpk)
	local id = rpk:Reverse_read_uint32()	
	local ply = GetPlayerById(id)
	if ply then
		print(ply.actname .. " CMD_GGAME_CLIDISCONNECTED")
		Gate.UnBind(ply)
	end
end)


return {
	RegRpcService = RegRpcService,
}		
