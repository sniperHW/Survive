--require "cocos2d"

local UIBaseLayer = class("UIBaseLayer", function ()
    return cc.Layer:create()
end)
  
function UIBaseLayer.create()
    local layer = UIBaseLayer.new() 

    return layer
end 

function UIBaseLayer:setSwallowTouch()
    local function onTouchBegan(touch, event)
        return true
    end

    local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN)
    listener:setSwallowTouches(true)
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
end

function UIBaseLayer:createBack()
    local function onBtnCloseTouched(sender, type)
        cc.Director:getInstance():getRunningScene().hud:closeUI(self.class.__cname)
    end
 
    local size = self.visibleSize
    self.back = cc.Sprite:create("UI/common/bg.png")
    self.back:setAnchorPoint(0, 0)

    self.nodeMid = cc.Node:create()
    self.nodeMid:setPositionX((self.visibleSize.width - DesignSize.width)/2)
    self:addChild(self.nodeMid)
    if self.visibleSize.width/self.visibleSize.height < 1.5 then
        self.nodeMid:setScale(0.9)
        self.nodeMid:setPositionX(0)
    end
    self.nodeMid:addChild(self.back)
    
    self.btnClose = self.createButton{pos = {x = 805, y = 510},
        icon = "UI/common/close.png",
        handle = onBtnCloseTouched,
        parent = self.nodeMid}
    self.btnClose:setLocalZOrder(1)
    --self.back:setScaleX(self.visibleSize.width/960)
end

--[[extra 
argu1 parent
argu2 anchorPos
--]]

function UIBaseLayer.createLabel(content, fontSize, pos, aligh, extra, demen)
	local label = cc.Label:create()
    if demen then
        label:setDimensions(demen.width, demen.height)
    end
	label:setString(content)
    label:setSystemFontSize(fontSize or 20)
    label:setPosition(pos)
    label:setHorizontalAlignment(aligh or cc.TEXT_ALIGNMENT_LEFT)
    for idx, v in pairs(extra) do
        if idx == 1 then
            v:addChild(label)
        end
        if idx == 2 then
            label:setAnchorPoint(v) 
        end
    end

    return label
end

function UIBaseLayer.createBMLabel(font, content, pos, extra)
    local label = cc.Label:createWithBMFont(font, content, cc.TEXT_ALIGNMENT_LEFT, 0, {x = 0, y = 0})
    label:setPosition(pos)
    
    for idx, v in pairs(extra) do
        if idx == 1 then
            v:addChild(label)
        end
        if idx == 2 then
            label:setAnchorPoint(v) 
        end
    end
    
    return label
end

function UIBaseLayer.createSprite(file, pos, extra)
    local sprite = cc.Sprite:create(file)
    sprite:setPosition(pos)
    
    for idx, v in pairs(extra) do
        if idx == 1 then
            v:addChild(sprite)
        end
        if idx == 2 then
            sprite:setAnchorPoint(v) 
        end
    end
    return sprite
end

function UIBaseLayer.createScale9Sprite(file, pos, perSize, extra)
    local sprite9 = ccui.Scale9Sprite:create(file)
    sprite9:setPosition(pos or {x = 0, y = 0})
    sprite9:setAnchorPoint(0, 0)
    sprite9:setPreferredSize(perSize)
    
    for idx, v in pairs(extra) do
        if idx == 1 then
            v:addChild(sprite9)
        end
        if idx == 2 then
            sprite9:setAnchorPoint(v) 
        end
    end

    return sprite9
end

--[[
title default ""
font  default ""
pos
fontSize default 20
ignore -ignoreAnchorPointForPosition default true
icon 
handle 
parent default nil
--]]
function UIBaseLayer.createButton(btnopt)
    local btn = cc.ControlButton:create(btnopt.title or "", 
                                        btnopt.font or "", 
                                        btnopt.fontSize or 20)
    btn:ignoreAnchorPointForPosition(btnopt.ignore == nil or btnopt.ignore == true)                                        
    btn:setPosition(btnopt.pos)
    if btnopt.icon then
        local texture = cc.Director:getInstance():getTextureCache():addImage(btnopt.icon)
        btn:setPreferredSize(texture:getContentSize())
        btn:setBackgroundSpriteForState(ccui.Scale9Sprite:create(btnopt.icon), 
                                            cc.CONTROL_STATE_NORMAL)
    end
    
    if btnopt.handle then
        btn:registerControlEventHandler(btnopt.handle, cc.CONTROL_EVENTTYPE_TOUCH_UP_INSIDE)
    end

    if btnopt.parent then
        btnopt.parent:addChild(btn)
    end
    return btn
end

return UIBaseLayer
   