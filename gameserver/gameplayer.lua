package.cpath = "./?.so"
local Avatar = require "gameserver.avatar"
local NetCmd = require "netcmd.netcmd"
local Aoi = require "aoi"
local Buff = require "gameserver.buff"
local Attr = require "gameserver.attr"
local Skill = require "gameserver.skill"
local Bag = require "gameserver.battlebag"

--[[
local battleitems = {}


function battleitems:new(items)
	local o = {}   
	setmetatable(o, self)
	self.__index = self
	o.items = {}
	items = items or {}
	for k,v in pairs(items) do
		o.items[v[1] ] = {id=v[2],count=v[3]}
	end
	return o	
end

function battleitems:on_entermap(wpk)
	local wpos = wpk:Get_write_pos()
	wpk:Write_uint8(0)
	local c = 0
	for i=5,10 do
		local item = self.items[i]
		if  item then
			wpk:Write_uint8(i)
			wpk:Write_uint16(item.id)
			wpk:Write_uint16(item.count)
			c = c + 1
		end
	end	
	wpk:Rewrite_uint8(wpos,c)
end
]]--

local player = Avatar.New()

function player:new()
	local o = {}
	setmetatable(o, self)
	self.__index = self
	return o	
end

function player:Init(id,avatid,map,nickname,actname,groupsession,attr,skillmgr,pos,dir,teamid,items)
	self.id = id
	self.map = map
	self.nickname = nickname
	self.actname = actname 
	self.groupsession = groupsession
	self.attr = Attr.New(self,attr)
	self.skillmgr = skillmgr
	self.pos = pos
	self.dir = dir
	self.avatid = avatid
	self.teamid = teamid or bit32.band(id,0x0000FFFF)
	self.avattype = 0
	self.see_radius = 5
	self.view_obj = {}
	self.watch_me = {}
	self.gate = nil
	self.path = nil
	self.speed = 27
	self.aoi_obj = Aoi.create_obj(self)
	self.buff = Buff.New(self)
	self.battleitems = Bag.New():Init(self,items)
	--self.battleitems = battleitems:new(items)
	return self
end

function player:Send2Client(wpk)
	local gatesession = self.gatesession
	if gatesession then
		local wpk1 = CPacket.NewWPacket(256)
		local rpk = CPacket.NewRPacket(wpk)
		wpk1:Write_uint16(rpk:Read_uint16())
		wpk1:Write_wpk(wpk)
		wpk1:Write_uint16(1)
		wpk1:Write_uint32(gatesession.sessionid)
		gatesession.sock:Send(wpk1)
	end	
end

function player:on_entermap()
	local wpk = CPacket.NewWPacket(64)
	wpk:Write_uint16(NetCmd.CMD_SC_ENTERMAP)
	wpk:Write_uint16(self.map.maptype)
	self.attr:on_entermap(wpk)
	self.battleitems:on_entermap(wpk)
	self.map.logic:OnEnterMap(wpk)
	wpk:Write_uint32(self.id)
	local gatesession = self.gatesession
	if gatesession then
		local wpk1 = CPacket.NewWPacket(256)
		local rpk = CPacket.NewRPacket(wpk)
		wpk1:Write_uint16(rpk:Read_uint16())
		wpk1:Write_wpk(wpk)
		wpk1:Write_uint16(1)
		wpk1:Write_uint32(gatesession.sessionid)
		wpk1:Write_uint32(self.id)
		gatesession.sock:Send(wpk1)
	end
	--[[for k,v in pairs(self.attr.attr) do
		print(k,v)
	end]]--			
end

--客户端断线重连处理
function player:ReConnect(maptype)
	if self.robot then
		--stop the robot
		self.robot:Stop()
	end
	self:on_entermap()	
	for k,v in pairs(self.view_obj) do
		self:SendEnterSee(v)
	end
end

return {
	New = function (id,avatid,map,nickname,actname,groupsession,attr,skillmgr,pos,dir,teamid,items) 
			return player:new():Init(id,avatid,map,nickname,actname,groupsession,attr,skillmgr,pos,dir,teamid,items) 
	             end,
} 
