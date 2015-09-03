local comm = require("common.CommonFun")
local uihud = require ("UI.UIHudLayer")
local UIMessage = require "UI.UIMessage"

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
    cc.SimpleAudioEngine:getInstance():stopMusic()
    comm.playMusic("music/mainlayer.mp3", true)
    cc.SpriteFrameCache:getInstance():addSpriteFrames("UI/main/main.plist","UI/main/main.png")
    
    local backTag = 100
    local map = cc.Sprite:createWithSpriteFrameName("ditu.png")
    map:setAnchorPoint({x = 0, y = 0})
    --self:setPositionX(-300)
    self:addChild(map)
    local maps = {}
    local landGarden = cc.Sprite:createWithSpriteFrameName("GARDEN0.png")
    local backSelected = cc.Sprite:createWithSpriteFrameName("gardeN.png")
    backSelected:setPosition({x = 100, y = 90})
    backSelected:setVisible(false)
    landGarden:addChild(backSelected, -1, backTag)
    maps[1] = landGarden
    landGarden:setTag(205)
    landGarden:setPosition(240, 335)
    local rainbow = cc.Sprite:createWithSpriteFrameName("garden1.png")
    rainbow:setPosition({x = 85, y = 82.5})
    landGarden:addChild(rainbow)
    
    self.createSprite("UI/main/xiaozidw.png", {x = 105, y = 24}, {landGarden})
    self.createBMLabel("fonts/zjmxiaozi.fnt", "单人PVE", {x = 111, y = 24}, {landGarden})
    
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
    
    local iconName = cc.Sprite:createWithSpriteFrameName("1.png")
    iconName:setPosition(100,50)
    landGarden:addChild(iconName)
    map:addChild(landGarden)

    local landCar, carAni = createAniSprite("CAR%d.png", 3, 0.2)
    landCar:setTag(0)
    maps[2] = landCar
    local function radAni()
        local radTime = math.random(1, 3)
        local ac = cc.Repeat:create(carAni, math.random(1,4))
        landCar:runAction(cc.Sequence:create(cc.DelayTime:create(radTime), ac, cc.CallFunc:create(radAni)))
    end

    landCar:runAction(cc.Sequence:create(carAni,cc.CallFunc:create(radAni)))
    landCar:setPosition(395, 170)
    
    iconName = cc.Sprite:createWithSpriteFrameName("2.png")
    iconName:setPosition(240,200)
    landCar:addChild(iconName)
    
    local backSelected = cc.Sprite:createWithSpriteFrameName("CAR.png")
    backSelected:setPosition({x = 175, y = 130})
    backSelected:setVisible(false)
    landCar:addChild(backSelected, -1, backTag)
    self.createSprite("UI/main/xiaozidw.png", {x = 235, y = 160}, {landCar})
    self.createBMLabel("fonts/zjmxiaozi.fnt", "暂未开放", {x = 235, y = 160}, {landCar})

    map:addChild(landCar)

    local landAdventure = cc.Sprite:createWithSpriteFrameName("adventure.png")
    landAdventure:setTag(204)
    maps[3] = landAdventure
    landAdventure:setPosition(575, 410)
    iconName = cc.Sprite:createWithSpriteFrameName("3.png")
    iconName:setPosition(140, 80)
    landAdventure:addChild(iconName)
    self.createSprite("UI/main/xiaozidw.png", {x = 140, y = 45}, {landAdventure})
    self.createBMLabel("fonts/zjmxiaozi.fnt", "多人PVP", {x = 145, y = 45}, {landAdventure})

    map:addChild(landAdventure)    
    
    local backSelected = cc.Sprite:createWithSpriteFrameName("adventure0.png")
    backSelected:setPosition({x = 145, y = 140})
    backSelected:setVisible(false)
    landAdventure:addChild(backSelected, -1, backTag)

    local landTisk, ani = createAniSprite("tisk%d.png", 4, 0.2)
    landTisk:setTag(203)
    maps[4] = landTisk
    landTisk:runAction(cc.RepeatForever:create(ani))
    landTisk:setPosition(900, 450)
    iconName = cc.Sprite:createWithSpriteFrameName("4.png")
    iconName:setPosition(100, -10)
    landTisk:addChild(iconName)    
    self.createSprite("UI/main/xiaozidw.png", {x = 100, y = -40}, {landTisk})
    self.createBMLabel("fonts/zjmxiaozi.fnt", "多人PVE", {x = 100, y = -40}, {landTisk})
    map:addChild(landTisk)
    
    local backSelected = cc.Sprite:createWithSpriteFrameName("TISK.png")
    backSelected:setPosition({x = 115, y = 100})
    backSelected:setVisible(false)
    landTisk:addChild(backSelected, -1, backTag)

    local landAncient = cc.Sprite:createWithSpriteFrameName("ancient.png")
    landAncient:setTag(0)
    maps[5] = landAncient
    landAncient:setPosition(1140, 380)
    map:addChild(landAncient)
    
    local backSelected = cc.Sprite:createWithSpriteFrameName("ancient0.png")
    backSelected:setPosition({x = 138, y = 85})
    backSelected:setVisible(false)
    landAncient:addChild(backSelected, -1, backTag)
    
    local land, ani = createAniSprite("ancient%d.png", 4, 0.5)
    land:runAction(cc.RepeatForever:create(ani))
    land:setPosition(1140, 380)
    map:addChild(land)
    
    iconName = cc.Sprite:createWithSpriteFrameName("5.png")
    iconName:setPosition(1140, 300)
    self.createSprite("UI/main/xiaozidw.png", {x = 150, y = -20}, { landAncient})
    self.createBMLabel("fonts/zjmxiaozi.fnt", "暂未开放", {x = 150, y = -20}, {landAncient})
    map:addChild(iconName)    

    local landLive, ani = createAniSprite("live%d.png", 4, 0.15)
    landLive:setTag(206)
    maps[6] = landLive
    landLive:runAction(cc.RepeatForever:create(ani))
    landLive:setPosition(1080, 180)
    iconName = cc.Sprite:createWithSpriteFrameName("6.png")
    iconName:setPosition(200, 180)
    landLive:addChild(iconName)    
    map:addChild(landLive)
    
    local backSelected = cc.Sprite:createWithSpriteFrameName("live.png")
    backSelected:setPosition({x = 175, y = 128})
    backSelected:setVisible(false)
    landLive:addChild(backSelected, -1, backTag)
    self.createSprite("UI/main/xiaozidw.png", {x = 190, y = 150}, {landLive})
    self.createBMLabel("fonts/zjmxiaozi.fnt", "大型PVP", {x = 190, y = 150}, {landLive})
    
    local bTouchMoved = false
    local touchBeginPoint = nil
    local beginPoint = nil
    local chooseMap = nil
    local function onTouchBegan(touch, event)
        bTouchMoved = false
        local location = touch:getLocation()
        touchBeginPoint = {x = location.x, y = location.y}
        beginPoint = touchBeginPoint
        
        for key, value in pairs(maps) do
            local box = value:getBoundingBox()
            local nodePos = value:getParent():convertToNodeSpace(beginPoint)
            if cc.rectContainsPoint(box, nodePos) then
                chooseMap = value
                chooseMap:getChildByTag(backTag):setVisible(true)
                break
            end
        end
        return true
    end

    local function onTouchMoved(touch, event)
        local location = touch:getLocation()
        --cclog("onTouchMoved: %0.2f, %0.2f", location.x, location.y)
        if touchBeginPoint then
            local cx, cy = map:getPosition()
            local posX = cx + location.x - touchBeginPoint.x
            posX = math.max(math.min(0, posX), self.visibleSize.width - map:getContentSize().width)
            map:setPositionX(posX)
            touchBeginPoint = {x = location.x, y = location.y}
            if cc.pGetDistance(beginPoint,touchBeginPoint) > 20 
                and not bTouchMoved 
                and chooseMap then
                bTouchMoved = true
                chooseMap:getChildByTag(backTag):setVisible(false)
            end
        end
    end

    local function onTouchEnded(touch, event)
        if not bTouchMoved and chooseMap then
            local tag = chooseMap:getTag()
            local hud = cc.Director:getInstance():getRunningScene().hud
            if tag == 204 then
                hud:openUI("UIChoosePVP")
            elseif tag == 205 then
                local scene = require("SceneLoading").create(tag)
                cc.Director:getInstance():replaceScene(scene)
            elseif tag == 206 then
                CMD_SURVIVE_APPLY()
            elseif tag > 0 then
                CMD_ENTERMAP(tag)
            elseif tag == 0 then
                UIMessage.showMessage(Lang.LandNotOpen) 
            end
            
            if tag == 203 then               
                hud:openUI("UIWaitTeamPVE")
            end
            
            chooseMap:getChildByTag(backTag):setVisible(false)
            chooseMap = nil
            print("choose map:"..tag)
        end
    end

    local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN)
    listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED)
    listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED)
    listener:setSwallowTouches(true)
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
    
    --[[MgrGuideStep = maincha.attr.introduce_step
    local function onTalkEnd()
        local hud = cc.Director:getInstance():getRunningScene().hud
        if MgrGuideStep > maincha.attr.introduce_step then
            CMD_COMMIT_INTRODUCE_STEP(MgrGuideStep)
        end
        
        if MgrGuideStep == 0 then
            local ui = hud:openUI("UINPCTalk")
            ui:ShowTalk(1, onTalkEnd)     
        elseif MgrGuideStep == 1 then
            local ui = hud:openUI("UIGetAward")
            ui:setOnEnd(onTalkEnd)            
        elseif MgrGuideStep == 2 then
            local ui = hud:openUI("UINPCTalk")
            ui:ShowTalk(2, onTalkEnd)
        elseif MgrGuideStep == 3 then
            local scene = require("SceneLoading").create(202)
            cc.Director:getInstance():replaceScene(scene)
        elseif MgrGuideStep == 4 then
            local ui = hud:openUI("UINPCTalk")
            ui:ShowTalk(8, onTalkEnd)
        elseif MgrGuideStep == 5 then
            local ui = hud:openUI("UIGuide")
            ui:createWidgetGuide(self.btnBag, "UI/main/bag.png", false)
        elseif MgrGuideStep == 6 then
            self.showMenu()
            local ui = hud:openUI("UINewOpen")
            ui:Show("UI/main/xs.png", cc.p(self.visibleSize.width - 91, 180), onTalkEnd)
        elseif MgrGuideStep == 7 then
            hud:closeUI("UINewOpen")
            self.btnAchieve:setVisible(true)
            local ui = hud:openUI("UIGuide")
            ui:createWidgetGuide(self.btnAchieve, "UI/main/xs.png", false)
        elseif MgrGuideStep == 8 then
            local ui = hud:openUI("UINPCTalk")
            ui:ShowTalk(9, onTalkEnd)
        elseif MgrGuideStep >= 9 and MgrGuideStep <= 11 then
            local ui = hud:openUI("UIGuide")
            ui:createClipNode(maps[1])
        elseif MgrGuideStep == 12 then
            hud:closeUI("UIGuide")
            local ui = hud:openUI("UIGuide")
            ui:createWidgetGuide(self.btnSkill, "UI/main/skill.png", false)
        elseif MgrGuideStep == 13 then
            local ui = hud:openUI("UINPCTalk")
            ui:ShowTalk(11, onTalkEnd)
        elseif MgrGuideStep == 14 then
            local ui = hud:openUI("UIGuide")
            ui:createWidgetGuide(self.btnBag, "UI/main/bag.png", false)
        elseif MgrGuideStep == 15 then        
            local ui = hud:openUI("UINPCTalk")
            ui:ShowTalk(12, onTalkEnd)
        elseif MgrGuideStep == 16 then
            local scene = require("SceneLoading").create(202)
            cc.Director:getInstance():replaceScene(scene)
        elseif MgrGuideStep == 17 then
            local ui = hud:openUI("UINPCTalk")
            ui:ShowTalk(13, onTalkEnd)
        elseif MgrGuideStep == 18 then
            local ui = hud:openUI("UIGuide")
            ui:createClipNode(maps[1])
        elseif MgrGuideStep == 19 then
            local ui = hud:openUI("UIGuide")
            ui:createWidgetGuide(self.btnAchieve, "UI/main/xs.png", false)
        elseif MgrGuideStep == 20 then
            self.showMenu()
            local ui = hud:openUI("UINewOpen")
            ui:Show("UI/main/mrrw.png", cc.p(self.visibleSize.width - 91, 270), onTalkEnd)
        elseif MgrGuideStep == 21 then
            hud:closeUI("UINewOpen")
            self.btnDayMission:setVisible(true)
            local ui = hud:openUI("UINPCTalk")
            ui:ShowTalk(14, onTalkEnd)
        elseif MgrGuideStep == 22 then
            if maincha.attr.level >= 10 then
                local ui = hud:openUI("UIGuide")
                ui:createWidgetGuide(self.btnEquip, 
                    "UI/main/wax.png", false)
            end
        elseif MgrGuideStep == 23 then
            local function onEnd()
                local ui = hud:openUI("UIGuide")
                ui:createWidgetGuide(self.btnDayMission, "UI/main/mrrw.png", false)
            end
            local ui = hud:openUI("UINPCTalk")
            ui:ShowTalk(15, onEnd)
        elseif MgrGuideStep == 24 then
            if maincha.attr.level >= 20 then
                local ui = hud:openUI("UIGuide")
                ui:createWidgetGuide(self.btnHead, "yuan.png", true)
            end            
        end
        
        MgrGuideStep = MgrGuideStep + 1
    end
    
    self.UpdateGuide = onTalkEnd
    --]]
    
    local function onNodeEvent(event)
        if "enter" == event then
            onTalkEnd()
        elseif "exit" == event then
            --cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.schedulerID)
            cc.SimpleAudioEngine:getInstance():stopMusic()
            if self.onlineSchID then
                local scheduler = cc.Director:getInstance():getScheduler()
                scheduler:unscheduleScriptEntry(self.onlineSchID)
            end
        end
    end
    self:registerScriptHandler(onNodeEvent)
    
    self:createLeftTop()
    self:createRightTop()
    self:createRightBottom()
    self:createLeftBottom()
    
    self:UpdateInfo()
    self:UpdateOnline()
