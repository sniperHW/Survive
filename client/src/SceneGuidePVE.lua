local comm = require("common.CommonFun")
local Pseudo = require "src.pseudoserver.pseudoserver"

--region SceneCity.lua
local SceneGuidePVE = class("SceneGuidePVE",function()
    return cc.Scene:create()
end)

local sceneMapID = 0
function SceneGuidePVE.create(mapID)
    sceneMapID = mapID
    local scene = SceneGuidePVE.new()
    scene:setTag(mapID)
    return scene
end

function SceneGuidePVE:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
    self.schedulerID = nil
    self.localPlayer = nil
    self.stars = {}
    self.moveAction = 0

    local mapInfo = TableMap[sceneMapID]
    local sprMap = nil

    sprMap = cc.Sprite:create("Scene/"..mapInfo.Source_Path..".png")    
    sprMap:setAnchorPoint({x = 0, y = 0})
    
    comm.playMusic(mapInfo.Music, true)
    InitAstar("Scene/"..mapInfo.Colision)
    self.map = sprMap
    self:addChild(self.map)
    
    local plant1 = {
        {path = "Scene/1.png", pos=cc.p(374, 147.5), tag = 111, zorder = 65535},
        {path = "Scene/2.png", pos=cc.p(1173, 142), tag = 111, zorder = 65535}}
    for _, value in pairs(plant1) do
        local plant = cc.Sprite:create(value.path)
        plant:setPosition(value.pos)
        if value.tag then
            plant:setTag(value.tag)
        end
        if value.zorder then
            plant:setLocalZOrder(value.zorder)
        end
        self.map:addChild(plant)
    end 

    for _, var in pairs(MgrPlayer) do
        print("add player in scene:"..var.id)
        var:setLocalZOrder(1)
        self.map:addChild(var)
        var:release()
        if var.id == maincha.id then
            self.localPlayer = var
        end
    end

    local viseSize = cc.Director:getInstance():getVisibleSize()
    local mapSize = self.map:getContentSize()

    self.hud = require("UI.UIHudLayer").create()
    self:addChild(self.hud, 1)

    local function tick(detal)
        if self.localPlayer then
            local cx, cy = self.map:getPosition()            
            local px, py = self.localPlayer:getPosition()
            local mapMid = self.map:convertToWorldSpace({x = px, y = py})
            local posX = math.min(0, 
                math.max(viseSize.width - mapSize.width, 
                    cx + viseSize.width / 2 - mapMid.x))
            local posY = 
                math.min(math.max(viseSize.height - mapSize.height, 
                    cy + viseSize.height / 2 - mapMid.y), 0)
            if self.moveAction == 0 then
                self.map:setPosition(posX, posY)
            end

            local anger = MgrFight.anger
            for idx, star in pairs(self.stars) do
                local sx, sy = star:getPosition()
                local dis = cc.pGetDistance(cc.p(sx, sy), cc.p(px, py))
                star:setLocalZOrder(6000)
                if dis < 100 then
                    local moveAc = cc.Spawn:create(cc.MoveTo:create(0.3, 
                        cc.p(px, py+100)), cc.ScaleTo:create(0.3, 0.3))
                    star:runAction(cc.Sequence:create(moveAc, 
                        cc.RemoveSelf:create()))
                    table.remove(self.stars, idx)
                    MgrFight.anger = math.min(MgrFight.anger+star:getTag(), 15)
                end
            end

            if anger ~= MgrFight.anger then
                local ui = self.hud:getUI("UIFightLayer")
                ui:UpdateAnger()
            end
            
            if self.curRound == 1001 and self.guideStar == false then
                for _, var in pairs(MgrPlayer) do
                    if var.id ~= maincha.id then
                        if var.attr.life <= 0 then
                            self.guideStar = true
                            self:createGuideStar(var)
                        end
                    end
                end
            end

            if self.curRound == 1003 and self.guideUseItem == false 
                and self.localPlayer.attr.life < self.localPlayer.attr.maxlife then
                self.guideUseItem = true
                local ui = self.hud:getUI("UIFightLayer")
                ui:createGuideUseItem()
            end
        else
            --print("**********no local player**************")            
        end

        local children = self.map:getChildren()
        for _, value in ipairs(children) do
            if value:getTag() ~= 111 then
                local zorder = math.ceil(value:getPositionY())
                --print(zorder)
                value:setLocalZOrder(mapSize.height - zorder)
            end
        end

        if sceneMapID ~= 205 and not MgrSetting.bJoyStickType then
            MgrFight:atkTick(detal)
        end
    end

    local scheduler = cc.Director:getInstance():getScheduler()
    self.schedulerID = scheduler:scheduleScriptFunc(tick, 0, false)

    -- handing touch events
    local touchBeginPoint = nil
    local function onTouchBegan(touch, event)
        local location = touch:getLocation()        
        local mapPos = self.map:convertToNodeSpace(location)
        local tilePos = cc.WalkTo:map2TilePos(mapPos)
        if self.localPlayer then
            if self.localPlayer.playSkillAction == 0 
                or self.localPlayer.buffState[3001]  then                
                CMD_MOV(tilePos)
            else
                self.localPlayer.moveTo = tilePos
            end
        end
        
        return true
    end

    local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN)
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
    
    local function createGuide()
        local guideNode = cc.Node:create()
        self.guideNode = guideNode
        self.hud:addChild(guideNode)
        
        local layer = cc.LayerColor:create({r = 0, g = 0, b = 0, a = 100})
        
        local pos = {x = 480, y = 360}
        local s = cc.Sprite:create("UI/guide/s.png")
        local moveBy = cc.MoveBy:create(0.2, {x = 20, y = -20})
        local move = moveBy:reverse()
        s:runAction(cc.RepeatForever:create(cc.Sequence:create(moveBy, move)))
        s:setPosition({x = pos.x, y = pos.y-20})
        
        local ceil = cc.Sprite:create("UI/guide/q.png")
        ceil:setPosition(pos)
        
        local spr = cc.Sprite:create()
        local ani = comm.getEffAni(152)
        spr:runAction(cc.RepeatForever:create(ani))
        --spr:setScale(2)
        spr:setPosition(pos)
        
        local clipNode = cc.ClippingNode:create(ceil)
        clipNode:setInverted(true)
        --clipNode:setAlphaThreshold(0)
        
        local lblTip = cc.Label:create()
        lblTip:setString("点击移动到此处")
        lblTip:setSystemFontSize(20)
        lblTip:setPosition({x = 480, y = 400})
        lblTip:setColor({r = 255, g = 255, b = 0})
        
        clipNode:addChild(layer)
        guideNode:addChild(spr)
        guideNode:addChild(s)
        guideNode:addChild(clipNode)
        guideNode:addChild(lblTip)
        
        local ui = self.hud:openUI("UINPCTalk")
        ui:ShowTalk(3, nil)
        local rect = s:getBoundingBox()
        
        local function onTouchBegan(touch, event)
            local location = touch:getLocation()
            if cc.rectContainsPoint(rect, location) then
                local attackSchID = 0 
                self.guideNode:removeFromParent()
                self.guideNode = nil
                local function guideAttack()
                    self:createGuideAttack()
                    scheduler:unscheduleScriptEntry(attackSchID)
                end
                attackSchID=scheduler:scheduleScriptFunc(guideAttack, 1, false)
                
                return false
            end
            return true
        end

        local listen = cc.EventListenerTouchOneByOne:create()
        listen:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN)
        listen:setSwallowTouches(true)
        local dispatcher = guideNode:getEventDispatcher()
        dispatcher:addEventListenerWithSceneGraphPriority(listen, guideNode)
    end

    local function onNodeEvent(event)
        if "enter" == event then
            local ui = self.hud:openUI("UIFightLayer")
            if MgrGuideStep == 4 then
                Pseudo.BegPlay(1001)
                self.curRound = 1001
                self.guideStar = false                
                ui.nodeLeftBottom:setVisible(false)
                ui.btnSwitch:setVisible(false)
                ui.nodeRightTop:setVisible(false)
                ui.nodeJoyStick:setVisible(false)
                createGuide()
            elseif MgrGuideStep == 17 then
                Pseudo.BegPlay(1003)
                self.curRound = 1003
                self.guideUseItem = false
            end
        elseif "exit" == event then
            local scheduler = cc.Director:getInstance():getScheduler()
            scheduler:unscheduleScriptEntry(self.schedulerID)
            cc.SimpleAudioEngine:getInstance():stopMusic()
        end
    end
    self:registerScriptHandler(onNodeEvent)
