local comm = require("common.CommonFun")

local Avatar = class("Avatar", function()
    return cc.Sprite:create()
end)

function Avatar.create(avatarID, weapon)
    local sprite = Avatar.new()
    sprite.actions = {}
    sprite.delayHit = {}
    local modelID = TableAvatar[avatarID].ModelID
    local spriteShadow = cc.Sprite:create("shadow.png")  
    
    if modelID == 0 then
        local itemInfo = TableItem[TableAvatar[avatarID].Item_ID]
        local weaponNode = cc.Sprite3D:create(itemInfo.Model)
        weaponNode:setScale(itemInfo.Scale * 0.2)
        sprite:addChild(weaponNode)
        spriteShadow:setVisible(false)
        return sprite
    end
    
    local tableModel = TableModel[modelID] 
    local resPath = tableModel.Resource_Path
    local len = string.len(resPath)
    
      
    if  avatarID > 500 then
        if string.sub(resPath, len - 5, len) == ".plist" then
            local sprite2D = sprite:init2DAvatar(avatarID)
            sprite2D:setTag(EnumAvatar.Tag2D)
            sprite:addChild(sprite2D)
            spriteShadow:setVisible(false)
            sprite2D:setScale(TableAvatar[avatarID].Scale) 
            --spriteShadow:setPosition(15,-15)
        elseif string.sub(resPath, len - 3, len) == ".png" then
            local sprite2D = cc.Sprite:create(resPath)
            sprite2D:setTag(EnumAvatar.Tag2D)
            sprite:addChild(sprite2D)
            sprite2D:setScale(TableAvatar[avatarID].Scale) 
            spriteShadow:setVisible(false)
        end
        --[[
        local sprite2D = sprite:init2DAvatar(avatarID)
        sprite2D:setTag(EnumAvatar.Tag2D)
        sprite:addChild(sprite2D)
        spriteShadow:setPosition(15,-15)
        ]]
    elseif string.sub(resPath, len - 3, len) == ".c3b" then
        local sprite3D = nil
        local weaponNode = nil
        
        if weapon and weapon.id and weapon.id > 0 then
            if weapon.id > 5100 and weapon.id < 5200 then
                modelID = modelID + 1
            elseif weapon.id > 5200 and weapon.id < 5300 then
                modelID = modelID + 2
            end

            local itemInfo = TableItem[weapon.id]
            weaponNode = cc.Sprite3D:create(itemInfo.Model)
            weaponNode:setTag(EnumChildTag.Weapon)
            weaponNode:setScale(itemInfo.Scale)
        end

        sprite3D = sprite:init3DAvatar(modelID)
        sprite3D:setTag(EnumAvatar.Tag3D)
        sprite3D:setScale(TableAvatar[avatarID].Scale) 
        
        if tableModel.Material_Path then
            sprite3D:setTexture(tableModel.Material_Path)
        end

        if weaponNode then
            local attachNode = sprite3D:getAttachNode(WeaponNodeName)
            attachNode:removeChildByTag(EnumChildTag.Weapon)
            attachNode:addChild(weaponNode)
        end
        
        local spr = cc.Sprite:create()
        spr:addChild(sprite3D)
        spr:setTag(EnumAvatar.Tag3D)
        spr:setRotation3D{x = 35, y = 0, z = 0}
        sprite:addChild(spr)
        spriteShadow:setPosition(5,5)
    end

    spriteShadow:setLocalZOrder(-1)
    local scaleac = cc.ScaleBy:create(0.5, 1.1)
    spriteShadow:runAction(cc.RepeatForever:create(cc.Sequence:create(scaleac, scaleac:reverse())))
    sprite:addChild(spriteShadow)

    return sprite
end

