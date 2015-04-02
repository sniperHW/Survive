local comm = require("common.CommonFun")
local plant1 = {
        {path = "Scene/1.png", pos=cc.p(374, 147.5), tag = 111, zorder = 65535},
        {path = "Scene/2.png", pos=cc.p(1173, 142), tag = 111, zorder = 65535}}
local Plants = {
    [201] = plant1,
    [202] = plant1,
    [203] = plant1,
    [207] = plant1,
    [208] = plant1,
    }
--region SceneCity.lua
local SceneCity = class("SceneCity",function()
    return cc.Scene:create()
end)

local sceneMapID = 0
function SceneCity.create(mapID)
    sceneMapID = mapID
    local scene = SceneCity.new()
    scene:setTag(mapID)
    return scene
end

function SceneCity:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
    self.schedulerID = nil
    self.localPlayer = nil
    self.stars = {}
    self.moveAction = 0

    local mapInfo = TableMap[sceneMapID]
    local sprMap = nil
    if mapInfo.Source_Path == "PVP" and false then      --！！！！
        local maps = {}
        sprMap = cc.Sprite:create()
        sprMap:setAnchorPoint({x = 0, y = 0})
        for i = 1, 8 do
            maps[i] = cc.Sprite:create("Scene/"..mapInfo.Source_Path..i..".png")
            maps[i]:setAnchorPoint({x = 0, y = 0})
            local cellSize = maps[i]:getContentSize()
            if i <= 4 then
                maps[i]:setPosition({x = (i-1)%4 * cellSize.width, 
                    y = cellSize.height})
            else
                maps[i]:setPosition({x = (i-1)%4 * cellSize.width, 
                    y = 0})
            end
            maps[i]:setLocalZOrder(-1)
            maps[i]:setTag(111) 
            sprMap:addChild(maps[i])
        end
        sprMap:setContentSize({width = 3088, height = 1920})
    elseif sceneMapID == 206 then
        local items = {{path = "Scene/1400005_1.png", pos = cc.p(324, 137.5), tag = 111, zorder = 65535},
            {path = "Scene/1400005_2.png", pos = cc.p(1390, 165.5), tag = 111, zorder = 65535}}        
        sprMap = cc.Sprite:create()
        sprMap:setAnchorPoint({x = 0, y = 0})        
        local cellSize = {width = 1464, height = 824}
        for i = 1, 12 do
            local spr = cc.Sprite:create("Scene/1400005.png")     
            spr:setAnchorPoint({x = 0, y = 0})
            local pos = cc.p((i-1)%4 * cellSize.width, 
                math.floor((i-1)/4)*cellSize.height)
            spr:setPosition(pos)
            spr:setLocalZOrder(-1)
            spr:setTag(111) 
            sprMap:addChild(spr)
            
            for _, value in pairs(items) do
                local plant = cc.Sprite:create(value.path)
                plant:setPosition(cc.pAdd(value.pos, pos))
                if value.tag then
                    plant:setTag(value.tag)
                end
                if value.zorder then
                    plant:setLocalZOrder(value.zorder)
                end
                sprMap:addChild(plant)
            end 
        end
        sprMap:setContentSize({width = 5760, height = 2880})
        --sprMap:setScale(0.3)
    else
        sprMap = cc.Sprite:create("Scene/"..mapInfo.Source_Path..".png")    
        sprMap:setAnchorPoint({x = 0, y = 0})
    end
    comm.playMusic(mapInfo.Music, true)
    InitAstar("Scene/"..mapInfo.Colision)
    self.map = sprMap
    self:addChild(self.map)
    
    if Plants[sceneMapID] then
        local items = Plants[sceneMapID]
        for _, value in pairs(items) do
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

    if sceneMapID == 205 then
        local player = require("Avatar").create(maincha.avatarid)
        player.id = maincha.id
        player.avatid = maincha.avatarid

        player.name = maincha.nickname
        player.attr = maincha.attr
        player:SetAvatarName(player.name)

        player:SetLife(player.attr.life, player.attr.maxlife)
        player:setPosition({x = 900, y = 600})
        player:retain()
        print(player.id)
        self.map:addChild(player)
        self.localPlayer = player
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
            local maxX = 0
            local minX = viseSize.width - mapSize.width
            local maxY = 0
            local minY = viseSize.height - mapSize.height
            
            if sceneMapID == 206 then
                local cellMapX = math.floor(px/1464)
                local cellMapY = math.floor(py/824)
                maxX = -cellMapX*1464
                minX = viseSize.width-(cellMapX+1)*1464
                maxY = -cellMapY*824
                minY = viseSize.height-(cellMapY+1)*824
            end
            
            local posX = math.min(maxX, 
                math.max(minX, cx + viseSize.width / 2 - mapMid.x))
            local posY = math.min(maxY, 
                math.max(minY, cy + viseSize.height / 2 - mapMid.y))
            if self.moveAction == 0 then
                self.map:setPosition(posX, posY)
            end
            
            local anger = MgrFight.anger
            for idx, star in pairs(self.stars) do
                local sx, sy = star:getPosition()
                local dis = cc.pGetDistance(cc.p(sx, sy), cc.p(px, py))
                star:setLocalZOrder(6000)
                if dis < 100 then
                    local moveAc = cc.Spawn:create(cc.MoveTo:create(0.3, cc.p(px, py+100)), cc.ScaleTo:create(0.3, 0.3))
                    star:runAction(cc.Sequence:create(moveAc, cc.RemoveSelf:create()))
                    table.remove(self.stars, idx)
                    MgrFight.anger = math.min(MgrFight.anger+star:getTag(), 15)
                end
            end
            
            for _, value in pairs(MgrPlayer) do
                if value.avatid > 500 and value.avatid < 700 then
                    local tx, ty = value:getPosition()
                    local dis = cc.pGetDistance(cc.p(px, py), cc.p(tx, ty))
                    if dis < 50 then
                        CMD_PICKUP(value.id)
                    end
                end
            end
            
            if anger ~= MgrFight.anger then
                local ui = self.hud:getUI("UIFightLayer")
                ui:UpdateAnger()
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

    self.schedulerID = cc.Director:getInstance():getScheduler():scheduleScriptFunc(tick, 0, false)
    
    -- handing touch events
    local touchBeginPoint = nil
    local function onTouchBegan(touch, event)
        local location = touch:getLocation()        
        local mapPos = self.map:convertToNodeSpace(location)
        local tilePos = cc.WalkTo:map2TilePos(mapPos)
        
        if self.localPlayer.buffState[3101] or MgrSetting.bJoyStickType then
            return true
        end
        
        if sceneMapID ~= 205 then
            if self.localPlayer.playSkillAction == 0 or self.localPlayer.buffState[3001]  then                
                CMD_MOV(tilePos)
            else
                self.localPlayer.moveTo = tilePos
            end
        else
            self.localPlayer:WalkTo(tilePos)
        end
        --[[
        if MgrFight.lockTarget then
            MgrFight.lockTarget = nil
        end
        ]]
        return true
    end

