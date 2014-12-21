MgrSkill = MgrSkill or {}
MgrSkill.EquipedSkill = MgrSkill.EquipedSkill or {1110, 1120, 1130, 1140, 1150}
MgrSkill.BaseSkill = MgrSkill.BaseSKill or {1511}

MgrSkill.SkillCD = MgrSkill.SkillCD or {} 

function MgrSkill.SetCD()
	
end

function MgrSkill.CanUseSkill(skillID)
	if MgrSkill.IsSkillInCD(skillID) then
		return false
	end

	local skillInfo = TableSkill[skillID]
	if skillInfo.Attack_Types == 0 then	--单体类型
		if MgrFight.lockTarget then
			if MgrFight.lockTarget.attr.life <= 0 then
				return false
			end
		else
			return false
		end
	end
	
	return true
end

function MgrSkill.UseSkill(skillID, selfPos, selfDir, targets)
	if MgrSkill.CanUseSkill(skillID) then
		local curtime = os.clock() * 1000
		
		local num = skillID % 10
		local realSkillID = skillID - num
		if num ~= 0 then
			realSkillID = realSkillID + 1
		end
		local skillInfo = TableSkill[skillID]

		for key, value in pairs(MgrSkill.SkillCD) do
			value.lastTime = curtime
			value.CDTime = skillInfo.Public_CD
		end
		local skillCD = MgrSkill.SkillCD[realSkillID] or {}
		skillCD.lastTime = curtime
		skillCD.CDTime = skillInfo.Skill_CD
		MgrSkill.SkillCD[realSkillID] = skillCD

		local function atkEnd()
            MgrPlayer[maincha.id].playSkillAction = 0
            MgrPlayer[maincha.id]:DelayIdle(0.1)
		end

		if skillID == 1120 then
			CMD_USESKILL_DIR(skillID, selfDir, targets)
		elseif skillInfo.Attack_Types == 3 then --target self
			CMD_USESKILL(skillID, maincha.id)
		elseif skillInfo.Attack_Types == 0 then	--target other
			MgrPlayer[maincha.id]:AttackPlayer(skillID, atkEnd, nil)
            MgrPlayer[maincha.id].playSkillAction = skillID
			CMD_USESKILL_POINT(skillID, selfPos.x, selfPos.y, nil)
		elseif skillInfo.Attack_Types == 1 then	--AOE
			MgrPlayer[maincha.id]:AttackPlayer(skillID, atkEnd, nil)
            MgrPlayer[maincha.id].playSkillAction = skillID
			CMD_USESKILL_POINT(skillID, selfPos.x, selfPos.y, targets)
		elseif skillInfo.Attack_Types == 2 then	--dir
            MgrPlayer[maincha.id].playSkillAction = skillID
			MgrPlayer[maincha.id]:AttackPlayer(skillID, atkEnd, nil)
			CMD_USESKILL_DIR(skillID, selfDir, targets)
		end
		print("Use skill:"..skillID)
		return true
	end
	return false
end

function MgrSkill.IsSkillInCD(skillID)
	local num = skillID % 10
	local realSkillID = skillID - num
	if num ~= 0 then
		realSkillID = realSkillID + 1
	end

	local skillCD = MgrSkill.SkillCD[realSkillID]
	if skillCD then
		local curtime = os.clock() * 1000
		local cdEndTime = skillCD.lastTime + skillCD.CDTime

		if curtime < cdEndTime then
			return true
		end
	end

	return false
end

function MgrSkill.HasSkillInCD()
	local curtime = os.clock() * 1000
	for key, value in pairs(MgrSkill.SkillCD) do
		local cdEndTime = value.lastTime + value.CDTime

		if curtime < cdEndTime then
			return true
		end
	end

	return false
end