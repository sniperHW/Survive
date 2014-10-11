local Avatar = class("Avatar", function()
    return cc.Sprite:create()
end)

local function ENUM_AVATAR(cmdBegin)
    local cmd = cmdBegin
    return function() 
        cmd = cmd + 1 
        return cmd 
    end
end

local ENUM = ENUM_AVATAR(0)
EnumAvatar = EnumAvatar or {
    ["Tag3D"]       = ENUM(),
    ["Tag2D"]       = ENUM(),
}

ENUM = ENUM_AVATAR(0)
EnumActions = EnumActions or {
    ["Idle"]        = ENUM(),
    ["Walk"]        = ENUM(),
    ["Hit"]         = ENUM(),
    ["Death"]       = ENUM(),
    ["Attack1"]     = ENUM(),
    ["Attack2"]     = ENUM(),
    ["Attack3"]     = ENUM(),
}

ENUM = ENUM_AVATAR(0)
EnumActionTag = EnumActionTag or {
    ["Idle"]        = ENUM(),
    ["Walk"]        = ENUM(),
    ["Hit"]         = ENUM(),
    ["ActionMove"]  = ENUM(),       --位移action,非动作
    ["Attack3D"]    = ENUM(),       --3D专用，攻击动作不混合
    ["State2D"]     = ENUM(),       --2D专用，动作不混合
}

function Avatar.create(avatarID)
    local sprite = Avatar.new()
    sprite.actions = {}
    local resPath = Model[avatarID].Resource_Path
    local len = string.len(resPath)
    
    local spriteShadow = cc.Sprite:create("shadow.png")    
    if string.sub(resPath, len - 5, len) == ".plist" then
        local sprite2D = sprite:init2DAvatar(avatarID)
        sprite2D:setTag(EnumAvatar.Tag2D)
        sprite:addChild(sprite2D)
        spriteShadow:setPosition(15,-15)
    elseif string.sub(resPath, len - 3, len) == ".c3b" then
        local sprite3D = sprite:init3DAvatar(avatarID)
        sprite3D:setTag(EnumAvatar.Tag3D)
        sprite3D:setScale(Model[avatarID].Scale)
        sprite:addChild(sprite3D)
        spriteShadow:setPosition(5,5)
    end
    sprite:Idle()

    spriteShadow:setLocalZOrder(-1)
    local scale = cc.ScaleBy:create(0.5, 1.1)
    spriteShadow:runAction(cc.RepeatForever:create(cc.Sequence:create(scale, scale:reverse())))
    sprite:addChild(spriteShadow)

    return sprite
end

function Avatar:ctor()
    self.schedulerID = nil

    local function onTouchBegan(touch, event)
        local touchPoint = touch:getLocation()     
        local sprite = self:getChildByTag(EnumAvatar.Tag3D) or 
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

    local listener = cc.EventListenerTouchOneByOne:create()
    listener:setSwallowTouches(true)
    listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)

    local function onNodeEvent(event)
        if "exit" == event then
            --cc.Director:getInstance():getScheduler():unschedul eScriptEntry(self.schedulerID)
            --self:unregisterScriptHandler()
            
            for _, value in pairs(self.actions) do
                value:release()
            end
        end
    end
    self.schedulerID = self:registerScriptHandler(onNodeEvent)
end

function Avatar:createAction(actionID)
    if actionID < 1 then
        return nil
    end
    
    local animation = cc.Animation:create()
    local tableAction = Action[actionID]
    
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

function Avatar:createAction3D(actionID, animation)
    if actionID < 1 then
        return nil
    end
    
    local tableAction = Action[actionID]
    local frameSpeed = tableAction.Frame_Interval
    --local animation3d = cc.Animation3D:create("cat.c3b")
    local action = cc.Animate3D:create(animation, 
        tableAction.Start_Frame/24, 
        (tableAction.End_Frame - tableAction.Start_Frame)/24)

    action:setSpeed(tableAction.Frame_Interval)
    action:setWeight(tableAction.Weight)            
    return action
end

function Avatar:Idle()
    local avatar3d = self:getChildByTag(EnumAvatar.Tag3D) 
    local avatar2d = self:getChildByTag(EnumAvatar.Tag2D)
    local avatar = avatar3d or avatar2d

    avatar:stopActionByTag(EnumActionTag.ActionMove)
    if avatar2d then
        avatar:stopActionByTag(EnumActionTag.State2D)
    elseif avatar3d then
        avatar:stopActionByTag(EnumActionTag.Walk)
    end    

    local action = self.actions[EnumActions.Idle]
    avatar:runAction(action)
end

