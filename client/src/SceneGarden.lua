--region SceneGarden.lua
local netCmd = require "src.net.NetCmd"
local UIMessage = require "UI.UIMessage"
local comm = require("common.CommonFun")

local SceneGarden = class("SceneGarden",function()
    return cc.Scene:create()
end)

function SceneGarden.create()
    local scene = SceneGarden.new()
    return scene
end

local stateFish = 1
local stateGather = 2
local stateSit = 3
local statePVE = 4
local stateIdle = 5
local curState = stateIdle

function SceneGarden:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
    self.schedulerID = nil
    self.localPlayer = nil
    
    self.flowers = {}

    local mapInfo = TableMap[205]
    local sprMap = cc.Sprite:create("Scene/garden.png")
    
    comm.playMusic(mapInfo.Music,true)
    sprMap:setAnchorPoint({x = 0, y = 0})
    InitAstar("Scene/garden.meta")
    self.map = sprMap
    self:addChild(self.map)
    self:makeFlowers()
   
    local spr = cc.Sprite:create()
    local ani = comm.getEffAni(150)
    spr:runAction(cc.RepeatForever:create(ani))
    spr:setScale(2)
    spr:setPosition(460,130)
    self.map:addChild(spr)
    
    self.hud = require("UI.UIHudLayer").create()
    self:addChild(self.hud, 1)
