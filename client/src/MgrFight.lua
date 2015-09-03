local netCmd = require "src.net.NetCmd"

MgrFight = MgrFight or {}

--MgrFight.lockTarget = MgrFight.lockTarget or nil
--MgrFight.lastSkill = {["skillID"] = math.random(1, 3) + 10, ["useTime"] = 0}
MgrFight.lastSkillIdx = 1
MgrFight.StateFighting = false
MgrFight.CanUseSkill = true
MgrFight.anger = 0
MgrFight.FivePVERound = 0
MgrFight.EnterMapTime = 0

local comm = require("common.CommonFun")

local timerTime  = 3.1
function MgrFight:atkTick(detal)
    timerTime = timerTime + detal
    local localPlayer = MgrPlayer[maincha.id]
    
    if MgrFight.StateFighting and localPlayer then
        if localPlayer.attr.life > 0 and not localPlayer.moveTo then
            timerTime = 0
            local skillid = MgrSkill.BaseSkill[MgrFight.lastSkillIdx]
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
    local skillID = MgrSkill.BaseSkill[MgrFight.lastSkillIdx ]
    MgrFight.lastSkillIdx  = MgrFight.lastSkillIdx  + 1
    if MgrFight.lastSkillIdx  > #MgrSkill.BaseSkill then
        MgrFight.lastSkillIdx  = 1
    end
    
    MgrSkill.UseSkill(skillID, nil, selfDir, targets)
end

local function HitEff(atkerid, sufferid, type)
    local scene = cc.Director:getInstance():getRunningScene()
    local hud = scene.hud
    
    if atkerid == maincha.id or sufferid == maincha.id then    
        local player = MgrPlayer[maincha.id]
        local posX, posY = player:getPosition()
        local worldPos = player:getParent():convertToWorldSpace(cc.p(posX+20, posY))
        local eff = nil 
        
        if type == 1 then   --miss
            eff = cc.Sprite:create("UI/fight/sb.png")
        elseif type == 2 then   --crit
            eff = cc.Sprite:create("UI/fight/bj.png")
            
            local mapPosX, mapPoxY = scene.map:getPosition()
            local effPosX = 0
            local effPosY = 0
            
            if math.abs(mapPosX) > 20 then
                effPosX = 20
            else
                mapPosX = -20
            end 

            local ac1 = cc.MoveBy:create(0.05,{x = effPosX, y = effPosY})
            local ac2 = cc.MoveBy:create(0.05,{x = -effPosX, y = -effPosY})
            local ac3 = cc.MoveBy:create(0.05,{x = effPosX, y = effPosY})
            local ac4 = cc.MoveBy:create(0.05,{x = -effPosX, y = -effPosY})
            
            local function onEnd()
                scene.moveAction = scene.moveAction - 1
            end
            
            scene.moveAction = scene.moveAction + 1
            local ac = cc.Sequence:create(ac1, ac2, ac3, ac4, cc.CallFunc:create(onEnd))
            scene.map:runAction(ac)
        end
        
        if eff then
            eff:setPosition(worldPos)
            local acScale = cc.EaseOut:create(cc.ScaleTo:create(0.06,1.5), 3)
            local acMove = cc.EaseOut:create(cc.MoveBy:create(0.06,{x = 20, y = 50}), 3)
            local ac = cc.Spawn:create(acScale, acMove)
            eff:runAction(cc.Sequence:create(ac, cc.DelayTime:create(0.3), cc.RemoveSelf:create()))
            hud:addChild(eff)
        end
    end
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

        if packet.atkerid == maincha.id then
            local localPlayer = MgrPlayer[maincha.id]
            if localPlayer and localPlayer.moveTo then
                CMD_MOV(localPlayer.moveTo)
            end
        end
    end
    print(success,skillid)
    --if success and packet.atkerid ~= maincha.id then
    if success > 0 then
        if success == 2 and skillid ~= 1040 then
            local sprite3D =  atker:GetAvatar3D()
            if sprite3D then
                local rotation = sprite3D:getRotation3D()
                rotation.y = dir + 90
                sprite3D:setRotation3D(rotation)
            end
            
            atker.playSkillAction = skillid
            atker:AttackPlayer(skillid, endHandle, nil)
            
            --[[
            local pos = cc.WalkTo:tile2MapPos(packet.atkpoint)        
            local moveAction = cc.MoveTo:create(0.06, pos)
            --moveAction:setTag(EnumActionTag.ActionMove)
            atker:runAction(moveAction)
            ]]
        elseif success == 1 then
            --atker:setPosition(cc.WalkTo:tile2MapPos(packet.point))
            atker.playSkillAction = skillid
            atker:AttackPlayer(skillid, endHandle, nil)
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

    local function endAtk()      
        atker.playSkillAction = 0
        atker:DelayIdle(0.1)  
        if packet.atkerid == maincha.id then
            local localPlayer = MgrPlayer[maincha.id]
            if localPlayer and localPlayer.moveTo then
                CMD_MOV(localPlayer.moveTo)
            end
        end
    end

    local elapseTime = os.clock() - packet.atktime * 0.001
    local delayHitTime = atker.delayHit[EnumActions[TableSkill[packet.skillid].ActionName]]

    --if packet.atkerid ~= maincha.id then
    if true then
        if sufferer.attr.life > 0 and packet.hpchange ~= 0 then
            sufferer:DelayHit(delayHitTime, packet.hpchange, packet.atkerid == maincha.id)
        end
        --[[
        local pos = cc.WalkTo:tile2MapPos(packet.atkpoint)        
        local moveAction = cc.MoveTo:create(0.06, pos)
        --moveAction:setTag(EnumActionTag.ActionMove)
        atker:runAction(moveAction)
        ]]
        atker:AttackPlayer(packet.skillid, endAtk, sufferer)       
    else
        if sufferer.attr.life > 0 and packet.hpchange ~= 0 then
            sufferer:DelayHit(delayHitTime - elapseTime, packet.hpchange, packet.atkerid == maincha.id)
        end
    end

    if sufferer.attr.life <= 0 then
        sufferer:Death()
        MgrPlayer[maincha.id]:Idle()
        --print("sufferer dead")
    end

    if packet.crit then
        HitEff(packet.atkerid, packet.suffererid, 2)
    elseif packet.miss then
        HitEff(packet.atkerid, packet.suffererid, 1)
    end
