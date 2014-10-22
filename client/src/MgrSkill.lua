MgrSkill = MgrSkill or {}
MgrSkill.EquipedSkill = MgrSkill.EquipedSkill or {1010, 1020, 1030, 1040}

MgrSkill.SkillCD = MgrSkill.SkillCD or {} 

function MgrSkill.SetCD()
	
end

function MgrSkill.CanUseSkill(skillID)
	print("test can use skillID:"..skillID)
	if MgrSkill.IsSkillInCD(skillID) then
		print("skill in cd")
		return false
	end

	local skillInfo = TableSkill[skillID]
	print(skillInfo)
	print(skillInfo.Attack_Types)
	if skillInfo.Attack_Types == 0 then	--单体类型
		if MgrFight.lockTarget then
			if MgrFight.lockTarget.attr.life <= 0 then
				return false
			end
		else
			return false
		end
	end
	print("can use skill:"..skillID)
	return true
end

function MgrSkill.UseSkill(skillID)
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
		end

		if (not skillInfo.Touch_Buff) or skillInfo.Touch_Buff == 0 then
			MgrPlayer[maincha.id]:AttackPlayer(skillID, atkEnd, MgrFight.lockTarget)
			CMD_USESKILL(skillID, MgrFight.lockTarget.id)
		else
			CMD_USESKILL(skillID, maincha.id)
		end
		print("Use skill:"..skillID)
	end
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