function Avatar:ctor()
    self.schedulerID = nil
    self.playSkillAction = 0
    self.buffState = {}
    local function onTouchBegan(touch, event)
        local touchPoint = touch:getLocation()     
        local sprite = self:GetAvatar3D() or 
            self:getChildByTag(EnumAvatar.Tag2D) 
        local rect = sprite:getBoundingBox()
        local location = sprite:getParent():convertToNodeSpace(touchPoint)
        --local contain = 
        --sprite:getBoundingBox():containsPoint(avatar:convertToNodeSpace(location))
        rect = {x = rect.x / 2, y = rect.y /2, width = rect.width / 2, height = rect.height / 2}
        --[[
        if location.x > rect.x and location.x < rect.x + rect.width
        and location.y > rect.y and location.y < rect.y + rect.height then]]
        if math.abs(location.x) < 50 and location.y > 0 and location.y < 120 then
            if self.id ~= maincha.id then
                MgrFight.lockTarget = self
            end
            return true 
        end

        return false
    end
    
--[[
    local listener = cc.EventListenerTouchOneByOne:create()
    listener:setSwallowTouches(true)
    listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
]]

    local function onNodeEvent(event)
        if "enter" == event then
            self:Idle()
        elseif "exit" == event then
            --cc.Director:getInstance():getScheduler():unschedul eScriptEntry(self.schedulerID)
            --self:unregisterScriptHandler()
            
            for _, value in pairs(self.actions) do
                value:release()
            end
        end
    end
    self:registerScriptHandler(onNodeEvent)
end

function Avatar:SetWeapon(weapon)
    self.actions = {}
    self.delayHit = {}
    
    local modelID = TableAvatar[self.avatid].ModelID
    local tableModel = TableModel[modelID] 
    local sprite3D = self:GetAvatar3D()
    
    local weaponNode = nil
    if weapon and weapon.id and weapon.id > 0 then
        if weapon.id > 5100 and weapon.id < 5200 then
            modelID = modelID + 1
        elseif weapon.id > 5200 and weapon.id < 5300 then
            modelID = modelID + 2
        end

        local itemInfo = TableItem[weapon.id]
        weaponNode = cc.Sprite3D:create(itemInfo.Model)
        weaponNode:setTag(EnumChildTag.Weapon)
        weaponNode:setScale(itemInfo.Scale)
    end
    
    self:init3DAvatar(modelID)
    sprite3D:stopAllActions()
    self:stopActionByTag(EnumActionTag.ActionMove)
    
    if weaponNode then
        local attachNode = sprite3D:getAttachNode(WeaponNodeName)
        attachNode:removeChildByTag(EnumChildTag.Weapon)
        attachNode:addChild(weaponNode)
    end
    
    self:Idle()
end

function Avatar:createAction(actionID)
    if actionID < 1 then
        return nil
    end
    
    local animation = cc.Animation:create()
    local tableAction = TableAction[actionID]
    
    local frameCache = cc.SpriteFrameCache:getInstance()
    local name = ""
    for i = tableAction.Start_Frame, tableAction.End_Frame do
        name = string.format(tableAction.Resource_Path..".png", i)
        animation:addSpriteFrame(frameCache:getSpriteFrame(name))
    end
    animation:setDelayPerUnit(tableAction.Frame_Interval)
    local animate = cc.Animate:create(animation)
    
    return animate
end

function Avatar:createAction3D(actionID, animation, FrameRate)
    if actionID < 1 then
        return nil
    end
    
    local tableAction = TableAction[actionID]

    local action = cc.Animate3D:create(animation, 
        tableAction.Start_Frame/FrameRate, 
        (tableAction.End_Frame - tableAction.Start_Frame)/FrameRate)

    action:setSpeed(tableAction.Frame_Interval)
    action:setWeight(tableAction.Weight)
    return action
end

function Avatar:GetAvatar3D()
    local viewSprite = self:getChildByTag(EnumAvatar.Tag3D)
    
	if viewSprite then
        local sprite3D = viewSprite:getChildByTag(EnumAvatar.Tag3D)
        return sprite3D
	end
    return nil
end

