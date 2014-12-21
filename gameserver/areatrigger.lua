package.cpath = "SurviveServer/?.so"
local Avatar = require "SurviveServer.gameserver.avatar"
local NetCmd = require "SurviveServer.netcmd.netcmd"
local Aoi = require "aoi"

local areaTrigger = Avatar.New()

function areaTrigger:new()
	local o = {}
	setmetatable(o, self)
	self.__index = self
	return o	
end

function areaTrigger:Init(id,map,triggerid)
	self.id = id
	self.map = map
	self.see_radius = 5 --read from table
	self.view_obj = {}
	self.watch_me = {}
	self.hide = true
	self.triggerid = triggerid
	self.aoi_obj = Aoi.create_obj(self)
	Aoi.enter_map(map.aoi,self.aoi_obj,pos[1],pos[2])	
	return self
end

function areaTrigger:Send2Client(wpk)
end

function areaTrigger:Tick(currenttick)
	self.Tick(self.view_obj)
end

function areaTrigger:enter_see(other)
	self.view_obj[other.id] = other
	other.watch_me[self.id] = self
	self:onEnterSee(other)	
end

function areaTrigger:leave_see(other)
	self.view_obj[other.id] = nil
	other.watch_me[self.id] = nil
	self:onLeaveSee(other)
end

return {
	New = return function (id,map,triggerid) return areaTrigger:new():Init(id,map,triggerid) end
}