end,netCmd.CMD_SC_NOTIATKSUFFER)

RegNetHandler(function (packet) 
    --print("CMD_SC_NOTISUFFER")
    local atker = MgrPlayer[packet.atker]
    local sufferer = MgrPlayer[packet.suffererid]
    if (not sufferer) or (not atker) then
        --print("no sufferer:"..packet.suffererid)
        return
    end

    if packet.bRepel == 1 then
        local pos = cc.WalkTo:tile2MapPos(packet.point)
        --print("CMD_SC_NOTISUFFER:"..pos.x.." "..pos.y)
        sufferer:Repel(pos, packet.hpchange)
    else
        local elapseTime = os.clock() - packet.atktime * 0.001
        local delayHitTime = atker.delayHit[EnumActions[TableSkill[packet.skillid].ActionName]]
        if sufferer.attr.life > 0 and packet.hpchange ~= 0 then
            sufferer:DelayHit(delayHitTime - elapseTime, packet.hpchange, packet.atker == maincha.id)
        end
    end    
    --print("noti suffer:"..packet.hpchange)
    --atker:AttackPlayer(packet.skillid, nil, sufferer)
    
    if packet.crit then
        HitEff(packet.atker, packet.suffererid, 2)
    elseif packet.miss then
        HitEff(packet.atker, packet.suffererid, 1)
    end
end,netCmd.CMD_SC_NOTISUFFER)  

RegNetHandler(function (packet)
    print("CMD_SC_NOTIATKSUFFER2")
    local atker = MgrPlayer[packet.atker]
    local function atkEnd()
        atker.playSkillAction = 0
        atker:DelayIdle(0.1)

        if packet.atkerid == maincha.id then
            local localPlayer = MgrPlayer[maincha.id]
            if localPlayer and localPlayer.moveTo then
                CMD_MOV(localPlayer.moveTo)
            end
        end
    end    

    if packet.skillid == 1060 then
        local targetId = {}
        local hpchanges = {}
        for k, value in pairs(packet.suffers) do
            table.insert(targetId, value.id)
            table.insert(hpchanges, value.hpchange)
        end

        local attackIdx = 1
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
                    local acIdx = "Attack"..attackIdx
                    attackIdx = attackIdx + 1
                    local function moveEnd()
                        atker:GetAvatar3D():stopAllActions()
                        atker:GetAvatar3D():runAction(cc.Sequence:create(atker.actions[EnumActions[acIdx]],
                        cc.CallFunc:create(attack))) 
                        
                        if hpchanges[attackIdx] ~= 0 then
                            player:DelayHit(0.5, hpchanges[attackIdx], packet.atker == maincha.id)
                        end
                    end
                    atker:runAction(cc.Sequence:create(moveAC,
                                    cc.CallFunc:create(moveEnd)))
                end
                --[[
                if #targetId > 0 then
                    MgrFight.StateFighting = false
                    atker.playSkillAction = 1060
                    attack()
                end
                ]]
            else
                atker.playSkillAction = 0
                atker:Idle()
            end
        end 

        if #targetId > 0 then
            MgrFight.StateFighting = false
            atker.playSkillAction = 1060
            attack()
            local skillInfo = TableSkill[1060]
            
            if skillInfo.Sound and atker.actions[EnumActions.Skill5] then
                local path = TableSound[skillInfo.Sound].Path
                comm.playEffect("music/"..path)
            end
        end

        return
    end

	atker.playSkillAction = packet.skillid    
    atker:AttackPlayer(packet.skillid, atkEnd, nil)
    local pos = cc.WalkTo:tile2MapPos(packet.atkerpos)
    local atkerMove = cc.MoveTo:create(0.1, pos)
    atker:runAction(atkerMove)
   
    local bHasLocalPlayer = false
    local type = 0
    for k, value in pairs(packet.suffers) do        
        local suffer = MgrPlayer[value.id]
        pos = cc.WalkTo:tile2MapPos(value.pos)
        suffer:Repel(pos, value.hpchange)
        if packet.suffers == maincha.id then
            bHasLocalPlayer = true
        end
    end
    
    if bHasLocalPlayer or packet.atker == maincha.id then
        if packet.crit then
            HitEff(packet.atker, maincha.id, 2)
        elseif packet.miss then
            HitEff(packet.atker, maincha.id, 1)
        end
    end 
end,netCmd.CMD_SC_NOTIATKSUFFER2)