--[[
    maincha = {}
    maincha.avatarid = 2
    maincha.id = 123
    maincha.name = "七-个字"
    maincha.nickname = "左奇才"
    maincha.attr = {life = 90, maxlife = 100, level = 10}
]]
    local player = require("Avatar").create(maincha.avatarid, nil)
    player.id = maincha.id
    player.avatid = maincha.avatarid

    player.name = maincha.nickname
    player.attr = maincha.attr
    player.attr = nil
    player:SetAvatarName(player.name) 
    player:SetLife(100, 100)
    player:setPosition({x = 900, y = 300})
    player:retain()
    self.map:addChild(player)
    self.localPlayer = player

    local viseSize = cc.Director:getInstance():getVisibleSize()
    local mapSize = self.map:getContentSize()

    self.hud = require("UI.UIHudLayer").create()
    self:addChild(self.hud, 1)

    local function onBtnBackTouched(sender, event)
        local running = cc.Director:getInstance():getRunningScene()
        local scene = require("SceneLogin").create()
        cc.Director:getInstance():replaceScene(scene)
        scene.hud:closeUI("UILogin")
        scene.hud:openUI("UIMainLayer")
        MgrPlayer = {}
    end
    
    local function onBtnTouched(sender, event)
        if curState == stateIdle or curState == statePVE then
            if sender == self.btnFish then
                CMD_HOMEACTION(stateFish)
            elseif sender == self.btnGather then
                CMD_HOMEACTION(stateGather)
            elseif sender == self.btnSit then
                CMD_HOMEACTION(stateSit)
            elseif sender == self.btnPVE then
                curState = statePVE
                self:walkTo({x = 55, y = 105})    
            end
        else
            if sender == self.btnFish then
                if curState == stateFish then
                    require("UI.UIPopup").Popup("是否取消钓鱼？",
                        stateFish, EnumPopupType.cancelGarden) 
                    --CMD_HOMEBALANCE(stateFish)
                else
                    UIMessage.showMessage(Lang.Hooking)    
                end
            elseif sender == self.btnGather then
                if curState == stateGather then
                    require("UI.UIPopup").Popup("是否取消采集？", 
                        stateGather, EnumPopupType.cancelGarden) 
                else
                    UIMessage.showMessage(Lang.Hooking)    
                end
            elseif sender == self.btnSit then
                if curState == stateSit then
                    require("UI.UIPopup").Popup("是否取消打坐？", 
                        stateSit, EnumPopupType.cancelGarden) 
                else
                    UIMessage.showMessage(Lang.Hooking)    
                end
            elseif sender == self.btnPVE then
                curState = statePVE
                --self:WalkTo()    
            end
        end

        self:UpdateBtnState()
    end

    if maincha.attr.fishing_start and maincha.attr.fishing_start > 0 then
        self:walkTo({x = 87, y = 53})
        curState = stateFish
    elseif maincha.attr.gather_start and maincha.attr.gather_start > 0 then
        self:walkTo(self.flowers[1].pos)
        curState = stateGather
    elseif maincha.attr.sit_start and maincha.attr.sit_start > 0 then
        self:walkTo({x = 170, y = 35})
        curState = stateSit
    end

    local vWidth, vHeight = self.visibleSize.width,  self.visibleSize.height
    require("UI.UIBaseLayer").createButton({
        pos = {x = vWidth-80, y = vHeight-90},
        icon = "UI/fight/back.png",
        handle = onBtnBackTouched,
        parent = self.hud
    })
    
    self.btnFish = require("UI.UIBaseLayer").createButton({
        pos = {x = vWidth-130, y = vHeight-210},
        icon = "UI/Garden/dy.png",
        handle = onBtnTouched,
        parent = self.hud
    })
    
    self.btnGather = require("UI.UIBaseLayer").createButton({
        pos = {x = vWidth-130, y = vHeight-330},
        icon = "UI/Garden/cj.png",
        handle = onBtnTouched,
        parent = self.hud
    })
    
    self.btnSit = require("UI.UIBaseLayer").createButton({
        pos = {x = vWidth-130, y = vHeight-450},
        icon = "UI/Garden/dz.png",
        handle = onBtnTouched,
        parent = self.hud
    })
    
    self.btnPVE = require("UI.UIBaseLayer").createButton({
        pos = {x = vWidth-150, y = vHeight-620},
        icon = "UI/Garden/wdd.png",
        handle = onBtnTouched,
        parent = self.hud
    })
    
    local spr = cc.Sprite:create()
    local ani = comm.getEffAni(151)
    spr:runAction(cc.RepeatForever:create(ani))
    spr:setScale(2)
    spr:setPosition(70,80)
    self.btnPVE:addChild(spr)

    local updateMakeTime = 60
    local function tick(detal)
        if self.localPlayer then
            local cx, cy = self.map:getPosition()            
            local px, py = self.localPlayer:getPosition()
            local mapMid = self.map:convertToWorldSpace({x = px, y = py})
            local posX = math.min(0, 
                math.max(viseSize.width - mapSize.width, cx + viseSize.width / 2 - mapMid.x))
            local posY = 
                math.min(math.max(viseSize.height - mapSize.height, 
                    cy + viseSize.height / 2 - mapMid.y), 0)
            self.map:setPosition(posX, posY)
            local dis = cc.pGetDistance({x = px, y = py}, {x = 460, y = 130})
            if dis < 50 then
                CMD_ENTERMAP(202)
            end
        else
        --print("**********no local player**************")            
        end

        local children = self.map:getChildren()
        for _, value in ipairs(children) do
            local zorder = math.ceil(value:getPositionY())
            --print(zorder)
            value:setLocalZOrder(mapSize.height - zorder)
        end

        updateMakeTime = updateMakeTime + detal
        if updateMakeTime >= 3 then
            self:UpdateMakeInfo()
            updateMakeTime = 0
        end
    end

    self.schedulerID = cc.Director:getInstance():getScheduler():scheduleScriptFunc(tick, 0, false)

    -- handing touch events
    local touchBeginPoint = nil
    local function onTouchBegan(touch, event)
        if curState ~= stateIdle and curState ~= statePVE then
            UIMessage.showMessage(Lang.Hooking)
            return
        end
        local location = touch:getLocation()        
        local mapPos = self.map:convertToNodeSpace(location)
        local tilePos = cc.WalkTo:map2TilePos(mapPos)
        --self.localPlayer:WalkTo(tilePos)
        self:walkTo(tilePos)
        if curState ~= stateIdle then
            CMD_HOMEBALANCE(curState)
        end
        curState = stateIdle
        return true
    end

    local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)

    local function onNodeEvent(event)
        if "exit" == event then
            cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.schedulerID)
            cc.SimpleAudioEngine:getInstance():stopMusic()
        end
    end
    self:registerScriptHandler(onNodeEvent)

    self:createUI()
    --self:OpenResult()
    self:UpdateBtnState()
end

