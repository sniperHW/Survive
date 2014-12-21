local comm = {}

local skillEffAttr = {
    [1010] = {pos = {x = 0, y = 50}},
    [1020] = {Delay=0.1, pos = {x = 0, y = 50}},
    [1030] = {},
    [1040] = {},
    [1050] = {},
    [1110] = {pos = {x = 0, y = 50}},
    [1130] = {pos = {x = 0, y = 0}, zorder = -1},
}

local buffEffAttr = {
    [3001] = {pos = {x = 0, y = 50}},
    [3002] = {pos = {x = 0, y = 50}}
}

function comm.getEffAni(effID)
    if effID < 1 then
        return nil
    end

    local animation = cc.Animation:create()
    local tblEff = TableSpecial_Effects[effID]

    local frameCache = cc.SpriteFrameCache:getInstance()
    frameCache:addSpriteFrames("effect/"..tblEff.Resource_Path..".plist")
    print("effect/"..tblEff.Resource_Path..".plist")
    local name = ""
    for i = tblEff.Start_Frame, tblEff.End_Frame do
        name = string.format(tblEff.Name..".png", i)
        animation:addSpriteFrame(frameCache:getSpriteFrame(name))
    end
    animation:setDelayPerUnit(tblEff.Frame_Interval)
    local animate = cc.Animate:create(animation)
    
    return animate
end

function comm.getSkillEff(skillID, d) 
    local dir = d
    local effIDoff = 0
    local bFlipX = false
    local bFlipY = false
    local zorder = 1
    if dir < 0 then
        dir = dir + 360
    end
    
    if skillID ~= 1130 then
        if (dir >= 0 and dir <= 22.5) or (dir <= 360 and dir > 337.5) then
            effIDoff = 1
            bFlipX = false
            bFlipY = false
            zorder = 1
        elseif (dir > 22.5 and dir <= 67.5) then
            effIDoff = 2
            bFlipX = false
            bFlipY = false
            zorder = -1
        elseif (dir > 67.5 and dir <= 112.5) then
            effIDoff = 0
            bFlipX = false
            bFlipY = false
            zorder = -1
        elseif (dir > 112.5 and dir <= 157.5) then
            effIDoff = 2
            bFlipX = true
            bFlipY = false
            zorder = -1
        elseif (dir > 157.5 and dir <= 202.5) then
            effIDoff = 1
            bFlipX = true
            bFlipY = false
            zorder = 1
        elseif (dir > 202.5 and dir <= 247.5) then
            if skillID == 1020 then
                effIDoff = 3
                bFlipX = true
                bFlipY = false
                zorder = 1
            else     
                effIDoff = 2
                bFlipX = true
                bFlipY = true
                zorder = 1
            end
        elseif (dir > 247.5 and dir <= 292.5) then
            effIDoff = 0
            bFlipX = false
            bFlipY = true
            zorder = 1
        elseif (dir > 292.5 and dir < 337.5) then
            if skillID == 1020 then
                effIDoff = 3
                bFlipX = false
                bFlipY = false
                zorder = 1
            else        
                effIDoff = 2
                bFlipX = false
                bFlipY = true
                zorder = 1
            end        
        end
    end

    local sprite = nil
    local skillInfo = TableSkill[skillID]    
    
    if skillInfo and skillInfo.Effects_ID then
       local animate = comm.getEffAni(skillInfo.Effects_ID + effIDoff)
       local tblEff = TableSpecial_Effects[skillInfo.Effects_ID + effIDoff]
	   if skillInfo.additive then
            local name = string.format(tblEff.Name..".png", tblEff.Start_Frame)
            sprite = cc.Sprite:createWithSpriteFrameName(name)
            sprite:setBlendFunc(gl.SRC_ALPHA, gl.ONE)
        else
            sprite = cc.Sprite:create()
	   end
	   if skillEffAttr[skillID] and skillEffAttr[skillID].Delay then
            sprite:runAction(cc.Sequence:create(cc.DelayTime:create(skillEffAttr[skillID].Delay ),
                animate, cc.RemoveSelf:create()))
       else
            sprite:runAction(cc.Sequence:create(animate, cc.RemoveSelf:create()))
	   end
	   
	   if tblEff.RotationZ then
            sprite:setRotation3D({x = 0, y = tblEff.RotationZ, z = 0})
	   end	   

       if skillEffAttr[skillID] and skillEffAttr[skillID].zorder then
            sprite:setLocalZOrder(skillEffAttr[skillID].zorder)
       else
            sprite:setLocalZOrder(zorder)
       end
       --sprite:setAnchorPoint({x = 0.2, y = 0.2}) 
       sprite:setFlippedX(bFlipX)
       sprite:setFlippedY(bFlipY)
       
       if skillEffAttr[skillID] and skillEffAttr[skillID].pos then
           sprite:setPosition(skillEffAttr[skillID].pos)
       end
       sprite:setRotation3D{x = -35, y = 0, z = 0}
       --sprite:setScale(0.7)
	end

	return sprite
