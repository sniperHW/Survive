require "src.table.TableSkill"
require "src.table.TableSkill_Addition"
local Time = require "src.pseudoserver.time"
local Util = require "src.pseudoserver.util"
local NetCmd = require "src.net.NetCmd"

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
	self.skills = {}
	if skills then
		for k,v in pairs(skills) do
			self.skills[v] = {
				id=v,
				lev=1,
				nexttime = Time.SysTick(),
				tb = TableSkill[v],
				Attack_Distance = TableSkill[v]["Attack_Distance"]
			}
		end
	end
	self.next_aval_tick = Time.SysTick()
	return self
end

local function notify_atk_success(avatar,skillid,atk_type,dir,point)
	local wpk = GetWPacket()
	WriteUint16(wpk,NetCmd.CMD_SC_NOTIATK)
	WriteUint32(wpk,avatar.id)
	WriteUint16(wpk,skillid)
	WriteUint8(wpk,atk_type)
	if atk_type == 1 then
		WriteUint16(wpk,point.x)
		WriteUint16(wpk,point.y)
	elseif atk_type == 2 then
		WriteUint16(wpk,dir)
	end
	Send2Client(wpk)	
end

local function notify_atk_failed(avatar,skillid)
	local wpk = GetWPacket()
	WriteUint16(wpk,NetCmd.CMD_SC_NOTIATK)
	WriteUint32(wpk,avatar.id)
	WriteUint16(wpk,skillid)
	WriteUint8(wpk,0)
	Send2Client(wpk)		
end

local function notify_atksuffer(atker,sufferer,skillid,miss,crit,damage,timetick)
	local wpk = GetWPacket()
	WriteUint16(wpk,NetCmd.CMD_SC_NOTIATKSUFFER)
	WriteUint32(wpk,timetick or 0)		
	WriteUint32(wpk,atker.id)
	WriteUint16(wpk,skillid)
	WriteUint32(wpk,sufferer.id)
	WriteUint32(wpk,damage)
	if miss then
		WriteUint32(wpk,1)
	elseif crit then
		WriteUint32(wpk,2)
	else
		WriteUint32(wpk,0)
	end	
	WriteUint32(wpk,timetick or 0)
	Send2Client(wpk)
end

local function notify_suffer(atker,skillid,sufferer,miss,crit,damage,pos)
	local wpk = GetWPacket()
	WriteUint16(wpk,NetCmd.CMD_SC_NOTISUFFER)
	WriteUint32(wpk,timetick or 0)
	WriteUint32(wpk,atker.id)
	WriteUint16(wpk,skillid)			
	WriteUint32(wpk,sufferer.id)
	WriteUint32(wpk,damage)
	if miss then
		WriteUint32(wpk,1)
	elseif crit then
		WriteUint32(wpk,2)
	else
		WriteUint32(wpk,0)
	end	
	if pos then
		WriteUint8(wpk,1)
		WriteUint16(wpk,pos[1])
		WriteUint16(wpk,pos[2])
	else
		WriteUint8(wpk,0)
	end
	Send2Client(wpk)
end

--计算伤害
local function CalDamage(atker,sufferer,skill)
	--首先判断sufferer是否合法目标
	local category = skill.tb["Category"] 
	if not category or category == 0 then 
		return nil,nil,0 
	end
	local crit,miss
	local atkrate = atker.attr:Get("attack") - sufferer.attr:Get("defencse")
	if atkrate < 0 then
		atkrate = 0
	end
	local damage = math.floor((skill.tb["Attack_Coefficient"] *atkrate)/1000 + skill.lev * skill.tb["Grade_Coefficient"])
	if atker ~= sufferer and damage <= 0 then
		damage = 10
	end

	if atker ~= sufferer and atker.attr:Get("agile") > math.random(1,1000) then
		miss = true
		return miss,crit,0
	end
	local suffer_plusrate =  atker.attr:Get("suffer_plusrate")
	if suffer_plusrate == 0 then
		suffer_plusrate = 1
	end
	if atker ~= sufferer and atker.attr:Get("crit") > math.random(1,1000) then
		suffer_plusrate = suffer_plusrate + 1.5
		crit = true
	end
	local tb = TableSkill_Addition[skill.lev]
	if tb then
		local v = tb[skill.id]
		if v then
			suffer_plusrate = suffer_plusrate + v 
		end
	end	
	return miss,crit,math.floor(damage*suffer_plusrate)
end

local function process_hp_change(atker,suffer,skill)
	local miss,crit,damage = CalDamage(atker,suffer,skill)
	local hp = suffer.attr:Get("life")
	if damage > hp  then
		damage = hp
	end
	if damage > 0 then
		hp = hp - damage
		suffer.attr:Set("life",hp)
		if hp == 0 then
			suffer:OnDead(atker,skill.id)
		end
		suffer.attr:NotifyUpdate()
		suffer.buff:RemoveBuff(3002)
	end
	return miss,crit,damage
end