function SceneGarden:createUI()
    local nodeLeftTop = cc.Node:create()
    nodeLeftTop:setPosition(0, self.visibleSize.height) 
    self:addChild(nodeLeftTop)

    local baseLayer = require("UI.UIBaseLayer")
    baseLayer.createSprite("UI/main/infoBack.png", {x = 102, y = -82}, {nodeLeftTop})

    local headPath = string.format("UI/main/head%d.png",maincha.avatarid)
    baseLayer.createSprite(headPath, {x = 61, y = -56}, {nodeLeftTop})

    local iconVip = baseLayer.createSprite("UI/main/vip0.png", {x = 160, y = -50}, {nodeLeftTop})
    self.lblLevel = baseLayer.createBMLabel("fonts/LV.fnt", maincha.attr.level, {x = 160, y = -82}, {nodeLeftTop, {x = 0, y = 0.5}})
    local lblSelfName = baseLayer.createLabel(maincha.nickname, nil, {x = 100, y = -118}, nil, {nodeLeftTop})
    self.lblFightValue = baseLayer.createBMLabel("fonts/ZDL.fnt", maincha.attr.combat_power or 10, {x = 105, y = -150}, {nodeLeftTop, {x = 0, y = 0.5}}) 

    local function add(sender, event)
        print("add")
    end
    
    local sprite = baseLayer.createSprite("UI/character/heng.png", {x = 220 , y = -30},
        {nodeLeftTop, {x = 0, y = 0.5}})
    sprite:setScaleX(0.9)
    local bk = baseLayer.createSprite("UI/main/tl.png", {x = 250, y = -30}, {nodeLeftTop})
    self.lblaction = baseLayer.createBMLabel("fonts/tili.fnt", "75646645", {x = 111, y = 24}, {bk})        
    baseLayer.createButton{icon = "UI/common/add.png",
        pos = {x = 163, y = 9},
        handle = add,
        parent = bk
    }

    local sprite = baseLayer.createSprite("UI/character/heng.png", {x = 440, y = -30},
        {nodeLeftTop, {x = 0, y = 0.5}})
    sprite:setScaleX(0.9)
    bk = baseLayer.createSprite("UI/main/bk.png", {x = 470 , y = -30}, {nodeLeftTop})
    self.lblshell = baseLayer.createBMLabel("fonts/tili.fnt", "75646645", {x = 111, y = 24}, {bk})        
    baseLayer.createButton{icon = "UI/common/add.png",
        pos = {x = 163, y = 7},
        handle = add,
        parent = bk
    }

    local sprite = baseLayer.createSprite("UI/character/heng.png", {x = 660, y = -30},
        {nodeLeftTop, {x = 0, y = 0.5}})
    sprite:setScaleX(0.9)
    bk = baseLayer.createSprite("UI/main/zz.png", {x = 690, y = -30}, {nodeLeftTop})
    self.lblpearl = baseLayer.createBMLabel("fonts/tili.fnt", "75646645", {x = 111, y = 20}, {bk})        
    baseLayer.createButton{icon = "UI/common/add.png",
        pos = {x = 170, y = 3},
        handle = add,
        parent = bk
    }
    
    local nodeLeftBottom = cc.Node:create()
    nodeLeftBottom:setPosition(0, 10)    
    self:addChild(nodeLeftBottom)

    baseLayer.createSprite("UI/main/ltk.png", {x = 0, y = 0}, {nodeLeftBottom,{x = 0, y = 0}})
    baseLayer.createSprite("UI/main/lt.png", {x = 0, y = 0}, {nodeLeftBottom,{x = 0, y = 0}})

    local red = {r = 242, g = 154, b = 117}
    local blue = {r = 126, g = 206, b = 244}
    local lbl = baseLayer.createLabel("[世界]", 14, {x = 100, y = 60}, nil, {nodeLeftBottom})
    lbl:setColor(red)
    lbl = baseLayer.createLabel("卡杰尔：", 14, {x = 150, y = 60}, nil, {nodeLeftBottom})
    lbl:setColor(blue)
    lbl = baseLayer.createLabel("5v5缺个剑，35以上的来", 14, {x = 175, y = 60}, nil, {nodeLeftBottom, {x = 0, y = 0.5}})
    lbl = baseLayer.createLabel("[私聊]jeenza：你今天飞车岛刷了没", 14, {x = 80, y = 40}, nil, {nodeLeftBottom,{x = 0, y = 0.5}})
    lbl:setColor(red)
    
    local expback = baseLayer.createSprite("UI/main/expBack.png", 
        {x = -9, y = -2}, {self, {x = 0, y = 0}})
    expback:setScaleX(self.visibleSize.width/DesignSize.width)
    baseLayer.createSprite("UI/main/exp.png", {x = -5, y = 0}, {self, {x = 0, y = 0}})
    
    local barSprite = cc.Sprite:create("UI/main/exppro.png")
    local exppro = cc.ProgressTimer:create(barSprite)
    exppro:setType(cc.PROGRESS_TIMER_TYPE_BAR)
    --exppro:setScaleX(self.visibleSize.width/DesignSize.width)
    exppro:setAnchorPoint(0, 0)
    exppro:setPosition(42, 1)
    exppro:setMidpoint({x = 0, y = 0.5})
    exppro:setBarChangeRate({x = 1, y = 0})
    exppro:setPercentage(60)    
    self:addChild(exppro)
    self.exppro = exppro

    self.lblExp = baseLayer.createBMLabel("fonts/ttt.fnt", "365464/564465", 
        {x = self.visibleSize.width/2, y = 2}, {self, {x = 0.5, y = 0}})
    
    self:UpdateInfo()

    self.getInfoBack = baseLayer.createSprite("UI/Garden/k.png", 
        {x = self.visibleSize.width-450, y = self.visibleSize.height-180},
        {self, {x = 0, y = 0}})
    
    local lblColor = {r = 255, g = 247, b = 153}
    local lbl = baseLayer.createLabel("累计奖励:", 
        nil, {x = 20, y = 85}, nil, {self.getInfoBack, {x = 0, y = 0}})    
    lbl:setTextColor(lblColor)
    self.iconGetItem1 = baseLayer.createSprite("UI/main/bk.png", 
        {x = 110, y = 80}, {self.getInfoBack, {x = 0, y = 0}})
    self.iconGetItem1:setScale(0.7)
    self.lblGetCount = baseLayer.createLabel("1234213213564", 
        nil, {x = 170, y = 85}, nil, {self.getInfoBack, {x = 0, y = 0}})    
    
    
    lbl = baseLayer.createLabel("生产速度:", 
        nil, {x = 20, y = 55}, nil, {self.getInfoBack, {x = 0, y = 0}}) 
    lbl:setTextColor(lblColor)
    self.iconGetItem2 = baseLayer.createSprite("UI/main/bk.png", 
        {x = 110, y = 50}, {self.getInfoBack, {x = 0, y = 0}})
    self.iconGetItem2:setScale(0.7)    
    self.lblMakeSpeed = baseLayer.createLabel("1234213213564", 
        nil, {x = 170, y = 55}, nil, {self.getInfoBack, {x = 0, y = 0}}) 
    self.lblTime = baseLayer.createLabel("累计奖励:", 
        nil, {x = 20, y = 24}, nil, {self.getInfoBack, {x = 0, y = 0}}) 
    self.lblTime:setTextColor(lblColor)
