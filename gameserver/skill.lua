local Cjson = require "cjson"
require "Survive/common/TableSkill"
local NetCmd = require "Survive/netcmd/netcmd"

local skillmgr = {
	skills,
}

--[[
skill = {
	id,
	lev,
	nexttime,   --技能下次可用的时间
	tb,         --技能表信息
}
]]--

function skillmgr:new(o)
  local o = o or {}   
  setmetatable(o, self)
  self.__index = self
  o.skills = {}
  return o
end

function skillmgr:Init(skills)
	self.skills = Cjson.decode(skills)
	return self
end

local function notify_atk_failed(avatar,skillid)
	local wpk = CPacket.NewWPacket(64)
	wpk:Write_uint16(NetCmd.CMD_SC_NOTIATK)
	wpk:Write_uint32(avatar.id)
	wpk:Write_uint16(skillid)
	wpk:Wwrite_uint8(0)
	avatar:Send2Client(wpk)		
end

local function notify_atksuffer(atker,sufferer,skillid,damage,timetick)
	local wpk = CPacket.NewWPacket(64)
	wpk:Write_uint16(wpk,NetCmd.CMD_SC_NOTIATKSUFFER)
	wpk:Write_uint32(atker.id)
	wpk:Write_uint16(skillid)
	wpk:Write_uint32(sufferer.id)
	wpk:Write_uint32(damage)
	wpk:Write_uint32(timetick)
	sufferer:Send2view(wpk)
end

--计算伤害
local function CalSuffer(atker,sufferer,skill)
	--首先判断sufferer是否合法目标
end

local function UseSkill(avatar,skill,rpk)
	local target = rpk:Read_uint32()
	local timetick = rpk:Read_uint32()
	print("UseSkill",target)
	target = avatar.map:GetAvatar(target)
	if not target then
		notify_atk_failed(avatar,skill.id)
	else
	    local hp = target.attr:Get("life")
	    if hp > 1 then
			hp = hp - 1
			notify_atksuffer(avatar,target,skill.id,-1,timetick)
			target.attr:Set("life",hp)
			target.attr:NotifyUpdate()
	    else
			notify_atksuffer(avatar,target,skill.id,0,timetick)	
	    end 
	end	
	
	--[[local target_type = skill.tb["target_type"]
	if target_type == 1 then
		--单体技能
		local target = rpk_read_uint32(rpk)
		target = avatar.map.avatars[target]
		if not target then
			notify_atk_failed(avatar,skill.id)
		end
		CalSuffer(avatar,target,skill)		
	elseif target_type == 2 then
		--方向技能
		local dir = rpk_read_uint8(rpk)
	elseif target_type == 3 then
		--点技能
		local x = rpk_read_uint16(rpk)
		local y = rpk_read_uint16(rpk)
	else
		notify_atk_failed(avatar,skill.id)
	end]]--
end

function skillmgr:UseSkill(avatar,rpk)
	print("skillmgr:UseSkill")
	local id = rpk:Read_uint16()
	print("skillid",id)
	local skill = self.skills[id]	
	if not skill then
		skill = {id=id,lev=1,nexttime = GetSysTick(),tb = TableSkill[id]}
		self.skills[id] = skill
	end	
	if skill then -- and skill.nexttime >= C.systemms() then
		UseSkill(avatar,skill,rpk)		
	else
		notify_atk_failed(avatar,id)	
	end
end

return {
	New = function () return skillmgr:new() end,
}