--[[
    local function onTouchMoved(touch, event)
        local location = touch:getLocation()
        if touchBeginPoint then
            local cx, cy = self.map:getPosition()
            local viseSize = cc.Director:getInstance():getVisibleSize()
            local mapSize = self.map:getContentSize()
            local posX = math.min(0, 
                math.max(viseSize.width - mapSize.width, cx + location.x - touchBeginPoint.x))
            local posY = 
                math.min(math.max(viseSize.height - mapSize.height, 
                    cy + location.y - touchBeginPoint.y), 0)
            self.map:setPosition(posX, posY)
            touchBeginPoint = {x = location.x, y = location.y}
        end
    end

    local function onTouchEnded(touch, event)
        local location = touch:getLocation()
        touchBeginPoint = nil
        if self.localPlayer then
            MoveTo(cc.WalkTo:map2TilePos(self.map:convertToNodeSpace(location)))
        end
    end
]]

    local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
    
    local function onNodeEvent(event)
        if "enter"  == event then
            if sceneMapID > 0 and sceneMapID ~= 205 then
                MgrFight.anger = 10
                self.hud:openUI("UIFightLayer")
                if sceneMapID == 202 then
                    self.hud:openUI("UIPVE")
                end
            elseif sceneMapID == 205 then
                local function onBtnBackTouched(sender, event)
                    local running = cc.Director:getInstance():getRunningScene()
                    local scene = require("SceneLogin").create()
                    cc.Director:getInstance():replaceScene(scene)
                    scene:setOpenUI("UIMainLayer")
                    MgrPlayer = {}
                end

                require("UI.UIBaseLayer").createButton({pos = {x = self.visibleSize.width-80, y = self.visibleSize.height-90},
                    icon = "UI/fight/back.png",
                    handle = onBtnBackTouched,
                    parent = self.hud
                })
            end
        elseif "exit" == event then
            cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.schedulerID)
            cc.SimpleAudioEngine:getInstance():stopMusic()
            MgrFight.EnterMapTime = 0
        end
    end
    self:registerScriptHandler(onNodeEvent)
end

return SceneCity
--endregion