end

local function onHeadTouched(sender, type)
    local runScene = cc.Director:getInstance():getRunningScene()
    local hud = runScene.hud
    --hud:closeUI("UILogin")
    hud:openUI("UICharacter")
end

local function getOnlineInfo()
    local maxTime = 0
    local times = {60, 300, 600, 1800, 3600, 7200}
    for i = 16, 21 do
        if MgrAchieve and not MgrAchieve[i].awarded then
            maxTime = times[i-15]
            return maxTime, i
        end
    end

    return 0, nil
end

function UIMainLayer:UpdateOnline()
    local maxTime, achieveID = getOnlineInfo()

    if maincha.attr.online_award == 0 or maxTime == 0 then
        self.btnOnline:setVisible(false)
        self.iconOnline:setVisible(false)
        self.lblOnline:setVisible(false)
    else
        self.btnOnline:setVisible(true)
        self.iconOnline:setVisible(true)
        self.lblOnline:setVisible(true)
        
        if self.onlineSchID then
            cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.onlineSchID)
        end        
        
        local function updateOnline()
            local t = math.ceil(os.clock() - BeginTime.localtime)
            local st = maincha.attr.online_award - BeginTime.servertime
            local rt = t - st 
            rt = math.max(0, maxTime - math.max(rt, 0))
            local min = math.floor(rt/60)
            local sec = rt % 60
            local str = string.format("%02d:%02d",min, sec)
            self.lblOnline:setString(str)
        end

        self.onlineSchID = cc.Director:getInstance():getScheduler():scheduleScriptFunc(updateOnline, 1, false)
    end
