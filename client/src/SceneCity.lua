local comm = require("common.CommonFun")

--region SceneCity.lua
local SceneCity = class("SceneCity",function()
    return cc.Scene:create()
end)

local sceneMapID = 0
function SceneCity.create(mapID)
    sceneMapID = mapID
    local scene = SceneCity.new()
    return scene
end

function SceneCity:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
    self.schedulerID = nil
    self.localPlayer = nil

    local mapInfo = TableMap[sceneMapID]
    local sprMap = nil
    if mapInfo.Source_Path == "PVP" then
        local maps = {}
        sprMap = cc.Sprite:create()
        sprMap:setAnchorPoint({x = 0, y = 0})
        for i = 1, 8 do
            maps[i] =  cc.Sprite:create("Scene/"..mapInfo.Source_Path..i..".png")
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
    else
        sprMap = cc.Sprite:create("Scene/"..mapInfo.Source_Path..".png")    
        sprMap:setAnchorPoint({x = 0, y = 0})
    end
    comm.playMusic(mapInfo.Music, true)
    InitAstar("Scene/"..mapInfo.Colision)
    self.map = sprMap
    self:addChild(self.map)

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

    if sceneMapID > 0 and sceneMapID ~= 205 then
        self.hud:openUI("UIFightLayer")
    elseif sceneMapID == 205 then
        local function onBtnBackTouched(sender, event)
            local running = cc.Director:getInstance():getRunningScene()
            local scene = require("SceneLogin").create()
            cc.Director:getInstance():replaceScene(scene)
            scene.hud:closeUI("UILogin")
            scene.hud:openUI("UIMainLayer")
            MgrPlayer = {}
        end

        require("UI.UIBaseLayer").createButton({pos = {x = self.visibleSize.width-80, y = self.visibleSize.height-90},
            icon = "UI/fight/back.png",
            handle = onBtnBackTouched,
            parent = self.hud
        })
    end

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

        if sceneMapID ~= 205 then
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
        if sceneMapID ~= 205 then
            if self.localPlayer.playSkillAction == 0 or
                self.localPlayer.playSkillAction % 10 ~= 0 then
                if self.localPlayer.playSkillAction % 10 ~= 0 then
                    print("==============================")
                    self.localPlayer.playSkillAction = 0
                end
                self.localPlayer:GetAvatar3D():stopActionByTag(EnumActionTag.Attack3D)
                MgrFight.StateFighting = 1
                CMD_MOV(tilePos)
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
end

return SceneCity
--endregion