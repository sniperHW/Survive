package.cpath = "./?.so"
local Avatar = require "gameserver.avatar"
local NetCmd = require "netcmd.netcmd"
local Aoi = require "aoi"
local Util = require "gameserver.util"
local TriggerFunc = require "gameserver.triggerfunction"
local Timer = require "lua.timer"
require "common.TableTrigger"

local areaTrigger = Avatar.New()

local function GetTabFunction(tb,name)
	--print(tb["TransferPoint"])
	return TriggerFunc[tb[name]]
end

function areaTrigger:new()
	local o = {}
	setmetatable(o, self)
	self.__index = self
	return o	
end

local triggers = {}

local TriggerTimer= Timer.New("runImmediate"):Register(function ()
			for k,v in pairs(triggers) do
				v:RangeCheck()
			end
		    end,50)

function areaTrigger:Init(id,map,triggerid,pos)
	self.id = id
	self.map = map
	self.view_obj = {}
	self.watch_me = {}
	self.pos = pos
	self.triggerid = triggerid
	self.isTrigger = true
	local tb = TableTrigger[triggerid]
	if not tb then
		return nil
	else
		map.avatars[id] = self
		triggers[id] = self
		self.hide = tb.Hide
		self.avatid = tb.AvatID 
		self.tb = tb
		self.range = tonumber(tb.Range)
		self.OnEnterRange = GetTabFunction(tb,"OnEnterRange")
		self.OnLeaveRange = GetTabFunction(tb,"OnLeaveRange")
		self.aoi_obj = Aoi.create_obj(self)
		self.obj_range = {}
		--print("Aoi.enter_map",pos[1],pos[2])
		Aoi.enter_map(map.aoi,self.aoi_obj,pos[1],pos[2])
	end	
	return self
end

function areaTrigger:PackEnterSee(wpk)
	wpk:Write_uint32(self.id)
	wpk:Write_uint8(0)
	wpk:Write_uint16(self.avatid)
	wpk:Write_string("")
	wpk:Write_uint16(0)
	wpk:Write_uint16(self.pos[1])
	wpk:Write_uint16(self.pos[2])
	wpk:Write_uint16(0)
	wpk:Write_uint8(0)
	wpk:Write_uint16(0)
	wpk:Write_uint16(0)
end


function areaTrigger:Send2Client(wpk)
end

function areaTrigger:onRelease()
	triggers[self.id] = nil
end

function areaTrigger:RangeCheck()
	local enterRange = {}
	local leaveRange = {}
	for k,v in pairs(self.view_obj) do
		if Util.TooClose(self.pos,v.pos,self.range/2) then
			if not self.obj_range[v.id] then
				table.insert(enterRange,v)
			end	
		else
			if self.obj_range[v.id] then
				table.insert(leaveRange,v)
			end			
		end
	end
	for k,v in pairs(enterRange) do
		self:EnterRange(v)
	end
	for k,v in pairs(leaveRange) do
		self:LeaveRange(v)
	end		
end

function areaTrigger:Tick(currenttick)
	--if self.disable then
	--	Aoi.destroy_obj(self.aoi_obj,0)
	--	self.aoi_obj = nil
	--	return	
	--end
end

function areaTrigger:DoCallBack(f,o)
	local func = self[f]
	if func then
		local ret,err = pcall(func,self,o)
		if not ret then
			log_gameserver:Log(CLog.LOG_ERROR,string.format("areaTrigger:DoCallBack error:%s",err))
		end
	end
end

--function areaTrigger:Disable()
--	self.disable = true
--end

function areaTrigger:EnterRange(o)
	self.obj_range[o.id] = o
	self:DoCallBack("OnEnterRange",o)
end

function areaTrigger:LeaveRange(o)
	self.obj_range[o.id] = nil
	self:DoCallBack("OnLeaveRange",o)
end

function areaTrigger:enter_see(other)
	if other.id ~= self.id and not other.isTrigger then
		self.view_obj[other.id] = other
	end	
end

function areaTrigger:leave_see(other)
	if other.id ~= self.id and not other.isTrigger then
		self.view_obj[other.id] = nil
		self.obj_range[other.id] = nil
	end
end

return {
	New =  function (id,map,triggerid,pos) return areaTrigger:new():Init(id,map,triggerid,pos) end
}