end

function UIMainLayer:onUpdateAchieve()
    self:UpdateOnline()
end

function UIMainLayer:UpdateInfo()
    self.lblLevel:setString(maincha.attr.level)
    local fight = maincha.attr.attack * 2 + maincha.attr.defencse * 1.5 + maincha.attr.maxlife * 0.2
    self.lblFightValue:setString(math.ceil(fight))
    self.lblaction:setString(maincha.attr.action_force)
    self.lblpearl:setString(maincha.attr.pearl)
    self.lblshell:setString(maincha.attr.shell)
    
    local expInfo = TableExperience[maincha.attr.level]
    self.exppro:setPercentage(maincha.attr.exp/expInfo.Experience * 100)
    self.lblExp:setString(maincha.attr.exp.."/"..expInfo.Experience)
end

function UIMainLayer:createLeftTop()    
	local nodeLeftTop = cc.Node:create()
    nodeLeftTop:setPosition(0, self.visibleSize.height)	
	self:addChild(nodeLeftTop)
    
    self.createSprite("UI/main/infoBack.png", {x = 102, y = -82}, {nodeLeftTop})

    local headPath = string.format("UI/main/head%d.png",maincha.avatarid)
    self.btnHead = self.createButton{icon = headPath,
        pos = {x = 61, y = -56},
        ignore = false,
        handle = onHeadTouched,
        parent = nodeLeftTop
    }
    
    local iconVip = self.createSprite("UI/main/vip0.png", {x = 160, y = -50}, {nodeLeftTop})
    self.lblLevel = self.createBMLabel("fonts/LV.fnt", maincha.attr.level, {x = 160, y = -82}, {nodeLeftTop, {x = 0, y = 0.5}})
    local lblSelfName = self.createLabel(maincha.nickname, nil, {x = 100, y = -118}, nil, {nodeLeftTop})
    lblSelfName:setColor{r = 0, g = 0, b = 0}
    self.lblFightValue = self.createBMLabel("fonts/ZDL.fnt", maincha.attr.combat_power or 10, {x = 105, y = -150}, {nodeLeftTop, {x = 0, y = 0.5}}) 
    
    local function add(sender, event)
        print("add")
    end

    local sprite = self.createSprite("UI/character/heng.png", {x = 220 , y = -30},
        {nodeLeftTop, {x = 0, y = 0.5}})
    sprite:setScaleX(0.9)
    local bk = self.createSprite("UI/main/tl.png", {x = 250, y = -30}, {nodeLeftTop})
    self.lblaction = self.createBMLabel("fonts/tili.fnt", "75646645", {x = 111, y = 24}, {bk})        
    self.createButton{icon = "UI/common/add.png",
        pos = {x = 163, y = 9},
        handle = add,
        parent = bk
    }

    local sprite = self.createSprite("UI/character/heng.png", {x = 440, y = -30},
        {nodeLeftTop, {x = 0, y = 0.5}})
    sprite:setScaleX(0.9)
    bk = self.createSprite("UI/main/zz.png", {x = 470 , y = -30}, {nodeLeftTop})
    self.lblpearl = self.createBMLabel("fonts/tili.fnt", "75646645", {x = 111, y = 20}, {bk})        
    self.createButton{icon = "UI/common/add.png",
        pos = {x = 163, y = 3},
        handle = add,
        parent = bk
    }

    local sprite = self.createSprite("UI/character/heng.png", {x = 660, y = -30},
        {nodeLeftTop, {x = 0, y = 0.5}})
    sprite:setScaleX(0.9)
    bk = self.createSprite("UI/main/bk.png", {x = 690, y = -30}, {nodeLeftTop})
    self.lblshell = self.createBMLabel("fonts/tili.fnt", "75646645", {x = 111, y = 25}, {bk})        
    self.createButton{icon = "UI/common/add.png",
        pos = {x = 170, y = 7},
        handle = add,
        parent = bk
    }    

    local function onHDTouched(sender, event)
        local hud = cc.Director:getInstance():getRunningScene().hud
        hud:openUI("UISign")
    end
    self.createButton{icon = "UI/main/hd.png",
        pos = {x = 220, y = -120},
        handle = onHDTouched,
        parent = nodeLeftTop
    }
    self.createSprite("UI/main/hdd.png", {x = 255, y = -120}, {nodeLeftTop})
    
    local function onFirstTouched(sender, event)
    --hud:openUI("UISign")
    end
    self.createButton{icon = "UI/main/first.png",
        pos = {x = 350, y = -120},
        handle = onFirstTouched,
        parent = nodeLeftTop
    }
    self.createSprite("UI/main/sc.png", {x = 380, y = -120}, {nodeLeftTop})
    
    local function onGiftTouched(sender, event)
        local hud = cc.Director:getInstance():getRunningScene().hud
        hud:openUI("UIGetGift")
    end
    self.createButton{icon = "UI/main/gift.png",
        pos = {x = 480, y = -120},
        handle = onGiftTouched,
        parent = nodeLeftTop
    }    
    self.createSprite("UI/main/lw.png", {x = 505, y = -120}, {nodeLeftTop})
    
    local function onMailTouched(sender, event)
        local hud = cc.Director:getInstance():getRunningScene().hud
        hud:openUI("UIMail")
    end
    self.createButton{icon = "UI/main/yj.png",
        pos = {x = 600, y = -120},
        handle = onMailTouched,
        parent = nodeLeftTop
    }
    self.createSprite("UI/main/mail.png", {x = 635, y = -120}, {nodeLeftTop})    

    local function onOnlineTouched(sender, event)
        local t = math.ceil(os.clock() - BeginTime.localtime)
        local st = maincha.attr.online_award - BeginTime.servertime
        local rt = t - st 

        local maxTime, achieveID = getOnlineInfo()

        if rt >= maxTime then
            CMD_ACHIEVE_AWARD(achieveID)
        end
    end
    self.btnOnline = self.createButton{icon = "UI/main/online.png",
        pos = {x = 720, y = -120},
        handle = onOnlineTouched,
        parent = nodeLeftTop
    }
    self.iconOnline = self.createSprite("UI/main/zx.png", {x = 750, y = -120}, {nodeLeftTop})
    self.lblOnline = self.createBMLabel("fonts/zaixianjiangli.fnt", "00:00",
        {x = 750, y = -60}, {nodeLeftTop})
    self.lblOnline:setAdditionalKerning(4) 