end

function comm.getBuffEff(buffID, d) 
    local buffInfo = TableBuff[buffID]
    local sprite = nil

    if buffInfo and buffInfo.Effects_ID then
        sprite = cc.Sprite:create()
        local animate = comm.getEffAni(buffInfo.Effects_ID)
        if buffID == 3002 then
            sprite:runAction(cc.Sequence:create(animate, cc.RemoveSelf:create()))
        else
            sprite:runAction(cc.RepeatForever:create(animate))
        end        
    end

    if buffEffAttr[buffID].pos then
        sprite:setPosition(buffEffAttr[buffID].pos)
    end

    return sprite
end

function comm.getDirSkillTargets(skillID)
	local targets = {}
	
    local localPlayer = MgrPlayer[maincha.id]
	if not localPlayer then
		return 
	end
    
    local selfPosX, selfPosY = localPlayer:getPosition()
    local selfPos = localPlayer:getParent():convertToWorldSpace({x = selfPosX, y = selfPosY})
    local selfDir = localPlayer:GetAvatar3D():getRotation3D().y - 90

    local skillInfo = TableSkill[skillID]

    if not skillInfo or skillInfo.Attack_Types ~= 2 then
        return selfDir, targets
    end
    
    for id, value in pairs(MgrPlayer) do
        if value and value.teamid ~= localPlayer.teamid 
            and value.attr.life > 0 then
            local tarPosX, tarPosY = value:getPosition()
            local tarPos = cc.p(tarPosX, tarPosY)
            local dis = cc.pGetDistance(selfPos, tarPos)
            
            local box = value:GetAvatar3D():getBoundingBox()
            if cc.rectContainsPoint(box, selfPos) then
                table.insert(targets, value.id)
            else
                local boxpoints = {{x = box.x, y = box.y},
                    {x = box.x, y = box.y + box.height},
                    {x = box.x + box.width, y = box.y},
                    {x = box.x + box.width, y = box.y + box.height}
                }
    
                local maxangle = 0
                local minangle = -1
                local inanlge = false
    
                for k, p in ipairs(boxpoints) do
                    local d = cc.pGetDistance(selfPos, p)
                    if d < dis then
                        dis = d
                    end
    
                    local dirVec = cc.pSub(p, selfPos)
                    local dir = cc.pToAngleSelf(dirVec) * 57.3
                    
                    if dir < 0 then
                        dir = dir + 360
                    end
    
                    if dir > maxangle then
                        maxangle = dir
                    end
    
                    if minangle < dir then
                        minangle = dir
                    end 
    
                    if not inanlge then
                        local diffDir = dir - selfDir
                        if diffDir < 0 then
                            diffDir = diffDir + 360
                        end
                        if diffDir > 180 then
                            diffDir = 360 -diffDir
                        end
    
                        if diffDir < skillInfo.Angle/2 then
                           inanlge = true 
                        end
                    end
                end
    
                if not inanlge then
                    local midangle = (minangle + maxangle) * 0.5
    
                    local diffDir = midangle - selfDir
                    if diffDir < 0 then
                        diffDir = diffDir + 360
                    end
                    if diffDir > 180 then
                        diffDir = 360 -diffDir
                    end
                   
                    if diffDir < skillInfo.Angle/2 then
                       inanlge = true 
                    end
                end
    
                if dis < skillInfo.Attack_Distance and inanlge then
                    table.insert(targets, value.id)
                end
            end
            
            --[[
            local tmpDiff = {x = 0, y = 0}
            if selfDir == 270 or selfDir == -90 then
                selfPos = cc.pSub(selfPos, {x = 0, y = -50})
            elseif selfDir == 90 then
                selfPos = cc.pSub(selfPos, {x = 0, y = 50})
            else
                local nor = cc.pNormalize({x = math.cos(selfDir), y = math.sin(selfDir)})
                selfPos = cc.pSub(selfPos, cc.pMul(nor, 50))
            end
            
            local dirVec = cc.pSub(tarPos, selfPos)
            local tarPosDir = cc.pToAngleSelf(dirVec) * 57.3

            local diffDir = tarPosDir - selfDir
            if diffDir < 0 then
                diffDir = diffDir + 360
            end

            if diffDir > 180 then
                diffDir = 360 -diffDir
            end

            if dis < skillInfo.Attack_Distance and
                diffDir < skillInfo.Angle/2
            then
                table.insert(targets, value.id)
            end      ]]
        end
    end

    if selfDir < 0 then
        selfDir = selfDir + 360
    end

    return selfDir, targets
