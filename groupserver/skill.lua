local Cjson = require "cjson"
local Db = require "common.db"
local NetCmd = require "netcmd.netcmd"
local MsgHandler = require "netcmd.msghandler"
local Task = require "groupserver.everydaytask"
require "common.TableSkill"
require "common.Tableskill_Upgrade"

local skills = {}

function skills:new()
  local o = {}   
  setmetatable(o, self)
  self.__index = self
  return o
end

function skills:Init(ply,sks)
	sks = sks or {}
	self.skills =  {}
	for k,v in pairs(sks) do
		self.skills[v[1]] = v[2]
	end
	self.flag = {}
	self.ply = ply
	return self
end

function skills:OnBegPly(wpk)
	local wpos = wpk:Get_write_pos()
	wpk:Write_uint16(0)
	local c = 0	
	for k,v in pairs(self.skills) do
		wpk:Write_uint16(k)
		wpk:Write_uint8(v)
		c = c + 1
	end
	wpk:Rewrite_uint16(wpos,c)	
end

function skills:GetSkills()
	local tmp = {}
	for k,v in pairs(self.skills) do
		table.insert(tmp,{k,v})
	end
	return tmp	
end

function skills:DbStr()
	local tmp = {}
	for k,v in pairs(self.skills) do
		table.insert(tmp,{k,v})
	end
	return Cjson.encode(tmp)
end

function skills:Save()
	local cmd = "hmset chaid:" .. self.ply.chaid .. " skill  " .. self:DbStr()
	Db.CommandAsync(cmd)	
end

function skills:Upgrade(skillid)
	local sklev = self.skills[skillid]
	if sklev then

		sklev = sklev + 1
		local tb = Tableskill_Upgrade[sklev]
		if tb then
			local money = tonumber(tb["Money"])
			if self.ply.attr:Get("shell") >= money then
				self.ply.attr:Sub("shell",money)
				self.ply.attr:Update2Client()
				self.ply.attr:DbSave()
			else
				return false
			end
		end		
		 self.skills[skillid] = sklev
		local wpk = CPacket.NewWPacket(64)
		wpk:Write_uint16(NetCmd.CMD_GC_SKILLUPDATE)
		wpk:Write_uint16(skillid)
		wpk:Write_uint8(sklev)
		self.ply:Send2Client(wpk)	 
		return true
	end
	return false
end

function skills:Unlock(skillid)
	local tb = TableSkill[skillid]
	if tb and not self.skills[skillid] then
		local soul = tb["Soul"]
		if soul and soul > 0 then
			if self.ply.attr:Get("soul") >= soul then
				self.ply.attr:Sub("soul",soul)
				self.ply.attr:Update2Client()
				self.ply.attr:DbSave()
			else
				return false
			end
		end
		self.skills[skillid] = 1
		local wpk = CPacket.NewWPacket(64)
		wpk:Write_uint16(NetCmd.CMD_GC_ADDSKILL)
		wpk:Write_uint16(skillid)
		wpk:Write_uint8(1)
		self.ply:Send2Client(wpk)
		return true
	end
	return false
end

MsgHandler.RegHandler(NetCmd.CMD_CG_UPGRADESKILL,function (sock,rpk)
	print("CMD_CG_UPGRADESKILL")
	local groupsession = rpk:Reverse_read_uint16()
	local ply = GetPlayerBySessionId(groupsession)
	if ply then
		local skillid = rpk:Read_uint16()
		if ply.skills:Upgrade(skillid) then
			ply.skills:Save()
			ply.task:OnEvent(Task.TaskType.SKILLUPGRADE)
		end
	end	
end)

MsgHandler.RegHandler(NetCmd.CMD_CG_UNLOCKSKILL,function (sock,rpk)
	print("CMD_CG_UNLOCKSKILL")
	local groupsession = rpk:Reverse_read_uint16()
	local ply = GetPlayerBySessionId(groupsession)
	if ply then
		local skillid = rpk:Read_uint16()
		if ply.skills:Unlock(skillid) then
			ply.skills:Save()
		end
	end	
end)

return {
	New = function (ply,sks) return skills:new():Init(ply,sks) end
}