function Avatar:Walk()
    local avatar3d = self:getChildByTag(EnumAvatar.Tag3D) 
    local avatar2d = self:getChildByTag(EnumAvatar.Tag2D)
    local avatar = avatar3d or avatar2d

    if avatar2d then
        avatar:stopActionByTag(EnumActionTag.State2D)
        avatar:runAction(self.actions[EnumActions.Walk])
    elseif avatar3d then
        avatar:stopActionByTag(EnumActionTag.Idle)
        if not avatar:getActionByTag(EnumActionTag.Walk) then
            avatar:runAction(self.actions[EnumActions.Walk])
        end
    end    
end

function Avatar:Attack(actionID, endHandle)
    local avatar3d = self:getChildByTag(EnumAvatar.Tag3D) 
    local avatar2d = self:getChildByTag(EnumAvatar.Tag2D)
    local avatar = avatar3d or avatar2d
    
    local function AttackEnd()
        self:Idle()
    end
    
    if avatar2d then
        avatar:stopActionByTag(EnumActionTag.State2D)        
        local action = self.actions[actionID]        
        local se = cc.Sequence:create(action, cc.CallFunc:create(AttackEnd,{}))
        se:setTag(EnumActionTag.State2D)
        avatar:runAction(se)
    elseif avatar3d then
        avatar:stopActionByTag(EnumActionTag.Attack3D)
        local action = self.actions[actionID]
        local se = cc.Sequence:create(action, cc.CallFunc:create(endHandle,{}))
        se:setTag(EnumActionTag.Attack3D)
        avatar:runAction(se)
    end
end

function Avatar:Hit()
    local avatar3d = self:getChildByTag(EnumAvatar.Tag3D) 
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
        avatar:stopAction(self.actions[EnumActions.Hit])
        avatar:runAction(self.actions[EnumActions.Hit])
    end
end

function Avatar:Death()
    local avatar3d = self:getChildByTag(EnumAvatar.Tag3D) 
    local avatar2d = self:getChildByTag(EnumAvatar.Tag2D)
    local avatar = avatar3d or avatar2d
    
    avatar:stopActionByTag(EnumActionTag.ActionMove)
    if avatar2d then
        avatar:stopActionByTag(EnumActionTag.State2D)        
    elseif avatar3d then
        avatar:stopAction(self.actions[EnumActions.Walk])
        avatar:stopAction(self.actions[EnumActions.Idle])
        avatar:stopAction(self.actions[EnumActions.Attack])
        avatar:stopAction(self.actions[EnumActions.Hit])
    end

    self.actions[EnumActions.Death]:setWeight(0.98)
    avatar:runAction(self.actions[EnumActions.Death])        
end

function Avatar:WalkTo(tarPos)
    local avatar = self 
    local cx, cy = avatar:getPosition()
    local action = cc.WalkTo:create({x= cx, y = cy}, {x = tarPos.x, y = tarPos.y}, 20)

    local function onWalkEnd()
        self:Idle()
    end
    
    avatar:stopActionByTag(EnumActionTag.ActionMove)
    local se = cc.Sequence:create(action, cc.CallFunc:create(onWalkEnd,{}))
    se:setTag(EnumActionTag.ActionMove)    
    avatar:Walk()
    avatar:runAction(se)
end

function Avatar:SetAvatarName(strName)
    if not self.lblName then
        local label = cc.Label:create()
        label:setSystemFontSize(20)
        label:setPosition(0, 140)
        label:setHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
        self:addChild(label)    
        self.lblName = label
    end

    self.lblName:setString(strName)    
end 

function Avatar:SetLife(life, maxLife)
    if not self.barHP then
        local barSprite = cc.Sprite:create("progress.png")
        local bar = cc.ProgressTimer:create(barSprite)
        self.barHP = bar
        bar:setType(cc.PROGRESS_TIMER_TYPE_BAR)
        --bar:setAnchorPoint(0.5, 0.5)
        bar:setPosition(0, 130)
        bar:setMidpoint({x = 0, y = 0.5})
        bar:setBarChangeRate({x = 1, y = 0})        
        self:addChild(bar)    
    end
    
    local value = life/maxLife * 100
    self.barHP:setPercentage(value)    
end