end

function SceneGarden:UpdateInfo()
    self.lblLevel:setString(maincha.attr.level)
    self.lblFightValue:setString(maincha.attr.combat_power)
    self.lblaction:setString(maincha.attr.action_force)
    self.lblpearl:setString(maincha.attr.pearl)
    self.lblshell:setString(maincha.attr.shell)

    local expInfo = TableExperience[maincha.attr.level]
    self.exppro:setPercentage(maincha.attr.exp/expInfo.Experience * 100)
    self.lblExp:setString(maincha.attr.exp.."/"..expInfo.Experience)
end

function SceneGarden:UpdateMakeInfo()
    local startTime = 0
    local iconPath
    local makeSpeed = 0
    if curState == stateFish then
        self.getInfoBack:setVisible(true)
        startTime = maincha.attr.fishing_start
        iconPath = "UI/main/bk.png"
        makeSpeed = TableFish[maincha.attr.level].Shell
    elseif curState == stateGather then
        self.getInfoBack:setVisible(true)
        startTime = maincha.attr.gather_start
        iconPath = "UI/common/jy.png"
        makeSpeed = TableGather[maincha.attr.level].Jism
    elseif curState == stateSit then
        self.getInfoBack:setVisible(true)
        startTime = maincha.attr.sit_start
        iconPath = "UI/common/exp.png"
        makeSpeed = TablePractice[maincha.attr.level].Experience
    else
        self.getInfoBack:setVisible(false)
    end
    
    if iconPath and makeSpeed > 0 then
        local doTime = (os.clock() - BeginTime.localtime) - 
            (startTime - BeginTime.servertime)

        local totalM = math.floor(math.max(0, doTime/60))
        local totalH = math.floor(totalM/60)
        local modelM = totalM % 60
        local strTime =  "已进行"
        if totalH > 0 then
            strTime = strTime..totalH.."小时"
        end
        strTime = strTime..modelM.."分钟"
        self.lblTime:setString(strTime)
        self.iconGetItem1:setTexture(iconPath)
        self.iconGetItem2:setTexture(iconPath)
        self.lblMakeSpeed:setString(makeSpeed.."/小时")
        self.lblGetCount:setString(math.floor(makeSpeed * totalM/60))
    end