end

function comm.getAOESkillTargets(skillID)
    local targets = {}
    
    local localPlayer = MgrPlayer[maincha.id]
    if not localPlayer then
        return 
    end
    local selfPosX, selfPosY = localPlayer:getPosition()
    local selfPos = {x = selfPosX, y = selfPosY}

    local skillInfo = TableSkill[skillID]

    if not skillInfo or skillInfo.Attack_Types ~= 1 then
        return targets
    end

    for id, value in pairs(MgrPlayer) do
        if value and value.teamid ~= localPlayer.teamid 
            and value.attr.life > 0 then
            local tarPosX, tarPosY = value:getPosition()
            local tarPos = cc.p(tarPosX, tarPosY)
            local dis = cc.pGetDistance(selfPos, tarPos)

            if dis < skillInfo.Attack_Distance then
                table.insert(targets, value.id)
            end      
        end
    end
    
    return targets
end

function comm.getJewelAttrValue(jewelID)
    local jewelInfo = TableStone[jewelID]
    local name, attr = nil, nil
    local attrIdx = ""
    if jewelInfo.Attack > 0 then
        name, attr = "攻击", jewelInfo.Attack
        attrIdx = "Attack"
    elseif jewelInfo.Defense > 0 then
        name, attr = "防御", jewelInfo.Defense
        attrIdx = "Defense"
    elseif jewelInfo.Life > 0 then
        name, attr = "生命", jewelInfo.Life
        attrIdx = "Life"
    elseif jewelInfo.Dodge > 0 then
        name, attr = "闪避", jewelInfo.Dodge
        attrIdx = "Dodge"
    elseif jewelInfo.Crit > 0 then
        name, attr = "暴击", jewelInfo.Crit
        attrIdx = "Crit"
    elseif jewelInfo.Hit > 0 then
        name, attr = "命中", jewelInfo.Hit
        attrIdx = "Hit"
    end
    return name, attr, attrIdx
end

function comm.calculateEquipAttr(attr, equipID)
    local equipInfo = TableEquipment[equipID]
    local name, value = nil, 0

    local inlayedJewel1 = bit.rshift(attr[1], 16)
    local inlayedJewel2 = bit.band(attr[1], 0x0000FFFF)
    local inlayedJewel3 = bit.rshift(attr[2], 16)
    local inlayedJewel4 = bit.band(attr[2], 0x0000FFFF)
    local stars = bit.band(attr[3], 0x0000FFFF)
    local Intensify = bit.rshift(attr[3], 16)

    local inlayedJewel = {inlayedJewel1, inlayedJewel2, 
        inlayedJewel3, inlayedJewel4}

    local attrIdx = ""
    if equipInfo then
        if equipInfo.Attack and equipInfo.Attack > 0 then
            name = "攻击"
            attrIdx = "Attack"
        elseif equipInfo.Defense and equipInfo.Defense > 0 then
            name = "防御"
            attrIdx = "Defense"
        elseif equipInfo.Life and equipInfo.Life > 0 then
            name = "生命"
            attrIdx = "Life"
        end

        local jewelValue = 0
        for i = 1, 4 do
            local jewelInfo = TableStone[inlayedJewel[i]]
            if jewelInfo and jewelInfo[attrIdx]  > 0 then
                jewelValue = jewelValue + jewelInfo[attrIdx]
            end
        end

        local a = TableIntensify[Intensify][attrIdx]
        local b = TableRising_Star[stars][attrIdx]
        value = (equipInfo[attrIdx] + a + b ) * (1 + jewelValue)
    end

    return name, value, attrIdx
end

function comm.playMusic(path, bRepeat)
    MgrSetting.curMusic = path or MgrSetting.curMusic
    if MgrSetting.bPlayMusic then
        cc.SimpleAudioEngine:getInstance():playMusic(MgrSetting.curMusic, true)
    end
end

function comm.playEffect(path)
   if MgrSetting.bPlayEffect then
        cc.SimpleAudioEngine:getInstance():playEffect(path)
    end
end

return comm