function Avatar:Idle()
    if self.id == maincha.id and 
        MgrSetting.bJoyStickType and MgrControl.bTouchJoyStick then
        self:Walk()
        return
    end

    if self.playSkillAction == 0 
        and self:getActionByTag(EnumActionTag.ActionMove) == nil then
        
        local avatar3d = self:GetAvatar3D()
        local avatar2d = self:getChildByTag(EnumAvatar.Tag2D)
        local avatar = avatar3d or avatar2d
        --self:stopActionByTag(EnumActionTag.ActionMove)
        if avatar2d then
            avatar:stopActionByTag(EnumActionTag.State2D)
            if self.actions[EnumActions.Idle] then
                avatar:runAction(self.actions[EnumActions.Idle])
            end
        elseif avatar3d then   
            if avatar:getActionByTag(EnumActionTag.Walk) then
                avatar:stopAction(self.actions[EnumActions.Walk])
            end 
        
            if (not avatar:getActionByTag(EnumActionTag.Idle)) and
                self.playSkillAction == 0 and 
                not self.buffState[3001] then
                if self.attr and self.attr.life and self.attr.life <= 0 then
                    return
                end
                avatar:runAction(self.actions[EnumActions.Idle])
            end
        end   
    end
end

function Avatar:DelayIdle(delayTime)
    local function delayIdle()
        self:Idle()
    end
    if delayTime > 0 then
        local action = cc.Sequence:create(cc.DelayTime:create(delayTime), 
            cc.CallFunc:create(delayIdle))
        self:runAction(action)
    else
        self:Idle()
    end
end

function Avatar:Walk()
    local avatar3d = self:GetAvatar3D()
    local avatar2d = self:getChildByTag(EnumAvatar.Tag2D)
    local avatar = avatar3d or avatar2d

    if self.playSkillAction ~= 0 then
        return
    end
    
    if avatar2d then
        avatar:stopActionByTag(EnumActionTag.State2D)
        avatar:runAction(self.actions[EnumActions.Walk])
    elseif avatar3d then
        if avatar:getActionByTag(EnumActionTag.Idle) then        
            avatar:stopActionByTag(EnumActionTag.Idle)
        end

        --avatar:stopAllActions()
        if not avatar:getActionByTag(EnumActionTag.Walk) then
            avatar:runAction(self.actions[EnumActions.Walk])
        end
    end    
end

function Avatar:DelayWalk(delayTime)
    local function delayWalk()
        self:Walk()
    end
    if delayTime > 0 then
        local action = cc.Sequence:create(cc.DelayTime:create(delayTime), 
            cc.CallFunc:create(delayWalk))
        self:runAction(action)
    else
        self:Walk()
    end
end

function Avatar:Attack(actionID, endHandle)
    local avatar3d = self:GetAvatar3D()
    local avatar2d = self:getChildByTag(EnumAvatar.Tag2D)
    local avatar = avatar3d or avatar2d
    
    local function AttackEnd()
        self:Idle()
    end
    
    self:stopActionByTag(EnumActionTag.ActionMove)
    if avatar2d then
        avatar:stopActionByTag(EnumActionTag.State2D)        
        local action = self.actions[actionID]        
        local se = cc.Sequence:create(action, cc.CallFunc:create(AttackEnd,{}))
        se:setTag(EnumActionTag.State2D)
        avatar:runAction(se)
    elseif avatar3d then
        avatar:stopActionByTag(EnumActionTag.Attack3D)
        avatar:stopActionByTag(EnumActionTag.Walk)
        avatar:stopActionByTag(EnumActionTag.Hit)

        avatar:stopActionByTag(EnumActionTag.Idle)  --TODO debug
        local action = self.actions[actionID]
        local se = cc.Sequence:create(action, 
            cc.CallFunc:create(endHandle,{}))
        se:setTag(EnumActionTag.Attack3D)
        avatar3d:runAction(se)
    end
end

