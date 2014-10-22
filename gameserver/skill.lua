local Cjson = require "cjson"
require "Survive.common.TableSkill"
local NetCmd = require "Survive.netcmd.netcmd"
local Time = require "lua.time"

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

function skillmgr:new()
  local o = {}   
  setmetatable(o, self)
  self.__index = self
  return o
end

function skillmgr:Init(skills)
	--self.skills = Cjson.decode(skills)
	self.skills = {}
	self.next_aval_tick = Time.SysTick()
	self.skills[1030] = {id=1030,lev=1,nexttime = Time.SysTick(),tb = TableSkill[1030]}
	--self.skills[id] = {id=id,lev=1,nexttime = Time.SysTick(),tb = TableSkill[id]}
	return self
end

local function notify_atk_success(avatar,skillid,atk_type,dir,point)
	local wpk = CPacket.NewWPacket(64)
	wpk:Write_uint16(NetCmd.CMD_SC_NOTIATK)
	wpk:Write_uint32(avatar.id)
	wpk:Write_uint16(skillid)
	wpk:Write_uint8(atk_type)
	if atk_type == 1 then
		wpk:Write_uint16(point.x)
		wpk:Write_uint16(point.y)
	elseif atk_type == 2 then
		wpk:Write_uint16(dir)
	end
	avatar:Send2view(wpk)	
end

local function notify_atk_failed(avatar,skillid)
	local wpk = CPacket.NewWPacket(64)
	wpk:Write_uint16(NetCmd.CMD_SC_NOTIATK)
	wpk:Write_uint32(avatar.id)
	wpk:Write_uint16(skillid)
	wpk:Write_uint8(0)
	avatar:Send2Client(wpk)		
end

local function notify_atksuffer(atker,sufferer,skillid,damage,timetick)
	local wpk = CPacket.NewWPacket(64)
	wpk:Write_uint16(NetCmd.CMD_SC_NOTIATKSUFFER)
	wpk:Write_uint32(atker.id)
	wpk:Write_uint16(skillid)
	wpk:Write_uint32(sufferer.id)
	wpk:Write_uint32(damage)
	wpk:Write_uint32(timetick or 0)
	sufferer:Send2view(wpk)
end

local function notify_suffer(sufferer,damage)
	local wpk = CPacket.NewWPacket(64)
	wpk:Write_uint16(NetCmd.CMD_SC_NOTISUFFER)
	wpk:Write_uint32(sufferer.id)
	wpk:Write_uint32(damage)
	sufferer:Send2view(wpk)
end

--计算伤害
local function CalDamage(atker,sufferer,skill)
	--首先判断sufferer是否合法目标
	local atkrate = atker.attr:Get("attack") - sufferer.attr:Get("defencse")
	if atkrate < 0 then
		atkrate = 0
	end
	local damage = skill.tb["Attack_Coefficient"] *atkrate + skill.lev * skill.tb["Grade_Coefficient"]
	if damage < 0 then
		damage = 0
	end 
	return damage
end

local function UseSkill(avatar,skill,byAi,param)
	print("UseSkill")
	if skill.nexttime > Time.SysTick() then
		print("UseSkill1")
		return false
	end
	local targets = {}
	local timetick
	local atk_type = skill.tb["Attack_Types"] 
	local dir
	local point
	local buf = skill.tb["Touch_Buff"]
	local single_target = atk_type == 0 or atk_type == 3
	if not byAi then -- from client
		local rpk = param[1]
		if single_target then --single
			local target = rpk:Read_uint32()
			target = avatar.map:GetAvatar(target)
			if not target then
				--notify_atk_failed(avatar,skill.id)
				return false
			end
			if atk_type == 3 and target ~= avatar then
				--notify_atk_failed(avatar,skill.id)
				return false
			end
			timetick = rpk:Read_uint32()
			table.insert(targets,target)
		else -- aoe and dir
			if atk_type == 1 then
				point = {}
				point.x = rpk:Read_uint16()
				point.y = rpk:Read_uint16()
			elseif atk_type == 2 then
				dir = rpk:Read_uint16()	
			else
				notify_atk_failed(avatar,skill.id)
				return false
			end
			--fetch all targets
			local size = rpk:Read_uint8()
			for i = 1,size do
				local target = rpk:Read_uint32()
				target = avatar.map:GetAvatar(target)
				if target then
					table.insert(targets,target)
				end
			end
		end		
	else  --from ai
		if single_target then --single
			local target = param[1]
			if not target then
				--notify_atk_failed(avatar,skill.id)
				return false
			end
			if atk_type == 3 and target ~= avatar then
				--notify_atk_failed(avatar,skill.id)
				return false
			end
			timetick = 0
			table.insert(targets,target)
		end
	end

	for k,v in pairs(targets) do
		local damage = CalDamage(avatar,v,skill)
		local hp = v.attr:Get("life")
		if damage > hp  then
			damage = hp
		end
		if damage > 0 then
			hp = hp - damage
			v.attr:Set("life",hp)
			v.attr:NotifyUpdate()	
		end
		if single_target then
			notify_atksuffer(avatar,v,skill.id,0-damage,timetick)
		else
			notify_suffer(v,0-damage)
		end
		if buf and buf > 0 then
			avatar.buff:NewBuff(v,buf)
		end
	end
	if not single_target then
		notify_atk_success(avatar,skill.id,atk_type,dir,point)
	end
	skill.nexttime = Time.SysTick() + skill.tb["Skill_CD"]
	return true
end

--skill request by client
function skillmgr:UseSkill(avatar,rpk)
	if self.next_aval_tick > Time.SysTick() then
		return false
	end
	print("skillmgr:UseSkill")
	local id = rpk:Read_uint16()
	print("skillid",id)
	local skill = self.skills[id]	
	if not skill then
		skill = {id=id,lev=1,nexttime = Time.SysTick(),tb = TableSkill[id]}
		self.skills[id] = skill
	end	
	if not UseSkill(avatar,skill,false,{rpk}) then
		notify_atk_failed(avatar,id)	
		return false
	else
		--update next_aval_tick
		self.next_aval_tick = Time.SysTick() + skill.tb["Public_CD"]
	end	
	return true
end

--skill request by ai
function skillmgr:UseSkillAi(avatar,skill,param)
	print("skillmgr:UseSkillAi")
	if self.next_aval_tick > Time.SysTick() then
		return false
	end	
	if not skill then
		return false
	end
	return UseSkill(avatar,skill,true,param)
end

function skillmgr:GetAvailableSkill()
	local tick = Time.SysTick()
	print(self.next_aval_tick,tick)
	if self.next_aval_tick > tick then
		return nil
	end
	for k,v in pairs(self.skills) do
		if  tick >= v.nexttime then
			return v
		end
	end
	return nil
end

return {
	New = function (skills) return skillmgr:new():Init(skills) end,
}
