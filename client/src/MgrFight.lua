local netCmd = require "src.net.NetCmd"

MgrFight = MgrFight or {}

MgrFight.lockTarget = MgrFight.lockTarget or nil
MgrFight.lastSkill = {["skillID"] = math.random(1, 3) + 10, ["useTime"] = 0}
 
local timerTime  = 3.1
function MgrFight:atkTick(detal)
    timerTime = timerTime + detal
    local selfPosX, selfPosY = MgrPlayer[maincha.id]:getPosition()
    if MgrFight.lockTarget then
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
end

function MgrFight:atkTarget()    
    MgrFight.PlayingSkill = true
    local skillID = MgrFight.lastSkill.skillID

    skillID = skillID + 1
    if skillID > 13 then
        skillID = 11
    end

    MgrFight.lastSkill.skillID = skillID
    MgrSkill.UseSkill(skillID)
end

RegNetHandler(function (packet) 
    local atker = MgrPlayer[packet.atkerid]
    local sufferer = MgrPlayer[packet.suffererid]
    local skillid = packet.skillid
    local success = packet.success
    print("CMD_SC_NOTIATK")
end,netCmd.CMD_SC_NOTIATK)

RegNetHandler(function (packet) 
    local sufferer = MgrPlayer[packet.suffererid]
    local atker = MgrPlayer[packet.atkerid]

    sufferer.attr.life  = sufferer.attr.life + packet.hpchange
    sufferer:SetLife(sufferer.attr.life, sufferer.attr.maxlife)

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
    local atker = MgrPlayer[packet.atkerid]
    local sufferer = MgrPlayer[packet.suffererid]
    sufferer:Hit()
    atker:AttackPlayer(packet.skillid, nil, sufferer)
end,netCmd.CMD_SC_NOTISUFFER)  

RegNetHandler(function (packet)
    print("netCmd.CMD_SC_BUFFBEGIN")
    local atker = MgrPlayer[packet.id]
    atker:stopAllActions()
    atker:getChildByTag(EnumAvatar.Tag3D):stopAllActions()
    print(atker)
    local atkActions = atker.actions[EnumActions.Skill3]
    local action = cc.RepeatForever:create(atkActions)
    action:setTag(packet.buffid)
    atker:getChildByTag(EnumAvatar.Tag3D):runAction(action)
    print("netCmd.CMD_SC_BUFFBEGIN")
end, netCmd.CMD_SC_BUFFBEGIN)

RegNetHandler(function (packet)
    print("netCmd.CMD_SC_BUFFEND")
    local atker = MgrPlayer[packet.id]
    atker:getChildByTag(EnumAvatar.Tag3D):stopActionByTag(packet.buffid)
    atker:Idle()
end, netCmd.CMD_SC_BUFFEND)