function Avatar:Hit(hpchandge, dropStar)
    local avatar3d = self:GetAvatar3D()
    local avatar2d = self:getChildByTag(EnumAvatar.Tag2D)
    local avatar = avatar3d or avatar2d

    if avatar2d then
        avatar:stopActionByTag(EnumActionTag.State2D)        
        local function HitEnd()
            self:Idle()
        end
        
        local action = self.actions[EnumActions.Hit]        
        local se = cc.Sequence:create(action, cc.CallFunc:create(HitEnd,{}))
        se:setTag(EnumActionTag.State2D)
        avatar:runAction(se)
    elseif avatar3d then
        if self.playSkillAction == 0 then
            if avatar:getActionByTag(EnumActions.Hit) then
                avatar:stopActionByTag(EnumActionTag.Hit)
            end
            avatar:runAction(self.actions[EnumActions.Hit])
        end
    end

    local hp = tostring(hpchandge)
    local label = cc.Label:createWithBMFont("fonts/hurt.fnt", hp, 
        cc.TEXT_ALIGNMENT_CENTER, 0, {x = 0, y = 0})
    label:setPosition({x = 0, y = 160})

    local acScaleMax = cc.ScaleTo:create(0.1, 1.5)
    local acScaleMin = cc.ScaleTo:create(0.3, 1)
    local acScale = cc.Sequence:create(acScaleMax, 
        cc.DelayTime:create(0.2), acScaleMin)
    local ac = cc.Sequence:create(cc.Spawn:create(
        cc.MoveBy:create(0.2, {x = 0, y = 30}), acScale), 
        cc.RemoveSelf:create())
    label:runAction(ac)
    self:addChild(label)
    
    if self.id ~= maincha.id then
        local box = self:GetAvatar3D():getBoundingBox()    
        local boxNodePos = self:convertToNodeSpace(cc.p(box.x,box.y))
        local sprHit = cc.Sprite:create()
        sprHit:setLocalZOrder(-1)
        local effID = 160
        local aniHit = comm.getEffAni(effID)
        sprHit:runAction(cc.Sequence:create(aniHit, cc.RemoveSelf:create()))
        sprHit:setPosition({x = boxNodePos.x+box.width*2/3, y = boxNodePos.y+box.height/2})
        self:addChild(sprHit)
    end
    
    --掉星星    
    local localPlayer = MgrPlayer[maincha.id]
    
    if dropStar then 
       local scene =  cc.Director:getInstance():getRunningScene()
        local i = math.random(1,100)
        local iconStar = nil
        if i >= 1 and i <= 10 then
            iconStar = cc.Sprite:create("xingxing.png")
            iconStar:setTag(1)
        elseif i >= 11 and i <= 20 then
            iconStar = cc.Sprite:create("xingxing2.png")
            iconStar:setTag(1)
        elseif i >= 21 and i <= 22 then
            iconStar = cc.Sprite:create("xingxingda.png")
            iconStar:setTag(15)
        elseif i >= 23 and i <= 25 then
            iconStar = cc.Sprite:create("xingxingda2.png")
            iconStar:setTag(15)
        end
        if iconStar then
            local posX, posY = self:getPosition()
            iconStar:setPosition(posX, posY+20)
            iconStar:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.FadeTo:create(0.3,180), cc.FadeTo:create(0.3,255))))
            local tarX = math.random(-80, 80)
            local tarY = math.random(-20, -100)
            local bezier = {
                cc.p(tarX, 60),
                cc.p(tarX, 20),
                cc.p(tarX, tarY),
            }
            
            local bezierForward = cc.BezierBy:create(0.8, bezier)
            
            local function insertStar()
                table.insert(scene.stars, iconStar)        
            end

            iconStar:runAction(cc.Sequence:create(bezierForward, cc.CallFunc:create(insertStar)))            
            scene.map:addChild(iconStar)
        end
    end
end

function Avatar:DelayHit(delayTime, hpchandge, dropStar)
    local function delayHit(sender, extra)
        self:Hit(extra[1], extra[2])
    end
    if delayTime > 0 then
        local action = cc.Sequence:create(cc.DelayTime:create(delayTime), 
            cc.CallFunc:create(delayHit, {hpchandge, dropStar}))
        self:runAction(action)
    else
        self:Hit(hpchandge, dropStar)
    end
