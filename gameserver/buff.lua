require "common.TableBuff"
require "common.TableBuff_Nexus"
local NetCmd = require "netcmd.netcmd"
local BuffFunc = require "gameserver.bufffunction"

local buffExclusion = TableBuff_Nexus
local buff = {}

function buff:new()
	local o = {}   
	self.__index = self
	setmetatable(o, self)
	return o
end

local function GetTabFunction(tb,name)
	return BuffFunc[tb[name]]
end

function buff:Init(id,owner,releaser,tb)
	self.releaser = releaser -- who release the buff
	self.id = id
	self.owner = owner
	self.tb = tb
	self.interval = tb["Interval"] or 0
	self.period1 = tb["Period1"] or 0
	self.period2 = tb["Period2"] or 0
	self.range = tb["Range"]
	self.period = self.period1 + self.period2 -- the total period
	self.endTick = C.GetSysTick() + self.period
	self.onBegin = GetTabFunction(tb,"OnBegin")
	self.onEnd = GetTabFunction(tb,"OnEnd")
	self.onInterval = GetTabFunction(tb,"OnInterval")
	--print("buff",id,self.onInterval,self.interval)
	if self.interval > 0 and self.onInterval then
		self.nextInterval = C.GetSysTick() +  self.interval
		--print(self.interval)
	end	
	return self
end

function buff:Do(event)
	local func = self[event]
	if func then
		local ret,err = pcall(func,self)
		if not ret then
			log_gameserver:Log(CLog.LOG_ERROR,string.format("do buff %d event error:%s",self.id,err))
		end
	end
end

function buff:Reset(releaser)
	self.releaser = releaser
	self.endTick = C.GetSysTick() + self.period
end

function buff:NotifyBegin(o)
	if o and o.gatesession == nil then
		return
	end
	local wpk = CPacket.NewWPacket(64)
	wpk:Write_uint16(NetCmd.CMD_SC_BUFFBEGIN)
	wpk:Write_uint32(self.owner.id)
	wpk:Write_uint16(self.id)
	if o then
		self.owner:Send2Client(wpk)
	else
		self.owner:Send2view(wpk)
	end
end

function buff:NotifyEnd()
	local wpk = CPacket.NewWPacket(64)
	wpk:Write_uint16(NetCmd.CMD_SC_BUFFEND)
	wpk:Write_uint32(self.owner.id)
	wpk:Write_uint16(self.id)
	self.owner:Send2view(wpk)
	self:Do("onEnd")
end

--if return false means the buff have end
function buff:Tick(currenttick)
	if self.nextInterval and currenttick >= self.nextInterval then
		self.nextInterval = C.GetSysTick() +  self.interval
		self:Do("onInterval")
	end	
	if currenttick >= self.endTick then
		return false
	end
	
	if self.buffSkill then
		local robot = self.releaser.robot
		if robot and robot.run then
			if currenttick >=  self.buffSkill[2] then
				robot:UseBuffSkill(self.buffSkill[1])
				self.buffSkill[2] = currenttick + self.buffSkill[3]
			end
		else
			self.buffSkill = nil
		end
	end
	return true
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
	--print("new buff",id)
	self.buffs[id] = buf
	local AtkSkill = tb["AtkSkill"]
	if AtkSkill and AtkSkill > 0 and releaser.robot then
		buf.buffSkill = {AtkSkill,C.GetSysTick()+100,500}
	end
	buf:NotifyBegin()
	buf:Do("onBegin")	
	return true
end

function buffmgr:OnAvatarDead()
	for k,v in pairs(self.buffs) do
		v:NotifyEnd()
	end
	self.buffs = {}	
end

function buffmgr:RemoveBuff(id)
	local buf = self.buffs[id]
	if not buf then
		return false
	end
	self.buffs[id] = nil
	buf:NotifyEnd()
	return true
end

function buffmgr:Tick(currenttick)
	for k,v in pairs(self.buffs) do
		if not v:Tick(currenttick) then
			v:NotifyEnd()
			self.buffs[k] = nil --remove the buff
		end
	end
end

function buffmgr:OnEnterSee(o)
	for k,v in pairs(self.buffs) do
		v:NotifyBegin(o)
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