end

function SceneGuidePVE:createGuideStar(monster)
    local iconStar = cc.Sprite:create("xingxingda.png")
    iconStar:setTag(15)
    local selfPosX, selfPosY = self.localPlayer:getPosition()
    local posX, posY = monster:getPosition()
    iconStar:setPosition(posX, posY+20)
    iconStar:runAction(cc.RepeatForever:create(
        cc.Sequence:create(cc.FadeTo:create(0.3,180), 
            cc.FadeTo:create(0.3,255))))

    local tarX = 0
    if posX > selfPosX then
        tarX = selfPosX - posX + 50
    else
        tarX = selfPosX - posX - 50
    end
    
    local bezier = {
        cc.p(tarX, 60),
        cc.p(tarX, 20),
        cc.p(tarX, selfPosY-posY)
    }
    
    local bezierForward = cc.BezierBy:create(0.8, bezier)
    
    local function insertStar()
        table.insert(self.stars, iconStar)        
    end

    iconStar:runAction(cc.Sequence:create(bezierForward, 
        cc.CallFunc:create(insertStar)))            
    self.map:addChild(iconStar)
    
    local ui = self.hud:openUI("UINPCTalk")
    ui:ShowTalk(5, nil)
end

function SceneGuidePVE:createGuideAttack()
    local guideNode = cc.Node:create()
    self.guideNode = guideNode
    self.hud:addChild(guideNode)

    local layer = cc.LayerColor:create({r = 0, g = 0, b = 0, a = 100})

    local pos = nil
    
    for _, var in pairs(MgrPlayer) do
        if var.id ~= maincha.id then
            local p = cc.p(var:getPosition())
            pos = var:getParent():convertToWorldSpace(p)
            break
        end
    end
    
    local s = cc.Sprite:create("UI/guide/s.png")
    local moveBy = cc.MoveBy:create(0.2, {x = 20, y = -20})
    local move = moveBy:reverse()
    s:runAction(cc.RepeatForever:create(cc.Sequence:create(moveBy, move)))
    s:setPosition({x = pos.x, y = pos.y-20})

    local ceil = cc.Sprite:create("UI/guide/q.png")
    ceil:setPosition(pos)

    local spr = cc.Sprite:create()
    local ani = comm.getEffAni(152)
    spr:runAction(cc.RepeatForever:create(ani))
    --spr:setScale(2)
    spr:setPosition(pos)

    local clipNode = cc.ClippingNode:create(ceil)
    clipNode:setInverted(true)
    --clipNode:setAlphaThreshold(0)

    local lblTip = cc.Label:create()
    lblTip:setString("点击怪物方向\n即可自动攻击")
    lblTip:setSystemFontSize(20)
    lblTip:setPosition({x = pos.x, y = pos.y+40})
    lblTip:setColor({r = 255, g = 255, b = 0})

    clipNode:addChild(layer)
    guideNode:addChild(spr)
    guideNode:addChild(s)
    guideNode:addChild(clipNode)
    guideNode:addChild(lblTip)

    local ui = self.hud:openUI("UINPCTalk")
    ui:ShowTalk(4, nil)
    local rect = s:getBoundingBox()

    local function onTouchBegan(touch, event)
        local location = touch:getLocation()
        if cc.rectContainsPoint(rect, location) then
            self.guideNode:removeFromParent()
            self.guideNode = nil
            return false
        end
        return true
    end

    local listen = cc.EventListenerTouchOneByOne:create()
    listen:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN)
    listen:setSwallowTouches(true)
    local dispatcher = guideNode:getEventDispatcher()
    dispatcher:addEventListenerWithSceneGraphPriority(listen, guideNode)
end

function SceneGuidePVE:createGuideSkill()

end

return SceneGuidePVE
--endregion