end

function SceneGarden:UpdateBtnState()
    if not self.cancelSpr then
        self.cancelSpr = require("UI.UIBaseLayer").createSprite(
            "UI/Garden/fg.png", {x = 320, y = 320}, {self, {x = 0, y = 0}})
        self.cancelSpr:setLocalZOrder(1)
    end
    if curState == stateFish then
        self.cancelSpr:setVisible(true)
        self.cancelSpr:setPosition(self.btnFish:getPosition())
    elseif curState == stateGather then
        self.cancelSpr:setVisible(true)
        self.cancelSpr:setPosition(self.btnGather:getPosition())
    elseif curState == stateSit then
        self.cancelSpr:setVisible(true)
        self.cancelSpr:setPosition(self.btnSit:getPosition())
    else
        self.cancelSpr:setVisible(false)
    end
end

function SceneGarden:makeFlowers()
    local minX = 120
    local minY = 70
    local maxX = 192
    local maxY = 112
    for i = 1, math.random(5,10) do
        local tilePosX = math.random(minX, maxX)
        local tilePosY = math.random(minY, maxY)
        local tilePos = {x = tilePosX, y = tilePosY} 
        local pos = cc.WalkTo:tile2MapPos(tilePos)
        local path = "Scene/flower/flower_"..math.random(1, 5)..".png"
        local spr = cc.Sprite:create(path)
        spr:setAnchorPoint({x = 0.5, y = 0})
        spr:setPosition(pos)
        self.map:addChild(spr)
        local flower = {pos = tilePos, sprite = spr}
        self.flowers[i] = flower
    end
end

function SceneGarden:OpenResult()
    local baseLayer = require("UI.UIBaseLayer")
    local back = baseLayer.createScale9Sprite("UI/common/tip.png", 
        {x = self.visibleSize.width/2 - 250, y = self.visibleSize.height/2 - 175},
        {width = 500, height = 350},{self})
    baseLayer.createSprite("UI/Garden/gjjl.png", {x = 250, y = 260}, {back})    
    --baseLayer.createSprite("UI/Garden/gjjl.png", {x = 250, y = 280}, {back})    
    
    local function onTouchBegan()
        return true
    end
    local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
    listener:setSwallowTouches(true)
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, back)
    
    local function onGetTouched(sender, event)
        back:removeFromParent()
    end
    
    baseLayer.createButton{icon = "UI/common/k.png",
        pos = {x = 250, y = 60},
        ignore = false,
        title = "领取",
        parent = back,
        handle = onGetTouched}
end

