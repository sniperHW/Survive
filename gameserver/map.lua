package.cpath = "SurviveServer/?.so"
local Avatar = require "SurviveServer.gameserver.avatar"
local Player = require "SurviveServer.gameserver.gameplayer"
local LinkQue = require "lua.linkque"
local Cjson = require "cjson"
local Gate = require "SurviveServer.gameserver.gate"
local Attr = require "SurviveServer.gameserver.attr"
local Skill = require "SurviveServer.gameserver.skill"
local Aoi = require "aoi"
local Astar = require "astar"
local Timer = require "lua.timer"
local NetCmd = require "SurviveServer.netcmd.netcmd"
local MsgHandler = require "SurviveServer.netcmd.msghandler"
local IdMgr = require "SurviveServer.common.idmgr"
local Sche = require "lua.sche"
local MapLogic = require "SurviveServer.gameserver.maplogic"
local Util = require "SurviveServer.gameserver.util"
require "SurviveServer.common.TableMap"

--local mapdef = {
--	[1] = {
		--gridlength = 100,          --管理格大小
		--xcount,
		--ycount,
		--radius = 100,              --视距大小
		--coli   = "./SurviveServer/gameserver/fightMap.meta",   --寻路碰撞文件
		--astar  = nil,
--	},
--}

for k,v in pairs(TableMap) do
	if k ~= 205 then
		v.astar,v.xcount,v.ycount = Astar.create("./SurviveServer/gameserver/" .. v.Colision)
		if not v.astar then
			log_gameserver:Log(CLog.LOG_ERROR,"astar init error:" .. v.Colision)
		else
			log_gameserver:Log(CLog.LOG_ERROR,string.format("load %d,%d,%d,%s,%d",k,v.xcount,v.ycount,v.Colision,v.GridLength))
		end
	end
end

local function GetDefByType(type)
	return TableMap[type]
end

local maps = {} --所有的地图实例
local mapidx = IdMgr.New(65535)

local function GetMapById(id)
	id = bit32.rshift(id,16)
	return maps[id]
end

local map = {}

function map:new(mapid,maptype)
	local o = {}
	--self.__gc = function () log_gameserver:Log(CLog.LOG_INFO,"map gc") end	   
	setmetatable(o, self)
	self.__index = self
	o.mapid = mapid
	o.maptype = maptype
	o.movingavatar = {}
	local mapdef = GetDefByType(maptype)
	o.mapdef = mapdef	
	o.astar = mapdef.astar
	o.aoi = Aoi.create_map(Util.Pixel2Grid(mapdef.GridLength),Util.Pixel2Grid(mapdef.ViewRadiu),0,0,mapdef.xcount-1,mapdef.ycount-1)
	o.movtimer = Timer.New("runImmediate"):Register(function () o:process_mov() end,100)
	o.logic = MapLogic.New(o)
	o.generalTimer = Timer.New("runImmediate"):Register(function ()
				local tick = C.GetSysTick()
				for k,v in pairs(o.avatars) do
					v:Tick(tick)
				end
				if o.logic and o.logic.Tick then
					o.logic:Tick(tick) --tick the map logic
 				end
			    end,500)
	maps[mapid] = o
	return o
end

function map:GetAvatar(id)
	return self.avatars[id]
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
	for k,v in pairs(self.avatars) do
		v:Release(1)--release on map destroy
	end
	Aoi.destroy_map(self.aoi)
	self.movtimer:Stop()
	self.generalTimer:Stop()
	maps[self.mapid] = nil
	mapidx:Release(self.mapid)
	if self.logic then
		self.logic.recycle = nil
		self.logic = nil
	end
	self.Release = nil

end

function map:process_mov()
	local stops = {}
	for k,v in pairs(self.movingavatar) do		
		if not v:process_mov() then
			self.movingavatar[k] = nil
		end
	end
end

local function GetPlayerById(id)
	local m = GetMapById(id) 
	if m then
		return m:GetAvatar(id)
	else
		return nil
	end	
end

--注册RPC服务
local function RegRpcService(app)
	app:RPCService("EnterMap",function (sock,mapid,type,plys)
		local m = nil
		local status,ret = pcall(function ()
			local plyids
			if mapid == 0 then
				mapid = mapidx:Get()
				if not mapid then
					log_gameserver:Log(CLog.LOG_INFO,"EnterMap reach max map count")
					return {false,"game busy"}
				end
				m = map:new(mapid,type)
			else
				m = maps[mapid] 
				if not m then
					log_gameserver:Log(CLog.LOG_INFO,string.format("EnterMap invaild mapid:%d",mapid))
					return {false,"invaild mapid"}				
				end
			end
			plyids = m.logic:entermap(plys)
			if not plyids and mapid == 0 then
				m:Release()
				log_gameserver:Log(CLog.LOG_INFO,string.format("EnterMap failed maptype:%d",type))
				return {false,"enter failed"}
			end
			return {true,mapid,plyids}
		end)
		if status then
			return ret
		else
			if m then
				m:Release()
			end
			log_gameserver:Log(CLog.LOG_ERROR,string.format("EnterMap error %s",ret))
			return {false,ret}
		end		 			
	end)
	
	app:RPCService("LeaveMap",function (sock,id)
		local m = GetMapById(id)
		if m then 
			return m.logic:leavemap(id)
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
		Gate.UnBind(ply)
		if ply.map and ply.map.logic and ply.map.logic.OnClientDisconnect then
			ply.map.logic:OnClientDisconnect(ply) 
		end
	end
end)


return {
	RegRpcService = RegRpcService,
}		