local buffScheduleID = {}
local function buffScheduleHand()
    
end

RegNetHandler(function (packet)   
    --print("netCmd.CMD_SC_BUFFBEGIN:"..packet.id)
    local localPlayer = MgrPlayer[maincha.id]
    local atker = MgrPlayer[packet.id]
    local buffEff = comm.getBuffEff(packet.buffid)
    if buffEff then
        buffEff:setTag(packet.buffid)
        atker:addChild(buffEff)
        atker:stopAllActions()
    end
    
    local buffInfo = TableBuff[packet.buffid]
    if buffInfo.ActionName then
        atker:GetAvatar3D():stopAllActions()
    end        

    if buffInfo.Sound then
        local path = TableSound[buffInfo.Sound].Path
        comm.playEffect("music/"..path)
    end

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
    elseif packet.buffid == 3201 then
        local atkActions = atker.actions[EnumActions[buffInfo.ActionName]]
        atkActions:setTag(packet.buffid)
        atker:GetAvatar3D():runAction(atkActions)
    else
        local atkActions = atker.actions[EnumActions[buffInfo.ActionName]]
        if atkActions then
            local action = cc.RepeatForever:create(atkActions)
            action:setTag(packet.buffid)
            atker:GetAvatar3D():runAction(action)
        end
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
                --print("buff skill:"..buffInfo.AtkSkill)
            end
            end, buffInfo.ClientInterval/1000, false)
    end
end, netCmd.CMD_SC_BUFFBEGIN)

RegNetHandler(function (packet)
    --print("netCmd.CMD_SC_BUFFEND")
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
    local buffInfo = TableBuff[packet.buffid]
    if buffInfo.ActionName then
        atker:GetAvatar3D():stopActionByTag(packet.buffid)
        atker:Idle()
    end
end, netCmd.CMD_SC_BUFFEND)

RegNetHandler(function (packet)
    MgrFight.FivePVERound = packet.round 
    local scene = cc.Director:getInstance():getRunningScene()
    for key, ui in pairs(scene.hud.UIS) do
        if ui.onFivePVERound then
            ui:onFivePVERound()
        end
    end
end, netCmd.CMD_SC_NOTI_5PVE_ROUND)

RegNetHandler(function (packet)
    local scene = cc.Director:getInstance():getRunningScene()
    local ui = scene.hud:openUI("UIPVEResult")
    
    if packet.lose then
        ui:Failed()
    else
        local items = {{id = 4001, count = math.random(500,5000)},
            {id = 4004, count = math.random(1000,8000)}}
        ui:Win(items)
        addItem(items[1].id, items[1].count)
        addItem(items[2].id, items[2].count)
    end
    
    local backSchID = nil
    local function back()
        cc.Director:getInstance():getScheduler():unscheduleScriptEntry(backSchID)
        CMD_LEAVE_MAP()
    end
                    
    backSchID = cc.Director:getInstance():getScheduler():scheduleScriptFunc(back, 3, false)
end, netCmd.CMD_SC_5PVP_RESULT)

RegNetHandler(function (packet)
    local scene = cc.Director:getInstance():getRunningScene()
    local ui = scene.hud:openUI("UIPVEResult")
    
    local items = {{id = 4001, count = MgrFight.FivePVERound*500},
        {id = 4004, count = MgrFight.FivePVERound*500}}
        
    ui:FailedAward(items)        
    --addItem(items[1].id, items[1].count)
    --addItem(items[2].id, items[2].count)
    
    local backSchID = nil
    local function back()
        cc.Director:getInstance():getScheduler():unscheduleScriptEntry(backSchID)
        CMD_LEAVE_MAP()
    end
                    
    backSchID = cc.Director:getInstance():getScheduler():scheduleScriptFunc(back, 3, false)
end, netCmd.CMD_SC_5PVE_RESULT)