function skill1120(skill,atker,sufferers,dir,point,timetick)
	local wpk = GetWPacket()
	WriteUint16(wpk,NetCmd.CMD_SC_NOTIATKSUFFER2)
	WriteUint32(wpk,timetick or 0)	
	WriteUint32(wpk,atker.id)
	WriteUint16(wpk,skill.id)
	local suffer = sufferers[1]
	if suffer then
		local distance = Util.Distance(atker.pos,suffer.pos)
		if distance > Util.Pixel2Grid(500) then
			local atker_pos = Util.ForwardTo(atker.map,atker.pos,suffer.pos,200 )
			if atker_pos then
				atker.pos = {atker_pos[1],atker_pos[2]}
			end
			WriteUint16(wpk,atker.pos[1])
			WriteUint16(wpk,atker.pos[2])
			WriteUint8(wpk,0)		
		else
			local suffer_pos = Util.ForwardTo(atker.map,atker.pos,suffer.pos,Util.Grid2Pixel(distance) +100)
			if suffer_pos then
				atker.pos = {suffer.pos[1],suffer.pos[2]}	
			end
			WriteUint16(wpk,atker.pos[1])
			WriteUint16(wpk,atker.pos[2])			
			WriteUint8(wpk,1)
			WriteUint32(wpk,suffer.id)
			local miss,crit,damage = process_hp_change(atker,suffer,skill)
			if suffer_pos then		
				suffer.pos = {suffer_pos[1],suffer_pos[2]}		
			end
			WriteUint32(wpk,0-damage)	
			if miss then
				WriteUint32(wpk,1)
			elseif crit then
				WriteUint32(wpk,2)
			else
				WriteUint32(wpk,0)
			end						
			WriteUint16(wpk,suffer.pos[1])
			WriteUint16(wpk,suffer.pos[2])
			suffer:StopMov()
		end
	else
		local atker_pos = Util.DirTo(atker.map,atker.pos,200,dir)
		if atker_pos then
			atker.pos = {atker_pos[1],atker_pos[2]}
		end
		WriteUint16(wpk,atker.pos[1])
		WriteUint16(wpk,atker.pos[2])
		WriteUint8(wpk,0)		
	end
	atker:StopMov()
	Send2Client(wpk)
	--atker:Send2view(wpk)	
end

local function UseSkill(avatar,skill,byAi,param)
	if skill.nexttime > Time.SysTick() then
		return false
	end
	local targets = {}
	local timetick = 0
	local atk_type = skill.tb["Attack_Types"]
	local break_move = skill.tb["Break_Move"] 
	local dir
	local point
	local buf = skill.tb["Touch_Buff"]
	local check_buf = skill.tb["Check_Buff"]
	if check_buf and check_buf > 0 and not avatar.buff:HasBuff(check_buf) then
		print("no buf")
		return false
	end
	local single_target = atk_type == 0 or atk_type == 3
	if not byAi then -- from client
		local rpk = param[1]
		timetick = ReadUint32(rpk)		
		if single_target then --single
			local target = ReadUint32(rpk)
			target = avatar.map:GetAvatar(target)
			if not target or target:isDead() then
				return false
			end
			if atk_type == 3 and target ~= avatar then
				return false
			end
			table.insert(targets,target)
		else -- aoe and dir
			if atk_type == 1 then
				point = {}
				point.x = ReadUint16(rpk)
				point.y = ReadUint16(rpk)
			elseif atk_type == 2 then
				dir = ReadUint16(rpk)	
			else
				--notify_atk_failed(avatar,skill.id)
				return false
			end
			--fetch all targets
			local size = ReadUint8(rpk)
			for i = 1,size do
				local target = ReadUint32(rpk)
				target = avatar.map:GetAvatar(target)
				if target and not target:isDead() then
					table.insert(targets,target)
				end
			end
		end		
	else  --from ai
		if single_target then --single
			local target = param[1]
			if not target and target:isDead() then
				return false
			end
			if atk_type == 3 and target ~= avatar then
				return false
			end
			timetick = 0
			table.insert(targets,target)
		elseif atk_type == 2 then
			dir = param[1]
			targets = param[2]
		else
			return false
		end
	end

	local suffer_function = skill.tb["Suffer_Script"]
	if suffer_function then
		--print(suffer_function)
		suffer_function = _G[suffer_function]
		--print(suffer_function)
	end
	if not suffer_function then
		for k,v in pairs(targets) do
			local miss,crit,damage = process_hp_change(avatar,v,skill)
			if single_target then
				notify_atksuffer(avatar,v,skill.id,miss,crit,0-damage,timetick)
			else
				local Repel_Range = skill.tb["Repel_Range"]
				local pos
				if Repel_Range and Repel_Range > 0 then
					v:StopMov()
					pos = Util.ForwardTo(avatar.map,avatar.pos,v.pos,Repel_Range)
					if pos then
						v.pos = pos
					end
				end
				notify_suffer(avatar,skill.id,v,miss,crit,0-damage,pos,timetick)
			end
			if buf and buf > 0 then
				v.buff:NewBuff(v,buf)
			end
		end
		if not single_target then
			notify_atk_success(avatar,skill.id,atk_type,dir,point)
		end
	else
		suffer_function(skill,avatar,targets,dir,point,timetick)
	end
	skill.nexttime = Time.SysTick() + skill.tb["Skill_CD"]
	if break_move and break_move > 0 then
		avatar:StopMov()
	end
	if skill.tb["Category"] == 2 then
		avatar.buff:RemoveBuff(3002)
	end
	return true
end

--skill request by client
function skillmgr:UseSkill(avatar,rpk)
	local id = ReadUint16(rpk)
	local skill = self.skills[id]	
	if not skill then
		skill = {id=id,lev=1,nexttime = Time.SysTick(),tb = TableSkill[id]}
		self.skills[id] = skill
	end

	local Check_Buff = skill.tb["Check_Buff"]
	if Check_Buff and Check_Buff == 0 and self.next_aval_tick > Time.SysTick() then
		return false
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
	if not skill then
		return false
	end
	local Check_Buff = skill.tb["Check_Buff"]
	if Check_Buff and Check_Buff == 0 and self.next_aval_tick > Time.SysTick() then
		return false
	end	
	return UseSkill(avatar,skill,true,param)
end

function skillmgr:GetAvailableSkill()
	local tick = Time.SysTick()
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
