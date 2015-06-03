local Cjson = require "cjson"
require "common.TableSkill"
require "common.TableSkill_Addition"

local NetCmd = require "netcmd.netcmd"
local Util = require "gameserver.util"
local Aoi = require "aoi"
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
			local id = v[1]
			local lev = v[2]
			self.skills[id] = {id=id,lev=lev,nexttime = C.GetSysTick(),tb = TableSkill[id]}
		end
	end
	self.next_aval_tick = C.GetSysTick()
	return self
end

local function notify_atk_success(avatar,skillid,atk_type,dir,point)
	local wpk = CPacket.NewWPacket(64)
	wpk:Write_uint16(NetCmd.CMD_SC_NOTIATK)
	wpk:Write_uint32(avatar.id)	
	wpk:Write_uint16(skillid)	
	wpk:Write_uint8(atk_type)
	if atk_type == 1 then
		wpk:Write_uint16(point[1])
		wpk:Write_uint16(point[2])
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

local function notify_atksuffer(atker,sufferer,skillid,miss,crit,damage,timetick)
	local wpk = CPacket.NewWPacket(64)
	wpk:Write_uint16(NetCmd.CMD_SC_NOTIATKSUFFER)
	wpk:Write_uint32(timetick or 0)
	wpk:Write_uint32(atker.id)
	wpk:Write_uint16(skillid)
	wpk:Write_uint32(sufferer.id)
	wpk:Write_uint32(damage)
	if miss then
		wpk:Write_uint8(1)
	elseif crit then
		wpk:Write_uint8(2)
	else
		wpk:Write_uint8(0)
	end	
	sufferer:Send2view(wpk)
end

local function notify_suffer(atker,skillid,sufferer,miss,crit,damage,pos,timetick)
	local wpk = CPacket.NewWPacket(64)
	wpk:Write_uint16(NetCmd.CMD_SC_NOTISUFFER)
	wpk:Write_uint32(timetick or 0)	
	wpk:Write_uint32(atker.id)
	wpk:Write_uint16(skillid or 0)
	wpk:Write_uint32(sufferer.id)
	wpk:Write_uint32(damage)
	if miss then
		wpk:Write_uint8(1)
	elseif crit then
		wpk:Write_uint8(2)
	else
		wpk:Write_uint8(0)
	end	
	if pos then
		wpk:Write_uint8(1)
		wpk:Write_uint16(pos[1])
		wpk:Write_uint16(pos[2])
	else
		wpk:Write_uint8(0)
	end
	sufferer:Send2view(wpk)
end

--计算伤害
--return miss,crit,damage
local function CalDamage(atker,sufferer,skill)
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
--return miss,crit,damage
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

function skill1060(skill,atker,sufferers,dir,point,timetick)
	--print("skill1060")
	local wpk = CPacket.NewWPacket(64)
	wpk:Write_uint16(NetCmd.CMD_SC_NOTIATKSUFFER2)
	wpk:Write_uint32(timetick or 0)		
	wpk:Write_uint32(atker.id)
	wpk:Write_uint16(skill.id)
	wpk:Write_uint16(0)
	wpk:Write_uint16(0)	
	local last_suffer = nil
	if #sufferers == 0 or #sufferers ~= 3 then
		wpk:Write_uint8(0)
		atker:Send2Client(wpk)
		return
	else
		wpk:Write_uint8(3)
		for i=1,#sufferers do
			local suffer = sufferers[i]
			wpk:Write_uint32(suffer.id)
			local miss,crit,damage = process_hp_change(atker,suffer,skill)			
			wpk:Write_uint32(0-damage)			
			if miss then
				wpk:Write_uint8(1)
			elseif crit then
				wpk:Write_uint8(2)
			else
				wpk:Write_uint8(0)
			end
			wpk:Write_uint16(suffer.pos[1])
			wpk:Write_uint16(suffer.pos[2])
		end
		last_suffer = sufferers[3]
	end
	atker:Send2view(wpk)
	if last_suffer then
		atker.pos = {last_suffer.pos[1],last_suffer.pos[2]}
		Aoi.moveto(atker.aoi_obj,atker.pos[1],atker.pos[2])  
	end	
end

