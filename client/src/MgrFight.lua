local netCmd = require "src.net.NetCmd"

MgrFight = MgrFight or {}

--MgrFight.lockTarget = MgrFight.lockTarget or nil
--MgrFight.lastSkill = {["skillID"] = math.random(1, 3) + 10, ["useTime"] = 0}
local lastSkillIdx = 1
MgrFight.StateFighting = false

local comm = require("common.CommonFun")

local timerTime  = 3.1
function MgrFight:atkTick(detal)
    timerTime = timerTime + detal

    if MgrFight.StateFighting and MgrPlayer[maincha.id] then
        if MgrPlayer[maincha.id].attr.life > 0 then
            timerTime = 0
            local skillid = MgrSkill.BaseSkill[lastSkillIdx]
            if MgrSkill.CanUseSkill(skillid) then
                local selfDir, targets = comm.getDirSkillTargets(skillid)

                if targets and #targets > 0 then
                    self:atkTarget(selfDir, targets)
                end
            end
        end
    end

    --[[
    if MgrFight.lockTarget and
        MgrFight.lockTarget.teamid ~= localPlayer.teamid then

        local tarPosX, tarPosY = MgrFight.lockTarget:getPosition()
        local disX = tarPosX - selfPosX
        local disY = tarPosY - selfPosY
        local dis = disX * disX + disY * disY
        
        if  timerTime > 0.5 then
            timerTime = 0                
            if dis > 16200 then
                local off = math.random(60, 90)
                if selfPosX > tarPosX then
                    tarPosX = tarPosX + off
                else
    tarPosX = tarPosX - off
                end

                if selfPosY > tarPosY then
                    tarPosY = tarPosY + off
                else
                    tarPosY = tarPosY - off
                end
                
                CMD_MOV(cc.WalkTo:map2TilePos({x = tarPosX, y = tarPosY}))
            end
        end        

        atkTimes = atkTimes or 0 
        if MgrSkill.CanUseSkill(MgrFight.lastSkill.skillID)
            and not MgrSkill.HasSkillInCD()
            and dis <= 16200 
            and MgrFight.lockTarget.attr.life > 0 then
            print("---------------"..atkTimes.."--------------------")
            atkTimes = atkTimes + 1
            self:atkTarget()
        end
    end
    ]]
end

function MgrFight:atkTarget(selfDir, targets)    
    MgrFight.PlayingSkill = true
    local skillID = MgrSkill.BaseSkill[lastSkillIdx]
    lastSkillIdx = lastSkillIdx + 1
    if lastSkillIdx > #MgrSkill.BaseSkill then
        lastSkillIdx = 1
    end
    
    MgrSkill.UseSkill(skillID, nil, selfDir, targets)
end

RegNetHandler(function (packet) 
    print("CMD_SC_NOTIATK")
    local atker = MgrPlayer[packet.atkerid]
    if not atker then
        print("no find atker:"..packet.atkerid)
        return
    end 
    local skillid = packet.skillid
    local dir = packet.dir

    local success = packet.success

    local function endHandle()
        atker.playSkillAction = 0
        atker:DelayIdle(0.1)
    end
    if success and packet.atkerid ~= maincha.id then
        if success == 2 and skillid ~= 1040 then
            local sprite3D =  atker:GetAvatar3D()
            if sprite3D then
                local rotation = sprite3D:getRotation3D()
                rotation.y = dir + 90
                sprite3D:setRotation3D(rotation)
            end
            
            atker.playSkillAction = skillid
            atker:AttackPlayer(skillid, endHandle, nil)
        elseif success == 1 then
            --atker:setPosition(cc.WalkTo:tile2MapPos(packet.point))
        end
    end
end,netCmd.CMD_SC_NOTIATK)