end

function Avatar:Repel(tarPos, hpchandge)
    print("---------repel-----------")
    print(self:getPositionX(), self:getPositionY())
    print(tarPos.x, tarPos.y)
    local moveAction = cc.MoveTo:create(0.1, tarPos)
    local avatar3d = self:GetAvatar3D()
    if avatar3d then
        avatar3d:stopAllActions()
        
        local function onRepelEnd()
            self.playSkillAction = 0
            self:DelayIdle(0.1)
        end
        avatar3d:runAction(cc.Sequence:create(self.actions[EnumActions.Repel], cc.CallFunc:create(onRepelEnd)))
    end
    local hp = tostring(hpchandge)
    local label = cc.Label:createWithBMFont("fonts/hurt.fnt", hp, cc.TEXT_ALIGNMENT_CENTER, 0, {x = 0, y = 0})
    label:setPosition({x = 0, y = 160})

    local acScaleMax = cc.ScaleTo:create(0.1, 2)
    local acScaleMin = cc.ScaleTo:create(0.3, 1)
    local acScale = cc.Sequence:create(acScaleMax, cc.DelayTime:create(0.2), acScaleMin)
    local ac = cc.Sequence:create(cc.Spawn:create(cc.MoveBy:create(0.2, {x = 0, y = 30}), acScale), cc.RemoveSelf:create())
    label:runAction(ac)
    self:addChild(label)
    self:stopActionByTag(EnumActionTag.ActionMove)
    moveAction:setTag(EnumActionTag.ActionMove)
    self:runAction(moveAction)
end

function Avatar:Death()
    local avatar3d = self:GetAvatar3D()
    local avatar2d = self:getChildByTag(EnumAvatar.Tag2D)
    local avatar = avatar3d or avatar2d
    
    self:stopActionByTag(EnumActionTag.ActionMove)
    if avatar2d then
        avatar:stopActionByTag(EnumActionTag.State2D)        
    elseif avatar3d then
        avatar3d:stopActionByTag(EnumActionTag.Walk)
        avatar3d:stopActionByTag(EnumActionTag.Idle)
        avatar3d:stopActionByTag(EnumActionTag.Attack3D)
        avatar3d:stopActionByTag(EnumActionTag.Hit)
        print("avatar3d dead")
    end

    --self.actions[EnumActions.Death]:setWeight(0.98)
    if not avatar:getActionByTag(EnumActionTag.Death) then
        avatar:runAction(self.actions[EnumActions.Death])        
    end
end

function Avatar:WalkTo(tarPos, speed)
    self:GetAvatar3D():stopActionByTag(EnumActionTag.Attack3D)
    self.playSkillAction = 0
    local avatar = self 
    local cx, cy = avatar:getPosition()    
    local action = cc.WalkTo:create({x= cx, y = cy}, {x = tarPos.x, y = tarPos.y},27 *(100 + speed or 0)/100)
    avatar:stopActionByTag(EnumActionTag.ActionMove)
    local function onWalkEnd()
        if self.id == maincha.id then
            MgrFight.StateFighting = 0
            print("-----------walk end idle--------------")
        end        
        --cc.Director:getInstance():getTotalFrames()
        --self:stopActionByTag(EnumActionTag.ActionMove)
        self:stopActionByTag(EnumActionTag.ActionMove)
        self:DelayIdle(0.1)
    end    
    
    local se = cc.Sequence:create(action, cc.CallFunc:create(onWalkEnd,{}))
    se:setTag(EnumActionTag.ActionMove)    
    avatar:runAction(se)
    
    if not self.buffState[3001] then
        avatar:DelayWalk(0)
    end    
end

function Avatar:SetAvatarName(strName)
    if not self.lblName then
        local label = cc.Label:create()
        label:setSystemFontSize(20)
        label:setPosition(0, 145)    
        label:setHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
        self:addChild(label)            
        self.lblName = label
    end
    self.lblName:setString(strName)    
end 

