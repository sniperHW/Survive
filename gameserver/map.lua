package.cpath = "./?.so"
local Avatar = require "gameserver.avatar"
local Player = require "gameserver.gameplayer"
local LinkQue = require "lua.linkque"
local Cjson = require "cjson"
local Gate = require "gameserver.gate"
local Attr = require "gameserver.attr"
local Skill = require "gameserver.skill"
local Aoi = require "aoi"
local Astar = require "astar"
local Timer = require "lua.timer"
local NetCmd = require "netcmd.netcmd"
local MsgHandler = require "netcmd.msghandler"
local IdMgr = require "common.idmgr"
local Sche = require "lua.sche"
local MapLogic = require "gameserver.maplogic"
local Util = require "gameserver.util"
require "common.TableMap"
require "common.TableItem"
require "common.TableAvatar"

--local mapdef = {
--	[1] = {
		--gridlength = 100,          --管理格大小
		--xcount,
		--ycount,
		--radius = 100,              --视距大小
		--coli   = "./Survive/gameserver/fightMap.meta",   --寻路碰撞文件
		--astar  = nil,
--	},
--}

for k,v in pairs(TableMap) do
	if k ~= 205 then
		v.astar,v.xcount,v.ycount = Astar.create("./gameserver/" .. v.Colision)
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
	local onMapDestroy = 1
	for k,v in pairs(self.avatars) do
		v:Release(onMapDestroy)--release on map destroy
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

g_survive = nil

--注册RPC服务
local function RegRpcService(app)

	app:RPCService("EnterSurvive",function (sock,ply,starttime,grouptime)
		if not g_survive then
			mapid = mapidx:Get()
			if not mapid then
				log_gameserver:Log(CLog.LOG_INFO,"EnterMap reach max map count")
				return {false,0}
			end
			g_survive = map:new(mapid,206)
			local now = os.time()
			g_logic.start_tick = starttime + (now - grouptime)			
		end
		local gameid = g_logic:entermap(ply)
		if not gameid then
			return {false,0}
		else
			return {true,gameid}
		end
	end)

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
		if not ply or ply.gatesession then
			return false
		end
		local gate = Gate.GetGateByName(gatesession.name)
		if not gate then
			print("no gate")
			for k,v in pairs(gatesession) do
				print(k,v)
			end 
			--print("no gate",gatesession.name,gatesession.id)
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

MsgHandler.RegHandler(NetCmd.CMD_CS_PICKUP,function (sock,rpk)
	--print("CMD_CS_PICKUP")
	local id = rpk:Reverse_read_uint32()
	local ply = GetPlayerById(id)
	if ply then
		local objid = rpk:Read_uint32()
		local obj = ply.map:GetAvatar(objid)
		if obj and obj.Pickable then
			local tb = TableAvatar[obj.avatid]
			if not tb then
				return
			end
			local itemid = tb.Item_ID
			
			local itemtb = TableItem[itemid]
			if not itemtb then 
				return 
			end
			if  itemtb["Item_Type"] < 5 then
				--print("pickup weapon")
				ply.weapon = {id=itemid,count=1,attr = {0,0,0,0,0,0,0,0,0,0}}
				local wpk = CPacket.NewWPacket(128)
				wpk:Write_uint16(NetCmd.CMD_SC_UPDATEWEAPON)
				wpk:Write_uint32(ply.id)				
				packWeapon(wpk,ply.weapon)
				ply:Send2view(wpk)
				obj:Release()				
			else
				if ply.battleitems:AddItem(itemid,1) then
					ply.battleitems:NotifyUpdate()
					obj:Release()
				end
			end
		end
	end
end)

local t = Timer.New("runImmediate"):Register(function ()
	if mapidx:Len() ~= 65535 then
		log_gameserver:Log(CLog.LOG_INFO,"-----------------------map info---------------------------")
		for k,v in pairs(maps) do
			local avatarcount = 0
			local aicount = 0
			for k1,v1 in pairs(v.avatars) do
				avatarcount = avatarcount + 1
				if v1.robot and v1.robot.run then
					aicount = aicount + 1
				end
			end
			log_gameserver:Log(CLog.LOG_INFO,string.format("mapid:%d,maptype:%d,plycount:%d,avatar count:%d,ai count:%d",
									    v.mapid,v.maptype,v.logic.plycount,avatarcount,aicount))
		end
	end
end,5000)


return {
	RegRpcService = RegRpcService,
}		
