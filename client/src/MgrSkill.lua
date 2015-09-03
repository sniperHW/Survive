MgrSkill = MgrSkill or {}
MgrSkill.EquipedSkill = MgrSkill.EquipedSkill or {1110, 1120, 1130, 1140, 1150}
MgrSkill.BaseSkill = MgrSkill.BaseSKill or {1511}
MgrSkill.SkillCD = MgrSkill.SkillCD or {} 

function MgrSkill.SetCD()
	
end

function MgrSkill.CanUseSkill(skillID)
    local localPlayer = MgrPlayer[maincha.id]
    if localPlayer.buffState[3101] or not MgrFight.CanUseSkill then
        return false
    end
    
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
	
    --[[if TableSkill[skillID].Energy then
        return MgrFight.anger >= TableSkill[skillID].Energy
	end]]--
	
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
            if value then
                local lastEndTime = value.lastTime + value.CDTime                
                local curEndTime = curtime + skillInfo.Public_CD
                
                if lastEndTime < curEndTime then
                    value.lastTime = curtime 
                    value.CDTime = skillInfo.Public_CD
                end
            end
		end
		
		if num ~= 0 then
    		local skillCD = MgrSkill.SkillCD[realSkillID] or {}
    		skillCD.lastTime = curtime
    		skillCD.CDTime = skillInfo.Skill_CD
    		MgrSkill.SkillCD[realSkillID] = skillCD
        end
        
		local function atkEnd()
            MgrPlayer[maincha.id].playSkillAction = 0
            MgrPlayer[maincha.id]:DelayIdle(0.1)
		end
        if skillID == 1060 then
            local localPlayer = MgrPlayer[maincha.id]
            local selfPosX, selfPosY = localPlayer:getPosition()
            local targets = {}
            for id, value in pairs(MgrPlayer) do
                if value and value.teamid ~= localPlayer.teamid 
                    and value.attr.life > 0 then
                    local tarPosX, tarPosY = value:getPosition()
                    local dis = cc.pGetDistance(cc.p(selfPosX, selfPosY), cc.p(tarPosX, tarPosY))
                    print("distanse:"..dis)
                    if dis < 500 then
                        table.insert(targets, value.id)
                    end                            
                end
            end

            local targetIdx = {math.random(1, #targets), 
                math.random(1, #targets), 
                math.random(1, #targets)}

            CMD_USESKILL_POINT(skillID, 0, 0, 
                {targets[targetIdx[1]], targets[targetIdx[2]], targets[targetIdx[3]]})
		elseif skillID == 1120 then
			CMD_USESKILL_DIR(skillID, selfDir, targets)
		elseif skillInfo.Attack_Types == 3 then --target self
			CMD_USESKILL(skillID, maincha.id)
		elseif skillInfo.Attack_Types == 0 then	--target other
			--MgrPlayer[maincha.id]:AttackPlayer(skillID, atkEnd, nil)
            MgrPlayer[maincha.id].playSkillAction = skillID
			CMD_USESKILL_POINT(skillID, selfPos.x, selfPos.y, nil)
		elseif skillInfo.Attack_Types == 1 then	--AOE
			--MgrPlayer[maincha.id]:AttackPlayer(skillID, atkEnd, nil)
            MgrPlayer[maincha.id].playSkillAction = skillID
			CMD_USESKILL_POINT(skillID, selfPos.x, selfPos.y, targets)
		elseif skillInfo.Attack_Types == 2 then	--dir
            MgrPlayer[maincha.id].playSkillAction = skillID
			--MgrPlayer[maincha.id]:AttackPlayer(skillID, atkEnd, nil)
			CMD_USESKILL_DIR(skillID, selfDir, targets)
		end
		
        --[[if skillInfo.Energy then
            MgrFight.anger = MgrFight.anger - skillInfo.Energy
            local scene = cc.Director:getInstance():getRunningScene()
            local fight = scene.hud:getUI("UIFightLayer")
            fight:UpdateAnger()
        end]]--
		
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