function Avatar:SetLife(life, maxLife)
    if not (life and maxLife) then
        return
    end
    
    if not self.barHP then
        local path = nil
        self.barHPback = cc.Sprite:create("xxt.png")
        if self.id == maincha.id then
            path = "xxt3.png"
        else
            path = "xxt2.png"
        end
        local barSprite = cc.Sprite:create(path)
        local bar = cc.ProgressTimer:create(barSprite)
        self.barHP = bar
        bar:setType(cc.PROGRESS_TIMER_TYPE_BAR)
        --bar:setAnchorPoint(0.5, 0.5)
        bar:setPosition(0, 130)
        bar:setMidpoint({x = 0, y = 0.5})
        bar:setBarChangeRate({x = 1, y = 0})      
        self.barHPback:setPosition(0, 130)
        self:addChild(self.barHPback) 
        self:addChild(bar)    
    end
    
    local localPlayer = MgrPlayer[maincha.id]
    if localPlayer and self.teamid == localPlayer.teamid then
        self.barHP:setVisible(false)
        self.barHPback:setVisible(false)
    end
    
    local value = life/maxLife * 100
    self.barHP:setPercentage(value)    
end

function Avatar:init2DAvatar(modelID)
    local model = TableModel[modelID]
    local pathlen = string.len(model.Resource_Path)
    local img = string.sub(model.Resource_Path, 1, pathlen - 5)
    local avatar = cc.Sprite:create()
    cc.SpriteFrameCache:getInstance():addSpriteFrames(model.Resource_Path, 
            img.."png")
    if model.Standby and model.Standby > 0 then
        local action = self:createAction(model.Standby)
        self.actions[EnumActions.Idle] = cc.RepeatForever:create(action)
        self.actions[EnumActions.Idle]:setTag(EnumActionTag.State2D)
        self.actions[EnumActions.Idle]:retain()
    end
    
    if model.Attack1 and model.Attack1 > 0 then
        self.actions[EnumActions.Attack1] = self:createAction(model.Attack1)        
        self.actions[EnumActions.Attack1]:setTag(EnumActionTag.State2D)
        self.actions[EnumActions.Attack1]:retain()
    end
    
    if model.Walk and model.Walk > 0 then
        local action = self:createAction(model.Walk)
        self.actions[EnumActions.Walk] = cc.RepeatForever:create(action)
        self.actions[EnumActions.Walk]:setTag(EnumActionTag.State2D)
        self.actions[EnumActions.Walk]:retain()
    end
    
    if model.Hit and model.Hit > 0 then
        self.actions[EnumActions.Hit] = self:createAction(model.Hit)
        self.actions[EnumActions.Hit]:setTag(EnumActionTag.State2D)
        self.actions[EnumActions.Hit]:retain()
    end
    
    if model.Death and model.Death > 0 then
        self.actions[EnumActions.Death] = self:createAction(model.Death)
        self.actions[EnumActions.Death]:setTag(EnumActionTag.State2D)
        self.actions[EnumActions.Death]:retain()
    end
    
    return avatar
end