end

function UIMainLayer:createRightTop()
    local nodeRightTop = cc.Node:create()
    nodeRightTop:setPosition(self.visibleSize.width, self.visibleSize.height)    
    self:addChild(nodeRightTop)
    
    local function onShopTouched(...)
        local hud = cc.Director:getInstance():getRunningScene().hud
        hud:openUI("UIShop")
    end
    self.createButton{icon = "UI/main/mall.png",
        pos = {x = -100, y = -100},
        handle = onShopTouched,
        parent = nodeRightTop
    }
end

function UIMainLayer:createRightBottom()
    local nodeRightButtom = cc.Node:create()
    nodeRightButtom:setPosition(self.visibleSize.width, 10)    
    self:addChild(nodeRightButtom)
    
    local funcNodeH = cc.Node:create()
    funcNodeH:setPositionY(10)
    nodeRightButtom:addChild(funcNodeH)
    
    local funcNodeV = cc.Node:create()
    funcNodeV:setPositionY(10)
    nodeRightButtom:addChild(funcNodeV)
    
    local function toggleHide(...)
        local posX, posY = funcNodeH:getPosition()
        local moveAc = nil
        if posX == 0 then
            moveAc = cc.MoveTo:create(0.3, {x = 620, y = posY})
        else
            moveAc = cc.MoveTo:create(0.3, {x = 0, y = posY})
        end
        funcNodeH:runAction(cc.EaseOut:create(moveAc, 5))
        
        posX, posY = funcNodeV:getPosition()
        if posY == -400 then
            moveAc = cc.MoveTo:create(0.3, {x = posX, y = 10})
        else
            moveAc = cc.MoveTo:create(0.3, {x = posX, y = -400})
        end
        funcNodeV:runAction(cc.EaseOut:create(moveAc, 5))
    end

    self.showMenu = function ()
        local posX, posY = funcNodeH:getPosition()
        if posX ~= 0 then
            toggleHide(nil, nil)
        end
    end

    local function onBagTouched( ... )
        local hud = cc.Director:getInstance():getRunningScene().hud
        hud:openUI("UIBag")
    end
    
    local function onEquipTouched( ... )
        local hud = cc.Director:getInstance():getRunningScene().hud
        hud:openUI("UIEquip")
    end
    
    local function onSkillTouched( ... )
        local hud = cc.Director:getInstance():getRunningScene().hud
        hud:openUI("UISkillLayer")
    end

    local toggleBtn = self.createButton{icon = "UI/main/cat.png",
        pos = {x = -88, y = 0},
        handle = toggleHide,
        parent = nodeRightButtom
    }
    local expback = self.createSprite("UI/main/expBack.png", 
        {x = -9, y = -2}, {self, {x = 0, y = 0}})
    expback:setScaleX(self.visibleSize.width/DesignSize.width)
    self.createSprite("UI/main/exp.png", {x = -5, y = 0}, {self, {x = 0, y = 0}})

    self.btnBag = self.createButton{icon = "UI/main/bag.png",
        pos = {x = -168, y = 0},
        handle = onBagTouched,
        parent = funcNodeH
    }

    self.btnEquip = self.createButton{icon = "UI/main/wax.png",
        pos = {x = -258, y = 0},
        handle = onEquipTouched,
        parent = funcNodeH
    }
    
    local function onSynthesisTouched(sender, event)
        local hud = cc.Director:getInstance():getRunningScene().hud
        hud:openUI("UISynthesis")
    end
    local toggleBtn = self.createButton{icon = "UI/main/others.png",
        pos = {x = -348, y = 0},
        handle = onSynthesisTouched,
        parent = funcNodeH
    }
    self.btnSkill = self.createButton{icon = "UI/main/skill.png",
        pos = {x = -438, y = 0},
        handle = onSkillTouched,
        parent = funcNodeH
    }
    
    local function onFirendTouched(...)
        local runScene = cc.Director:getInstance():getRunningScene()
        runScene.hud:openUI("UIFriend")
    end
    local toggleBtn = self.createButton{icon = "UI/main/friend.png",
        pos = {x = -535, y = 0},
        handle = onFirendTouched,
        parent = funcNodeH
    }

    local function onSettingTouched( ... )
        local runScene = cc.Director:getInstance():getRunningScene()
        runScene.hud:openUI("UISetting")
    end
    local toggleBtn = self.createButton{icon = "UI/main/sz.png",
        pos = {x = -618, y = 0},
        handle = onSettingTouched,
        parent = funcNodeH
    }

    local function onAchieveTouched( ... )
        local hud = cc.Director:getInstance():getRunningScene().hud
        hud:openUI("UIAchieve")
    end
    self.btnAchieve = self.createButton{icon = "UI/main/xs.png",
        pos = {x = -91, y = 120},
        handle = onAchieveTouched,
        parent = funcNodeV
    }
    self.btnAchieve:setVisible(MgrGuideStep > 6)
    
    local function onDayMissionTouched( ... )
        local hud = cc.Director:getInstance():getRunningScene().hud
        hud:openUI("UIDayMission")
        
        if MgrGuideStep == 24 then
            CMD_COMMIT_INTRODUCE_STEP(MgrGuideStep)
            hud:closeUI("UIGuide")
        end
    end
    self.btnDayMission = self.createButton{icon = "UI/main/mrrw.png",
        pos = {x = -91, y = 210},
        handle = onDayMissionTouched,
        parent = funcNodeV
    }
    self.btnDayMission:setVisible(MgrGuideStep > 20)
    
    local barSprite = cc.Sprite:create("UI/main/exppro.png")
    local exppro = cc.ProgressTimer:create(barSprite)
    exppro:setType(cc.PROGRESS_TIMER_TYPE_BAR)
    exppro:setScaleX(self.visibleSize.width/DesignSize.width)
    --exppro:setScaleX(1.3)
    exppro:setAnchorPoint(0, 0)
    exppro:setPosition(42, 1)
    exppro:setMidpoint({x = 0, y = 0.5})
    exppro:setBarChangeRate({x = 1, y = 0})
    exppro:setPercentage(60)    
    self:addChild(exppro)
    self.exppro = exppro
    
    self.lblExp = self.createBMLabel("fonts/ttt.fnt", "365464/564465", 
        {x = self.visibleSize.width/2, y = 2}, {self, {x = 0.5, y = 0}})