function SceneGarden:walkTo(tarPos)
    local cx, cy = self.localPlayer:getPosition()    
    local action = cc.WalkTo:create({x= cx, y = cy}, {x = tarPos.x, y = tarPos.y}, 20)

    local function onWalkEnd()
        local animationF = cc.Animation3D:create("animation/player/fish.c3b")
        local animationG = cc.Animation3D:create("animation/player/gather.c3b")
        local animationS = cc.Animation3D:create("animation/player/sit.c3b")
        local animaF = cc.RepeatForever:create(cc.Animate3D:create(animationF))
        local animaG = cc.Animate3D:create(animationG)
        local animaS = cc.RepeatForever:create(cc.Animate3D:create(animationS))

        self.localPlayer:GetAvatar3D():stopAllActions()
        if curState == stateFish then
            self.localPlayer:GetAvatar3D():setRotation3D({x = 0, y = 240, z = 0})
            self.localPlayer:GetAvatar3D():runAction(animaF)            
            animaF:setTag(100)
            local attachNode = self.localPlayer:GetAvatar3D():getAttachNode(WeaponNodeName)
            attachNode:removeChildByTag(EnumChildTag.Weapon)
            local obj = cc.Sprite3D:create("animation/player/yugan.c3b")
            obj:setTag(EnumChildTag.Weapon)
            attachNode:addChild(obj)
        elseif curState == stateGather then
            local function onGatherEnd()
                self.flowers[1].sprite:removeFromParent()
                table.remove(self.flowers, 1)
                if #self.flowers == 0 then
                   self:makeFlowers()
                end
                self:walkTo(self.flowers[1].pos)
            end
            local se = cc.Sequence:create(animaG, cc.CallFunc:create(onGatherEnd))
            se:setTag(100)
            self.localPlayer:GetAvatar3D():runAction(se)               
        elseif curState == stateSit then
            self.localPlayer:GetAvatar3D():runAction(animaS)
            self.localPlayer:GetAvatar3D():setRotation3D({x = -35, y = 10, z = 10})
            animaS:setTag(100)
        else
            self.localPlayer:GetAvatar3D():stopActionByTag(100)
            self.localPlayer:Idle()
        end
    end

    self.localPlayer:GetAvatar3D():stopAllActions()
    self.localPlayer:stopActionByTag(EnumActionTag.ActionMove)
    local se = cc.Sequence:create(action, cc.DelayTime:create(0.2), cc.CallFunc:create(onWalkEnd,{}))
    se:setTag(EnumActionTag.ActionMove)    
    self.localPlayer:runAction(se)        
    self.localPlayer:Walk()
end

RegNetHandler(function (packet)
    if packet.start_time then
        local scene = cc.Director:getInstance():getRunningScene()
        if scene.class.__cname == "SceneGarden" then
            if packet.action == stateFish then
                scene:walkTo({x = 87, y = 53})
                curState = stateFish
                maincha.attr.fishing_start = packet.start_time
            elseif packet.action == stateGather then
                scene:walkTo(scene.flowers[1].pos)
                curState = stateGather
                maincha.attr.gather_start = packet.start_time
            elseif packet.action == stateSit then
                scene:walkTo({x = 170, y = 35})
                curState = stateSit
                maincha.attr.sit_start = packet.start_time
            end
            scene:UpdateMakeInfo()
            scene:UpdateBtnState()
        else
            print("error:not in garden")
        end
    end
end,netCmd.CMD_GC_HOMEACTION_RET)

RegNetHandler(function (packet)
    print("home action end:"..packet.action)
    maincha.attr.fishing_start = 0
    maincha.attr.gather_start = 0
    maincha.attr.sit_start = 0
    curState = stateIdle
    local scene = cc.Director:getInstance():getRunningScene()
    if scene.class.__cname == "SceneGarden" then
        scene:UpdateMakeInfo()
        scene:UpdateBtnState()
        scene.localPlayer:GetAvatar3D():setRotation3D({x = 0, y = 0, z = 0})
        scene.localPlayer:Idle()
        local attachNode = scene.localPlayer:GetAvatar3D():getAttachNode(WeaponNodeName)
        attachNode:removeChildByTag(EnumChildTag.Weapon)
        scene.localPlayer:GetAvatar3D():stopActionByTag(100)
    end
end,netCmd.CMD_GC_HOMEBALANCE_RET)

return SceneGarden
--endregion