function Avatar:init3DAvatar(avatarID)
    local model = TableModel[avatarID]
    local sprite3d = cc.Sprite3D:create(model.Resource_Path)
    local animation3d = cc.Animation3D:create(model.Action_Path)
    --local animation3d = cc.Animation3D:create("animation/player/catF.c3b")

    if model.Standby > 0 then
        local action = self:createAction3D(model.Standby, animation3d, model.FrameRate)
        self.actions[EnumActions.Idle] = cc.RepeatForever:create(action)
        self.actions[EnumActions.Idle]:setTag(EnumActionTag.Idle)
        self.actions[EnumActions.Idle]:retain()
    end

    if model.Walk > 0 then
        local action = self:createAction3D(model.Walk, animation3d, model.FrameRate)        
        self.actions[EnumActions.Walk] = cc.RepeatForever:create(action)
        self.actions[EnumActions.Walk]:setTag(EnumActionTag.Walk)
        self.actions[EnumActions.Walk]:retain()
    end

    for i = EnumActions.Attack1, EnumActions.Attack3 do
        local  idxName = GetEnumName(EnumActions, i)
        if model[idxName] and model[idxName] > 0 then
            self.actions[i] = self:createAction3D(model[idxName], animation3d, model.FrameRate)
            self.actions[i]:setTag(EnumActionTag.Attack3D)
            self.actions[i]:retain()
            local tableAction = TableAction[model[idxName]]
            self.delayHit[i] = tableAction.HitDelay / (tableAction.Frame_Interval * model.FrameRate)
        end
    end

    for i = EnumActions.Skill1, EnumActions.Skill5 do
        local  idxName = GetEnumName(EnumActions, i)

        if nil ~= model[idxName] then
            self.actions[i] = self:createAction3D(model[idxName], animation3d, model.FrameRate)
            self.actions[i]:setTag(EnumActionTag.Attack3D)
            self.actions[i]:retain()
            local tableAction = TableAction[model[idxName]]
            self.delayHit[i] = tableAction.HitDelay / (tableAction.Frame_Interval * model.FrameRate)
        end
    end

    if model.Hit and model.Hit > 0 then
        self.actions[EnumActions.Hit] = self:createAction3D(model.Hit, animation3d, model.FrameRate)
        self.actions[EnumActions.Hit]:setTag(EnumActionTag.Hit)
        self.actions[EnumActions.Hit]:setWeight(0.6)
        self.actions[EnumActions.Hit]:retain()
    end

    if model.Death and model.Death > 0 then
        self.actions[EnumActions.Death] = self:createAction3D(model.Death, animation3d, model.FrameRate)
        self.actions[EnumActions.Death]:setTag(EnumActionTag.Death)
        self.actions[EnumActions.Death]:retain()
    end

    if model.Repel and model.Repel > 0 then
        self.actions[EnumActions.Repel] = self:createAction3D(model.Repel, animation3d, model.FrameRate)
        self.actions[EnumActions.Repel]:setTag(EnumActionTag.Repel)
        self.actions[EnumActions.Repel]:retain()
    end

    if model.Vertigo and model.Vertigo > 0 then
        self.actions[EnumActions.Vertigo] = self:createAction3D(model.Vertigo, animation3d, model.FrameRate)
        self.actions[EnumActions.Vertigo]:setTag(EnumActionTag.Vertigo)
        self.actions[EnumActions.Vertigo]:retain()
    end 
    
    return sprite3d
end

function Avatar:AttackPlayer(skillID, endHandle, target)
    local avatar3d = self:GetAvatar3D()
    local avatar2d = self:getChildByTag(EnumAvatar.Tag2D)
    if target then       
        local selfPosX, selfPosY = self:getPosition()
        local tarPosX, tarPosY = target:getPosition()
        
        local roY = math.deg(math.atan2(tarPosY - selfPosY, tarPosX - selfPosX)) + 90
        
        if avatar2d then
            if (_rotationY >= 0 and (_rotationY > 270 or _rotationY < 90))
                or (_rotationY < 0 or _rotationY > -90) then 
                avatar2d:setScaleX(-1)
            else
                avatar2d:setScaleX(1)
            end
        elseif avatar3d then
            local ro = avatar3d:getRotation3D()
            if math.abs(ro.y - roY) > 15 then
                avatar3d:setRotation3D({x = ro.x, y = roY, z = ro.z})
            end
        end
    end
    
    if avatar3d then
        local comm = require("common.CommonFun") 
        local sprEff = comm.getSkillEff(skillID, avatar3d:getRotation3D().y - 90)
        if sprEff then
            self:addChild(sprEff)
        end
        
        local skillInfo = TableSkill[skillID]
        
        if skillInfo.Sound and self.actions[EnumActions.Skill5] then
            local path = TableSound[skillInfo.Sound].Path
            comm.playEffect("music/"..path)
        end
    end
    self:Attack(EnumActions[TableSkill[skillID].ActionName], endHandle)
end

return Avatar