end

function UIMainLayer:createLeftBottom()
    local nodeLeftBottom = cc.Node:create()
    nodeLeftBottom:setPosition(0, 10)    
    self:addChild(nodeLeftBottom)
    
    self.createSprite("UI/main/ltk.png", {x = 0, y = 0}, {nodeLeftBottom,{x = 0, y = 0}})
    
    local function onChatTouched(sender, event)
        local hud = cc.Director:getInstance():getRunningScene().hud
        hud:openUI("UIChat")
    end    

    self.createButton{
        icon = "UI/main/lt.png",
        pos = {x = 0, y = 0},
        handle = onChatTouched,
        parent = nodeLeftBottom
    }    
    --self.createSprite("UI/main/lt.png", {x = 0, y = 0}, {nodeLeftBottom,{x = 0, y = 0}})
    
    local red = {r = 242, g = 154, b = 117}
    local blue = {r = 126, g = 206, b = 244}
    local lbl = self.createLabel("[世界]", 14, {x = 100, y = 60}, nil, {nodeLeftBottom})
    lbl:setColor(red)
    self.lblWorld = self.createLabel("", 14, {x = 130, y = 60}, nil, {nodeLeftBottom,{x = 0, y = 0.5}})
    self.lblWorld:setColor(red)
    --lbl = self.createLabel("5v5缺个剑，35以上的来", 14, {x = 175, y = 60}, nil, {nodeLeftBottom, {x = 0, y = 0.5}})
    lbl = self.createLabel("[私聊]", 14, {x = 80, y = 40}, 
        nil, {nodeLeftBottom,{x = 0, y = 0.5}})
    lbl:setColor(blue)
    
    self.lblPrivate = self.createLabel("", 14, {x = 130, y = 40}, nil, {nodeLeftBottom,{x = 0, y = 0.5}})
    self.lblPrivate:setColor(blue)