function skill1120(skill,atker,sufferers,dir,point,timetick)
	local wpk = CPacket.NewWPacket(64)
	wpk:Write_uint16(NetCmd.CMD_SC_NOTIATKSUFFER2)
	wpk:Write_uint32(timetick or 0)		
	wpk:Write_uint32(atker.id)
	wpk:Write_uint16(skill.id)
	local atk_pos_change
	local suffer = sufferers[1]
	if suffer then
		local distance = Util.Distance(atker.pos,suffer.pos)
		if distance > Util.Pixel2Grid(500) then
			local atker_pos = Util.ForwardTo(atker.map,atker.pos,suffer.pos,200 )
			if atker_pos then 
				atker.pos = {atker_pos[1],atker_pos[2]} 
				atk_pos_change = true
			end
			wpk:Write_uint16(atker.pos[1])
			wpk:Write_uint16(atker.pos[2])
			wpk:Write_uint8(0)		
		else
			local suffer_pos = Util.ForwardTo(atker.map,atker.pos,suffer.pos,Util.Grid2Pixel(distance) +100)
			if suffer_pos then 
				atk_pos_change = true
				atker.pos = {suffer.pos[1],suffer.pos[2]} 
				suffer.pos = {suffer_pos[1],suffer_pos[2]}
				Aoi.moveto(suffer.aoi_obj,suffer.pos[1],suffer.pos[2])  	
			end	
			wpk:Write_uint16(atker.pos[1])
			wpk:Write_uint16(atker.pos[2])			
			wpk:Write_uint8(1)
			wpk:Write_uint32(suffer.id)
			local miss,crit,damage = process_hp_change(atker,suffer,skill)			
			wpk:Write_uint32(0-damage)
			if miss then
				wpk:Write_uint8(1)
			elseif crit then
				wpk:Write_uint8(2)
			else
				wpk:Write_uint8(0)
			end						
			wpk:Write_uint16(suffer.pos[1])
			wpk:Write_uint16(suffer.pos[2])
			suffer:StopMov()
		end
	else
		local atker_pos = Util.DirTo(atker.map,atker.pos,200,dir)
		if atker_pos then 
			atk_pos_change = true
			atker.pos = {atker_pos[1],atker_pos[2]} 
		end
		wpk:Write_uint16(atker.pos[1])
		wpk:Write_uint16(atker.pos[2])
		wpk:Write_uint8(0)		
	end
	atker:StopMov()
	atker:Send2view(wpk)
	Aoi.moveto(atker.aoi_obj,atker.pos[1],atker.pos[2]) 	
end

local function UseSkill(avatar,skill,byAi,param)
	if not avatar.canUseSkill then
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
		return false
	end
	--print("UseSkill1",skill.id)
	local single_target = atk_type == 0 or atk_type == 3
	if not byAi then -- from client
		local rpk = param[1]
		timetick = rpk:Read_uint32()
		if single_target then --single
			local target = rpk:Read_uint32()
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
				point[1] = rpk:Read_uint16()
				point[2] = rpk:Read_uint16()
			elseif atk_type == 2 then
				dir = rpk:Read_uint16()
			else
				--notify_atk_failed(avatar,skill.id)
				return false
			end
			--fetch all targets
			local size = rpk:Read_uint8()
			--print(size)		
			for i = 1,size do
				local target = rpk:Read_uint32()
				target = avatar.map:GetAvatar(target)
				if target and target.teamid ~= avatar.teamid and not target:isDead() then
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
		elseif atk_type == 1 then
			point = param[1]
			targets = param[2]
		else
			return false
		end
	end
	local suffer_function = skill.tb["Suffer_Script"]
	if suffer_function then
		suffer_function = _G[suffer_function]
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
					--print("Repel_Range",skill.id,Repel_Range)
					pos = Util.ForwardTo(avatar.map,avatar.pos,v.pos,Repel_Range)
					if pos then
						v.pos = pos
						--print(pos[1],pos[2])
						Aoi.moveto(v.aoi_obj,v.pos[1],v.pos[2]) 
					end
				end
				notify_suffer(avatar,skill.id,v,miss,cirt,0-damage,pos,timetick)
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
	skill.nexttime = C.GetSysTick() + skill.tb["Skill_CD"]
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
	local id = rpk:Read_uint16()
	local skill = self.skills[id]	
	if not skill then
		skill = {id=id,lev=1,nexttime = C.GetSysTick(),tb = TableSkill[id]}
		self.skills[id] = skill
	end
	local Check_Buff = skill.tb["Check_Buff"]
	if Check_Buff and Check_Buff == 0 and self.next_aval_tick > C.GetSysTick() then
		return false
	end
	if not UseSkill(avatar,skill,false,{rpk}) then
		notify_atk_failed(avatar,id)	
		return false
	else
		--update next_aval_tick
		self.next_aval_tick = C.GetSysTick() + skill.tb["Public_CD"]
	end	
	return true
end

--skill request by ai
function skillmgr:UseSkillAi(avatar,skill,param)	
	if not skill then
		return false
	end
	local Check_Buff = skill.tb["Check_Buff"]
	if Check_Buff and Check_Buff == 0 and self.next_aval_tick > C.GetSysTick() then
		return false
	end	
	if not UseSkill(avatar,skill,true,param) then
		return false
	else
		self.next_aval_tick = C.GetSysTick() + skill.tb["Public_CD"]
		return true
	end
end

function skillmgr:GetAvailableSkill()
	local tick = C.GetSysTick()
	if self.next_aval_tick > tick then
		return nil
	end
	for k,v in pairs(self.skills) do
		local check_buf =  v.tb["Check_Buff"] 
		if not check_buf or check_buf == 0 and tick >= v.nexttime then
			return v
		end
	end
	return nil
end

function skillmgr:GetSkill(id)
	return self.skills[id]
end

return {
	New = function (skills) return skillmgr:new():Init(skills) end,
}
