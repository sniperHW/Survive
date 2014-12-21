require "src.table.TableBuff"
require "src.table.TableBuff_Nexus"
local Time = require "src.pseudoserver.time"
local NetCmd = require "src.net.NetCmd"

local buffExclusion = TableBuff_Nexus
local buff = {}

function buff:new()
	local o = {}   
	self.__index = self
	setmetatable(o, self)
	return o
end

function buff:Init(id,owner,releaser,tb)
	self.releaser = releaser -- who release the buff
	self.id = id
	self.owner = owner
	self.tb = tb
	self.interval = tb["Interval"]
	self.onInterval = tb["OnInterval"]
	if self.interval and self.interval > 0 and self.onInterval then
		self.nextInterval =  Time.SysTick() +  self.interval
	end
	self.period1 = tb["Period1"]
	self.period2 = tb["Period2"]
	self.range = tb["Range"]
	self.period = self.period1 + self.period2 -- the total period
	self.endTick = Time.SysTick() + self.period
	self.onBegin = tb["OnBegin"]
	self.onEnd = tb["OnEnd"]
	return self
end

function buff:Reset(releaser)
	self.releaser = releaser
	self.endTick = Time.SysTick() + self.period
end

function buff:NotifyBegin()
	local wpk = GetWPacket()
	WriteUint16(wpk,NetCmd.CMD_SC_BUFFBEGIN)
	WriteUint32(wpk,self.owner.id)
	WriteUint16(wpk,self.id)
	Send2Client(wpk)
end

function buff:NotifyEnd()
	local wpk = GetWPacket()
	WriteUint16(wpk,NetCmd.CMD_SC_BUFFEND)
	WriteUint32(wpk,self.owner.id)
	WriteUint16(wpk,self.id)
	Send2Client(wpk)	
end

--if return false means the buff have end
function buff:Tick(currenttick)
	if self.nextInterval and currenttick >= self.nextInterval then
		local onInterval = self.tb["OnInterval"]
		onInterval(self)
	end	
	if currenttick >= self.endTick then
		print("buff timeout")
		return false
	else
		return true
	end
end

local buffmgr = {}

function buffmgr:new(avatar)
	local o = {}   
	setmetatable(o, self)
	self.__index = self
	o.avatar = avatar
	o.buffs = {}
	return o	
end

local replace     = 1
local exclude    = 2
local interrupt  = 3

function buffmgr:NewBuff(releaser,id)
	local tb = TableBuff[id]
	if not tb then
		return false
	end
	for k,v in pairs(self.buffs) do
		local exclusion	= buffExclusion[id]
		if exclusion then exclusion = exclusion[k] end
		if exclusion == exclude then 
			return false
		elseif exclusion == replace  or id == k then
			if id == k then
				v:Reset(releaser)
				return true
			else
				--remove the old one
				self:RemoveBuff(k)
				break
			end
		elseif  exclusion == interrupt then
			self:RemoveBuff(k)	
		end	
	end
	local buf = buff:new():Init(id,self.avatar,releaser,tb)
	self.buffs[id] = buf
	local onBegin = tb["OnBegin"]
	if onBegin then
		onBegin(buf)	
	end
	buf:NotifyBegin()
	return true
end

function buffmgr:OnAvatarDead()
	for k,v in pairs(self.buffs) do
		onBuffEnd(v)
	end
	self.buffs = {}	
end

local function onBuffEnd(buf)
	local onEnd = buf.tb["OnEnd"]
	if onEnd then onEnd = _G[onEnd] end
	if onEnd then onEnd(buf) end
	buf:NotifyEnd()
end

function buffmgr:RemoveBuff(id)
	local buf = self.buffs[id]
	if not buf then
		return false
	end
	self.buffs[id] = nil
	onBuffEnd(buf)
	return true
end

function buffmgr:Tick(currenttick)
	for k,v in pairs(self.buffs) do
		if not v:Tick(currenttick) then
			onBuffEnd(self.buffs[k])
			self.buffs[k] = nil --remove the buff
		end
	end
end

function buffmgr:HasBuff(buffid)
	if buffid and self.buffs[buffid] then
		return true
	else
		return false
	end
end



local function StopMove(buf)
	local avatar = buf.owner
	if avatar then
		avatar:StopMov()
	end
end

return {
	New = function (avatar)
		return buffmgr:new(avatar) 
	end
}
