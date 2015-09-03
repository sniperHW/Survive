local UIGuide = class("UIGuide", function()
    return require("UI.UIBaseLayer").create()
end)

function UIGuide.create()
    local layer = UIGuide.new()
    return layer
end

function UIGuide:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
    self.schedulerID = nil    
    self:setLocalZOrder(60000)
end

function UIGuide:createClipNode(ceil, strTip, pos)
    if ceil then
        local box1 = ceil:getBoundingBox()        
        local circle = cc.Sprite:create("UI/guide/tutorial_circle_big.png")
        local box2 = circle:getBoundingBox()
        circle:setScale(math.min(box1.width/box2.width, box1.height/box2.height))
        local s = cc.Sprite:create("UI/guide/s.png")
        
        local moveBy = cc.MoveBy:create(0.2, {x = 20, y = -20})
        local move = moveBy:reverse()
        s:runAction(cc.RepeatForever:create(cc.Sequence:create(moveBy, move)))
        
        --circle:setAnchorPoint(ceil:getAnchorPoint())
        local posX, posY = ceil:getPosition()
        circle:setPosition(posX, posY )
        s:setPosition(posX+50, posY)
        local clipNode = cc.ClippingNode:create(ceil)
        self:addChild(clipNode)
    
        local layer = cc.LayerColor:create({r = 0, g = 0, b = 0, a = 100})
        
        clipNode:addChild(layer)
        self:addChild(s)
        clipNode:setInverted(true)
        clipNode:setAlphaThreshold(0)
        local rect = ceil:getBoundingBox()
    
        local function onTouchBegan(touch, event)
            local location = touch:getLocation()
            if cc.rectContainsPoint(rect, location) then
                return false
            end
    
            return true
        end
    
        local listener = cc.EventListenerTouchOneByOne:create()
        listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN)
        listener:setSwallowTouches(true)
        local eventDispatcher = self:getEventDispatcher()
        eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
        
        if strTip and pos then
            local lblTip = cc.Label:create()
            lblTip:setString(strTip)
            lblTip:setSystemFontSize(20)
            lblTip:setPosition(pos)
            lblTip:setColor({r = 255, g = 255, b = 0})
            self:addChild(lblTip)
        end
    else
        self:setSwallowTouch()
    end
end

function UIGuide:createWidgetGuide(node, iconPath, ingore, strTip, tipPos)
    local ceil = cc.Sprite:create(iconPath)
    local size = ceil:getContentSize()
    local posX, posY = node:getPosition()
    local pos = node:getParent():convertToWorldSpace({x = posX, y = posY})
    local s = cc.Sprite:create("UI/guide/s.png")
    if ingore then
        ceil:setPosition(pos)
        s:setPosition({x = pos.x, y = pos.y - 20})
    else
        ceil:setPosition(pos.x + size.width/2, pos.y + size.height/2)
        s:setPosition(pos.x + size.width/2, pos.y + size.height/2 - 20)
    end
    
    local moveBy = cc.MoveBy:create(0.2, {x = 20, y = -20})
    local move = moveBy:reverse()
    s:runAction(cc.RepeatForever:create(cc.Sequence:create(moveBy, move)))
    --[[
    local box1 = node:getBoundingBox()        
    local box2 = ceil:getBoundingBox()
    ceil:setScale(math.min(box1.width/box2.width, box1.height/box2.height))
]]
    local clipNode = cc.ClippingNode:create(ceil)
    self:addChild(clipNode)
    
    self:addChild(s)

    local layer = cc.LayerColor:create({r = 0, g = 0, b = 0, a = 100})
    clipNode:addChild(layer)
    clipNode:setInverted(true)
    clipNode:setAlphaThreshold(0)
    local rect = ceil:getBoundingBox()

    local function onTouchBegan(touch, event)
        local location = touch:getLocation()
        if cc.rectContainsPoint(rect, location) then
            return false
        end

        return true
    end

    local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN)
    listener:setSwallowTouches(true)
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
    
    if strTip and pos then
        local lblTip = cc.Label:create()
        lblTip:setString(strTip)
        lblTip:setSystemFontSize(20)
        lblTip:setPosition(tipPos)
        lblTip:setColor({r = 255, g = 255, b = 0})
        self:addChild(lblTip)
    end
end

return UIGuide