local UIMainLayer = class("UIMainLayer", function()
    return require("UI.UIBaseLayer").create()
end)

function UIMainLayer.create()
    local layer = UIMainLayer.new()
    return layer
end

function UIMainLayer:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    
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
    map:addChild(land)

    local carLand, carAni = createAniSprite("CAR%d.png", 3, 0.2)
    local function radAni()
        local radTime = math.random(1, 3)
        local ac = cc.Repeat:create(carAni, math.random(1,4))
        carLand:runAction(cc.Sequence:create(cc.DelayTime:create(radTime), ac, cc.CallFunc:create(radAni)))
    end

    carLand:runAction(cc.Sequence:create(carAni,cc.CallFunc:create(radAni)))
    carLand:setPosition(395, 170)
    map:addChild(carLand)

    land = cc.Sprite:createWithSpriteFrameName("adventure.png")
    land:setPosition(575, 410)
    map:addChild(land)    

    land, ani = createAniSprite("tisk%d.png", 4, 0.2)
    land:runAction(cc.RepeatForever:create(ani))
    land:setPosition(900, 450)
    map:addChild(land)

    land = cc.Sprite:createWithSpriteFrameName("ancient.png")
    land:setPosition(1140, 380)
    map:addChild(land)
    
    land, ani = createAniSprite("ancient%d.png", 4, 0.5)
    land:runAction(cc.RepeatForever:create(ani))
    land:setPosition(1140, 380)
    map:addChild(land)

    land, ani = createAniSprite("live%d.png", 4, 0.15)
    land:runAction(cc.RepeatForever:create(ani))
    land:setPosition(1080, 180)
    map:addChild(land)
    
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
            local cx, cy = map:getPosition()
            local posX = cx + location.x - touchBeginPoint.x
            posX = math.max(math.min(0, posX), self.visibleSize.width - map:getContentSize().width)
            map:setPositionX(posX)
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
    
    self:createLeftTop()
    self:createRightTop()
    self:createRightBottom()
    self:createLeftBottom()
end

local function onHeadTouched(sender, type)
    local runScene = cc.Director:getInstance():getRunningScene()
    local hud = runScene.hud
    --hud:closeUI("UILogin")
    hud:openUI("UICharacter")
end

local function onShopTouched(sender, type)
    print("TODO on onShopTouched")
end

local function onGiftTouched(sender, type)
    print("TODO on gift")
end

local function onActivityTouched(sender, type)
    print("TODO onActivityTouched")
end

local function onFirstPayTouched(sender, type)
    print("TODO onFirstPayTouched")
end

local function onOnlineTouched(sender, type)
    print("TODO onOnlineTouched")
end

local function onBagTouched(sender, type)
	print("TODO onBagTouched")
end

local function onEquipTouched(sender, type)
    print("TODO onEquipTouched")
end

local function onSkillTouched(sender, type)
    print("TODO onSkillTouched")
end

local function onLifeTouched(sender, type)
    print("TODO onLifeTouched")
end

local function onFriendTouched(sender, type)
    print("TODO onFriendTouched")
end

local function onSystemTouched(sender, type)
    print("TODO onSystemTouched")
end

function UIMainLayer:createLeftTop()    
	local nodeLeftTop = cc.Node:create()
    nodeLeftTop:setPosition(0, self.visibleSize.height)	
	self:addChild(nodeLeftTop)
    
    self.createSprite("UI/main/infoBack.png", {x = 102, y = -82}, {nodeLeftTop})
    local iconHead = self.createSprite("UI/main/CATF.png", {x = 61, y = -56}, {nodeLeftTop})
    local iconVip = self.createSprite("UI/main/vip0.png", {x = 160, y = -50}, {nodeLeftTop})
    local lblLevel = self.createBMLabel("fonts/LV.fnt", "36", {x = 160, y = -82}, {nodeLeftTop, {x = 0, y = 0.5}})
    local lblSelfName = self.createLabel("番茄青椒土豆丝", nil, {x = 100, y = -118}, nil, {nodeLeftTop})
    local lblFightValue = self.createBMLabel("fonts/ZDL.fnt", "23145656", {x = 105, y = -150}, {nodeLeftTop, {x = 0, y = 0.5}}) 
    
    local function add(sender, event)
        print("add")
    end
    
    for i = 1, 3 do
        local bk = self.createSprite("UI/main/bk.png", {x = 100 + 220 * i , y = -30}, {nodeLeftTop})
        local lbl = self.createBMLabel("fonts/tili.fnt", "75646645", {x = 111, y = 22}, {bk})        
        self.createButton{icon = "UI/main/add.png",
            pos = {x = 170, y = 3},
            handle = add,
            parent = bk
        }
        --bk:addChild(lbl)
    end
    
    self.createButton{icon = "UI/main/hd.png",
        pos = {x = 220, y = -120},
        handle = add,
        parent = nodeLeftTop
    }
    
    self.createButton{icon = "UI/main/online.png",
        pos = {x = 350, y = -120},
        handle = add,
        parent = nodeLeftTop
    }
    
    self.createButton{icon = "UI/main/first.png",
        pos = {x = 520, y = -120},
        handle = add,
        parent = nodeLeftTop
    }
    
    self.createButton{icon = "UI/main/gift.png",
        pos = {x = 670, y = -120},
        handle = add,
        parent = nodeLeftTop
    }
    