RegNetHandler(function (packet) 
    print("CMD_SC_NOTIATKSUFFER")
    local sufferer = MgrPlayer[packet.suffererid]
    local atker = MgrPlayer[packet.atkerid]

    if (not sufferer) or (not atker) then
        return
    end

    local function nullAction()        
    end
    
    local elapseTime = os.clock() - packet.atktime * 0.001
    local delayHitTime = atker.delayHit[EnumActions[TableSkill[packet.skillid].ActionName]]

    if packet.atkerid ~= maincha.id then
        if sufferer.attr.life > 0 then
            sufferer:DelayHit(delayHitTime, packet.hpchange)
        end
        atker:AttackPlayer(packet.skillid, nullAction, sufferer)       
    else
        if sufferer.attr.life > 0 then
            sufferer:DelayHit(delayHitTime - elapseTime, packet.hpchange)
        end
    end

    if sufferer.attr.life <= 0 then
        sufferer:Death()
        MgrPlayer[maincha.id]:Idle()
        print("sufferer dead")
    end
end,netCmd.CMD_SC_NOTIATKSUFFER)

RegNetHandler(function (packet) 
    print("CMD_SC_NOTISUFFER")
    local atker = MgrPlayer[packet.atker]
    local sufferer = MgrPlayer[packet.suffererid]
    if (not sufferer) or (not atker) then
        print("no sufferer:"..packet.suffererid)
        return
    end

    if packet.bRepel == 1 then
        local pos = cc.WalkTo:tile2MapPos(packet.point)
        sufferer:Repel(pos, packet.hpchange)
    else
        local elapseTime = os.clock() - packet.atktime * 0.001
        local delayHitTime = atker.delayHit[EnumActions[TableSkill[packet.skillid].ActionName]]
        if sufferer.attr.life > 0 then
            sufferer:DelayHit(delayHitTime - elapseTime, packet.hpchange)
        end
    end    
    print("noti suffer:"..packet.hpchange)
    --atker:AttackPlayer(packet.skillid, nil, sufferer)
end,netCmd.CMD_SC_NOTISUFFER)  

RegNetHandler(function (packet)
    print("CMD_SC_NOTIATKSUFFER2")
    
    local atker = MgrPlayer[packet.atker]
    local function atkEnd()
        atker.playSkillAction = 0
        atker:DelayIdle(0.1)
    end    

    if packet.skillid == 1060 then
        local targetId = {}
        for k, value in pairs(packet.suffers) do
            table.insert(targetId, value.id)
        end
        local function attack()
            if #targetId > 0 then
                local idx = targetId[1]
                table.remove(targetId, 1)
                local player = MgrPlayer[idx]
                if player then
                    local selfPosX, selfPosY = atker:getPosition()
                    local tarPosX, tarPosY = player:getPosition()
                    local norP = cc.pNormalize(cc.p(tarPosX-selfPosX, tarPosY-selfPosY))
                    local tarP = cc.p(tarPosX - norP.x*50, tarPosY - norP.y*50)
                    local moveAC = cc.MoveTo:create(0.1, tarP)
                    local angle = math.deg(math.atan2(norP.y,norP.x))
                    atker:GetAvatar3D():setRotation3D{x = 0, y = angle+90, z = 0}
                    atker:runAction(cc.Sequence:create(moveAC, cc.CallFunc:create(attack)))
                end
            end
        end

        if #targetId > 0 then
            MgrFight.StateFighting = false
            attack()
        end

        return
    end

	atker.playSkillAction = packet.skillid    
    atker:AttackPlayer(packet.skillid, atkEnd, nil)
    local pos = cc.WalkTo:tile2MapPos(packet.atkerpos)
    local atkerMove = cc.MoveTo:create(0.1, pos)
    atker:runAction(atkerMove)

    for k, value in pairs(packet.suffers) do        
        local suffer = MgrPlayer[value.id]
        pos = cc.WalkTo:tile2MapPos(value.pos)
        suffer:Repel(pos, value.hpchange)
    end
end,netCmd.CMD_SC_NOTIATKSUFFER2)

local buffScheduleID = {}
local function buffScheduleHand()
    
end

