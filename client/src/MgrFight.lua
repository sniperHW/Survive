MgrFight = MgrFight or {}

MgrFight.lockTarget = MgrFight.lockTarget or nil
MgrFight.lastSkill = {["skillID"] = 0, ["useTime"] = 0}
MgrFight.PlayingSkill = false
local bDead = false 
local timerTime  = 3.1
function MgrFight:atkTick(detal)
    timerTime = timerTime + detal
    local selfPosX, selfPosY = MgrPlayer[maincha.id]:getPosition()
    if MgrFight.lockTarget then
        local tarPosX, tarPosY = MgrFight.lockTarget:getPosition()
        local disX = tarPosX - selfPosX
        local disY = tarPosY - selfPosY
        local dis = disX * disX + disY * disY
        
        if  timerTime > 2 then
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

        if not MgrFight.PlayingSkill and dis <= 16200 and MgrFight.lockTarget.attr.life > 0 then
            self:atkTarget()
        end
    end
end

function MgrFight:atkTarget()
    local function atkEnd()
        MgrFight.PlayingSkill = false
    end
    
    MgrFight.PlayingSkill = true
    local skillID = MgrFight.lastSkill.skillID
    if skillID == 0 then
        skillID = math.random(1, 3)
    else
        skillID = skillID % 3 + 1
    end
    MgrFight.lastSkill.skillID = skillID
    MgrPlayer[maincha.id]:AttackPlayer(skillID, atkEnd, MgrFight.lockTarget)
    CMD_USESKILL(skillID, MgrFight.lockTarget.id)
end

RegNetHandler(function (packet) 
    local atker = MgrPlayer[packet.atkerid]
    local sufferer = MgrPlayer[packet.suffererid]
    local skillid = packet.skillid
    local success = packet.success
    print("CMD_SC_NOTIATK")
end,CMD_SC_NOTIATK)

RegNetHandler(function (packet) 
    print("CMD_SC_NOTIATKSUFFER")
    print(packet.hpchange)
    local sufferer = MgrPlayer[packet.suffererid]
    sufferer:Hit()
    print(sufferer.attr.life)
    print(sufferer.attr.maxlife)
    sufferer.attr.life  = sufferer.attr.life + packet.hpchange
    sufferer:SetLife(sufferer.attr.life, 100)
    if sufferer.attr.life <= 0 then
        sufferer:Death()
    end
    if packet.atkerid ~= maincha.id then
        local atker = MgrPlayer[packet.atkerid]
        atker:AttackPlayer(packet.skillid, nil, sufferer)        
    end
end,CMD_SC_NOTIATKSUFFER)

RegNetHandler(function (packet) 
    print("CMD_SC_NOTISUFFER")
    print(packet.hpchange)
    local atker = MgrPlayer[packet.atkerid]
    local sufferer = MgrPlayer[packet.suffererid]
    sufferer:Hit()
    atker:AttackPlayer(packet.skillid, nil, sufferer)
end,CMD_SC_NOTISUFFER)  