function Avatar:init2DAvatar(avatarID)
    local model = Model[avatarID]
    local pathlen = string.len(model.Resource_Path)
    local img = string.sub(model.Resource_Path, 1, pathlen - 5)
    local avatar = cc.Sprite:create()
    cc.SpriteFrameCache:getInstance():addSpriteFrames(model.Resource_Path, 
            img.."png")
    if model.Standby > 0 then
        local action = self:createAction(model.Standby)
        self.actions[EnumActions.Idle] = cc.RepeatForever:create(action)
        self.actions[EnumActions.Idle]:setTag(EnumActionTag.State2D)
        self.actions[EnumActions.Idle]:retain()
    end
    
    if model.Attack1 > 0 then
        self.actions[EnumActions.Attack1] = self:createAction(model.Attack1)        
        self.actions[EnumActions.Attack1]:setTag(EnumActionTag.State2D)
        self.actions[EnumActions.Attack1]:retain()
    end
    
    if model.Walk > 0 then
        local action = self:createAction(model.Walk)
        self.actions[EnumActions.Walk] = cc.RepeatForever:create(action)
        self.actions[EnumActions.Walk]:setTag(EnumActionTag.State2D)
        self.actions[EnumActions.Walk]:retain()
    end
    
    if model.Hit > 0 then
        self.actions[EnumActions.Hit] = self:createAction(model.Hit)
        self.actions[EnumActions.Hit]:setTag(EnumActionTag.State2D)
        self.actions[EnumActions.Hit]:retain()
    end
    
    if model.Death > 0 then
        self.actions[EnumActions.Death] = self:createAction(model.Death)
        self.actions[EnumActions.Death]:setTag(EnumActionTag.State2D)
        self.actions[EnumActions.Death]:retain()
    end
    
    return avatar
end

function Avatar:init3DAvatar(avatarID)
    local model = Model[avatarID]
    local sprite3d = cc.Sprite3D:create(model.Resource_Path)
    local animation3d = cc.Animation3D:create(model.Resource_Path)

    if model.Standby > 0 then
        local action = self:createAction3D(model.Standby, animation3d)
        self.actions[EnumActions.Idle] = cc.RepeatForever:create(action)
        self.actions[EnumActions.Idle]:setTag(EnumActionTag.Idle)
        self.actions[EnumActions.Idle]:retain()
    end

    if model.Walk > 0 then
        local action = self:createAction3D(model.Walk, animation3d)
        self.actions[EnumActions.Walk] = cc.RepeatForever:create(action)
        self.actions[EnumActions.Walk]:setTag(EnumActionTag.Walk)
        self.actions[EnumActions.Walk]:retain()
    end
    
    if model.Attack1 > 0 then
        self.actions[EnumActions.Attack1] = self:createAction3D(model.Attack1, animation3d)
        self.actions[EnumActions.Attack1]:setTag(EnumActionTag.Attack3D)
        self.actions[EnumActions.Attack1]:retain()
    end

    if model.Attack2 > 0 then
        self.actions[EnumActions.Attack2] = self:createAction3D(model.Attack2, animation3d)
        self.actions[EnumActions.Attack2]:setTag(EnumActionTag.Attack3D)
        self.actions[EnumActions.Attack2]:retain()
    end
    
    if model.Attack3 > 0 then
        self.actions[EnumActions.Attack3] = self:createAction3D(model.Attack3, animation3d)
        self.actions[EnumActions.Attack3]:setTag(EnumActionTag.Attack3D)
        self.actions[EnumActions.Attack3]:retain()
    end

    if model.Hit > 0 then
        self.actions[EnumActions.Hit] = self:createAction3D(model.Hit, animation3d)
        self.actions[EnumActions.Hit]:setTag(EnumActionTag.Hit)
        self.actions[EnumActions.Hit]:retain()
    end

    if model.Death > 0 then
        self.actions[EnumActions.Death] = self:createAction3D(model.Death, animation3d)
        self.actions[EnumActions.Death]:setTag(EnumActionTag.Death)
        self.actions[EnumActions.Death]:retain()
    end
    
    return sprite3d
end

function Avatar:AttackPlayer(skillID, endHandle, target)
    local avatar3d = self:getChildByTag(EnumAvatar.Tag3D)
    local avatar2d = self:getChildByTag(EnumAvatar.Tag2D)
    if MgrFight.lockTarget then      
        
        local selfPosX, selfPosY = self:getPosition()
        local tarPosX, tarPosY = target:getPosition()
        
        local roY = math.atan2(tarPosY - selfPosY, tarPosX - selfPosX) * 54.0 + 90
        
        if avatar2d then
            if (_rotationY >= 0 and (_rotationY > 270 or _rotationY < 90))
                or (_rotationY < 0 or _rotationY > -90) then 
                avatar2d:setScaleX(-1)
            else
                avatar2d:setScaleX(1)
            end
        elseif avatar3d then
            local ro = avatar3d:getRotation3D()
            avatar3d:setRotation3D({x = ro.x, y = roY, z = ro.z})
        end
    end
    self:Attack(skillID + EnumActions["Attack1"] - 1, endHandle)
end

return Avatar