end

function UIMainLayer:createRightTop()
    local nodeRightTop = cc.Node:create()
    nodeRightTop:setPosition(self.visibleSize.width, self.visibleSize.height)    
    self:addChild(nodeRightTop)
    
    self.createButton{icon = "UI/main/mall.png",
        pos = {x = -100, y = -100},
        handle = add,
        parent = nodeRightTop
    }
end

function UIMainLayer:createRightBottom()
    local nodeRightButtom = cc.Node:create()
    nodeRightButtom:setPosition(self.visibleSize.width, 10)    
    self:addChild(nodeRightButtom)
    
    local funcNode = cc.Node:create()
    funcNode:setPositionY(10)
    nodeRightButtom:addChild(funcNode)
    
    local function toggleHide(sender, event)
        local posX, posY = funcNode:getPosition()
        local moveAc = nil
        if posX == 0 then
            moveAc = cc.MoveTo:create(0.3, {x = 620, y = posY})
        else
            moveAc = cc.MoveTo:create(0.3, {x = 0, y = posY})
        end
        funcNode:runAction(cc.EaseOut:create(moveAc, 5))
    end
    
    local toggleBtn = self.createButton{icon = "UI/main/cat.png",
        pos = {x = -88, y = 0},
        handle = toggleHide,
        parent = nodeRightButtom
    }
    self.createSprite("UI/main/expBack.png", {x = -9, y = 0}, {self, {x = 0, y = 0}})
    self.createSprite("UI/main/exp.png", {x = 0, y = 0}, {self, {x = 0, y = 0}})    


    local toggleBtn = self.createButton{icon = "UI/main/bag.png",
        pos = {x = -168, y = 0},
        handle = toggleHide,
        parent = funcNode
    }

    local toggleBtn = self.createButton{icon = "UI/main/wax.png",
        pos = {x = -258, y = 0},
        handle = toggleHide,
        parent = funcNode
    }
    local toggleBtn = self.createButton{icon = "UI/main/others.png",
        pos = {x = -348, y = 0},
        handle = toggleHide,
        parent = funcNode
    }
    local toggleBtn = self.createButton{icon = "UI/main/skill.png",
        pos = {x = -438, y = 0},
        handle = toggleHide,
        parent = funcNode
    }
    local toggleBtn = self.createButton{icon = "UI/main/friend.png",
        pos = {x = -535, y = 0},
        handle = toggleHide,
        parent = funcNode
    }
    
    local toggleBtn = self.createButton{icon = "UI/main/sz.png",
        pos = {x = -618, y = 0},
        handle = toggleHide,
        parent = funcNode
    }
    
    local barSprite = cc.Sprite:create("UI/main/exppro.png")
    local exppro = cc.ProgressTimer:create(barSprite)
    exppro:setType(cc.PROGRESS_TIMER_TYPE_BAR)
    --exppro:setScaleX(920/586)
    exppro:setAnchorPoint(0, 0)
    exppro:setPosition(55, 0)
    exppro:setMidpoint({x = 0, y = 0.5})
    exppro:setBarChangeRate({x = 1, y = 0})
    exppro:setPercentage(60)    
    self:addChild(exppro)
    
    self.createBMLabel("fonts/ttt.fnt", "365464/564465", {x = 480, y = 0}, {self, {x = 0.5, y = 0}})
end

function UIMainLayer:createLeftBottom()
    local nodeLeftBottom = cc.Node:create()
    nodeLeftBottom:setPosition(0, 10)    
    self:addChild(nodeLeftBottom)
    
    self.createSprite("UI/main/ltk.png", {x = 0, y = 0}, {nodeLeftBottom,{x = 0, y = 0}})
    self.createSprite("UI/main/lt.png", {x = 0, y = 0}, {nodeLeftBottom,{x = 0, y = 0}})
    
    local red = {r = 242, g = 154, b = 117}
    local blue = {r = 126, g = 206, b = 244}
    local lbl = self.createLabel("[世界]", 14, {x = 100, y = 60}, nil, {nodeLeftBottom})
    lbl:setColor(red)
    lbl = self.createLabel("卡杰尔：", 14, {x = 150, y = 60}, nil, {nodeLeftBottom})
    lbl:setColor(blue)
    lbl = self.createLabel("5v5缺个剑，35以上的来", 14, {x = 175, y = 60}, nil, {nodeLeftBottom, {x = 0, y = 0.5}})
    lbl = self.createLabel("[私聊]jeenza：你今天飞车岛刷了没", 14, {x = 80, y = 40}, nil, {nodeLeftBottom,{x = 0, y = 0.5}})
    lbl:setColor(red)
end

return UIMainLayer