RegNetHandler(function (packet)   
    print("netCmd.CMD_SC_BUFFBEGIN:"..packet.id)
    local localPlayer = MgrPlayer[maincha.id]
    local atker = MgrPlayer[packet.id]
    local buffEff = comm.getBuffEff(packet.buffid)
    buffEff:setTag(packet.buffid)
    atker:addChild(buffEff)
    atker:stopAllActions()

    local buffInfo = TableBuff[packet.buffid]
    atker:GetAvatar3D():stopAllActions()

    if packet.buffid == 3002 then
        local atkActions = atker.actions[EnumActions[buffInfo.ActionName]]
        local function atkIdle()
        	atker:Idle()
        end
        local sprite3D = atker:GetAvatar3D()
        sprite3D:runAction(cc.Sequence:create(atkActions, cc.CallFunc:create(atkIdle)))
        
        if atker.teamid == localPlayer.teamid then
            sprite3D:runAction(cc.FadeTo:create(0.2, 125))
            sprite3D:getAttachNode(WeaponNodeName):runAction(cc.FadeTo:create(0.2, 125))
        else
            atker:setVisible(false)
        end
    else
        local atkActions = atker.actions[EnumActions[buffInfo.ActionName]]
        local action = cc.RepeatForever:create(atkActions)
        action:setTag(packet.buffid)
        atker:GetAvatar3D():runAction(action)
    end

    atker.buffState[packet.buffid] = true
    
    if packet.id == maincha.id and buffInfo.AtkSkill then
        local schedule = cc.Director:getInstance():getScheduler()
        buffScheduleID[packet.buffid] = schedule:scheduleScriptFunc(function()
            local targetID = {}
            local targetCount = 0
            local selfPlayer = MgrPlayer[maincha.id]

            if not selfPlayer then 
                local schedule = cc.Director:getInstance():getScheduler()
                schedule:unscheduleScriptEntry(packet.buffid)
                return
            end


            local posX, posY = selfPlayer:getPosition()
            local skillInfo = TableSkill[buffInfo.AtkSkill]
            for id, value in pairs(MgrPlayer) do
                if value and value.teamid ~= selfPlayer.teamid then
                    print(value.teamid)
                    local tarPosX, tarPosY = value:getPosition()
                    local dis = cc.pGetDistance(cc.p(posX, posY), cc.p(tarPosX, tarPosY))
                    if dis < skillInfo.Att_Range then
                        targetCount = targetCount + 1
                        targetID[targetCount] = value.id
                    end      
                end
            end
            
            CMD_USESKILL_POINT(buffInfo.AtkSkill, posX, posY, targetID)
            if #targetID > 0 then
                print("buff skill:"..buffInfo.AtkSkill)
            end
            end, buffInfo.ClientInterval/1000, false)
    end
end, netCmd.CMD_SC_BUFFBEGIN)

RegNetHandler(function (packet)
    print("netCmd.CMD_SC_BUFFEND")
    local atker = MgrPlayer[packet.id]
    atker:removeChildByTag(packet.buffid)
    atker.buffState[packet.buffid] = nil
    
    if buffScheduleID[packet.buffid] then
        local schedule = cc.Director:getInstance():getScheduler()
        schedule:unscheduleScriptEntry(buffScheduleID[packet.buffid])
    end
    
    if packet.buffid == 3002 then
        local localPlayer = MgrPlayer[maincha.id]
        local sprite3D = atker:GetAvatar3D()
        
        if atker.teamid == localPlayer.teamid then
            sprite3D:runAction(cc.FadeTo:create(0.2, 255))
            sprite3D:getAttachNode(WeaponNodeName):getChildByTag(100):runAction(cc.FadeTo:create(0.2, 255))
        else
            atker:setVisible(true)
        end
    end
    atker.playSkillAction = 0
    atker:GetAvatar3D():stopActionByTag(packet.buffid)
    atker:Idle()
end, netCmd.CMD_SC_BUFFEND)