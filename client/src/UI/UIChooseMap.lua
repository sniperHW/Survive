local UIChooseMap = class("UIChooseMap", function()
    return require("UI.UIBaseLayer").create()
end)

function UIChooseMap.create()
    local layer = UIChooseMap.new()
    return layer
end

function UIChooseMap:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
    self.schedulerID = nil
    --print("init ui choose map")
--[[    
    local texture = cc.Director:getInstance():getTextureCache():addImage("Main.png")
    local back = cc.Sprite:createWithTexture(texture)
    back:setAnchorPoint(0, 0)
    self:addChild(back)
]]    
    local function createAniSprite(str, count, delay)
        local spr = cc.Sprite:createWithSpriteFrameName(string.format(str,1))

        local frameCache = cc.SpriteFrameCache:getInstance()
        local name = ""
        local animation = cc.Animation:create()
        for i = 1, count do
            name = string.format(str, i)
            local frame = frameCache:getSpriteFrame(name)
            animation:addSpriteFrame(frame)
        end
        animation:setDelayPerUnit(delay)
        local animate = cc.Animate:create(animation)
        --spr:runAction(cc.RepeatForever:create(animate))
        return spr, animate
    end
    
    cc.SpriteFrameCache:getInstance():addSpriteFrames("UI/main/main.plist","UI/main/main.png")
    
    local map = cc.Sprite:createWithSpriteFrameName("ditu.png")
    map:setAnchorPoint({x = 0, y = 0})
    --self:setPositionX(-300)
    self:addChild(map)
--[[
    local land, ani = createAniSprite("GARDEN%d.png", 3, 0.25)
    land:runAction(cc.RepeatForever:create(ani))
    ]]
    local land = cc.Sprite:createWithSpriteFrameName("GARDEN0.png")
    land:setPosition(240, 335)
    local rainbow = cc.Sprite:createWithSpriteFrameName("garden1.png")
    rainbow:setPosition({x = 85, y = 82.5})
    land:addChild(rainbow)
    local function rainbowAni()
        local ac0 = cc.FadeTo:create(math.random(3, 6), math.random(50, 80))   
        local dealy0 = cc.DelayTime:create(math.random(2,5))   
        local ac1 = cc.FadeTo:create(math.random(3,6), math.random(200, 255))
        local radTime = math.random(10, 30)
        rainbow:runAction(cc.Sequence:create(cc.DelayTime:create(radTime), 
                            cc.Sequence:create(ac0, dealy0, ac1), 
                            cc.CallFunc:create(rainbowAni)))
    end
    rainbowAni()
    self:addChild(land)

    local carLand, carAni = createAniSprite("CAR%d.png", 3, 0.2)
    local function radAni()
        local radTime = math.random(1, 3)
        local ac = cc.Repeat:create(carAni, math.random(1,4))
        carLand:runAction(cc.Sequence:create(cc.DelayTime:create(radTime), ac, cc.CallFunc:create(radAni)))
    end

    carLand:runAction(cc.Sequence:create(carAni,cc.CallFunc:create(radAni)))
    carLand:setPosition(395, 170)
    self:addChild(carLand)

    land = cc.Sprite:createWithSpriteFrameName("adventure.png")
    land:setPosition(575, 410)
    self:addChild(land)    

    land, ani = createAniSprite("tisk%d.png", 4, 0.2)
    land:runAction(cc.RepeatForever:create(ani))
    land:setPosition(900, 450)
    self:addChild(land)

    land = cc.Sprite:createWithSpriteFrameName("ancient.png")
    land:setPosition(1140, 380)
    self:addChild(land)
    
    land, ani = createAniSprite("ancient%d.png", 4, 0.5)
    land:runAction(cc.RepeatForever:create(ani))
    land:setPosition(1140, 380)
    self:addChild(land)

    land, ani = createAniSprite("live%d.png", 4, 0.15)
    land:runAction(cc.RepeatForever:create(ani))
    land:setPosition(1080, 180)
    self:addChild(land)
    
    local bTouchMoved = false
    local touchBeginPoint = nil
    local function onTouchBegan(touch, event)
        bTouchMoved = false
        local location = touch:getLocation()
        touchBeginPoint = {x = location.x, y = location.y}
        --CMD_ENTERMAP(1)
        return true
    end
    
    local function onTouchMoved(touch, event)
        bTouchMoved = true
        
        local location = touch:getLocation()
        --cclog("onTouchMoved: %0.2f, %0.2f", location.x, location.y)
        if touchBeginPoint then
            local cx, cy = self:getPosition()
            local posX = cx + location.x - touchBeginPoint.x
            posX = math.max(math.min(0, posX), self.visibleSize.width - map:getContentSize().width)
            self:setPositionX(posX)
            touchBeginPoint = {x = location.x, y = location.y}
        end
    end
    
    local function onTouchEnded(touch, event)
        if not bTouchMoved then
            CMD_ENTERMAP(1)
        end
    end
    
    local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
    listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
    listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
end
    
return UIChooseMap