--[[
    local function onTextHandle(typestr)
        if typestr == "began" then
        elseif typestr == "changed" then

        elseif typestr == "ended" then
            CMD_CHAT(self.txtInput:getText())
        elseif typestr == "return" then
            self.txtInput:setText("")
        end
        --return true
    end

    self.txtInput = ccui.EditBox:create({width = 255, height = 60},
        "UI/login/txtInput.png")
        --self.createScale9Sprite("UI/login/txtInput.png", nil, {widht = 255, height = 55}, {}))
    self.txtInput:setPosition(100, 20)
    self.txtInput:setAnchorPoint(0, 0.5)
    self.txtInput:registerScriptEditBoxHandler(onTextHandle)
    nodeLeftBottom:addChild(self.txtInput)
    ]]
end

function UIMainLayer:onUpdateChat()
    if #MgrChat.World > 0 then
        local  chatInfo = MgrChat.World[#MgrChat.World]
        self.lblWorld:setString(string.format("%s:%s", chatInfo.sender, chatInfo.content))
    else
        self.lblWorld:setString("")
    end

    if #MgrChat.Private > 0 then
        local  chatInfo = MgrChat.Private[#MgrChat.Private]
        self.lblPrivate:setString(string.format("%s:%s", chatInfo.sender, chatInfo.content))
    else
        self.lblPrivate:setString("")
    end
end

return UIMainLayer