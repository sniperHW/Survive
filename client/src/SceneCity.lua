--region SceneCity.lua
local SceneCity = class("SceneCity",function()
    return cc.Scene:create()
end)

function SceneCity.create()
    local scene = SceneCity.new()
    return scene
end

function SceneCity:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
    --self.schedulerID = nil
    self.localPlayer = nil
    
    local sprMap = cc.Sprite:create("Scene/map9.png")
    sprMap:setAnchorPoint({x = 0, y = 0})
    --self.map = cc.TMXTiledMap:create("Scene/fightMap.tmx")
    self.map = sprMap
    self:addChild(self.map)
    
    for _, var in pairs(MgrPlayer) do
        --print(_.."hello"..var)
        self.map:addChild(var)
        var:release()
        print("--------------------")
        print(var.id)
        print(maincha.id)
        if var.id == maincha.id then
            self.localPlayer = var
        end
    end
    print(self.localPlayer)
    print("*************************")
    
    local viseSize = cc.Director:getInstance():getVisibleSize()
    local mapSize = self.map:getContentSize()

    self.hud = require("UI.UIHudLayer").create()
    self:addChild(self.hud, 1)
    self.hud:openUI("UIFightLayer")

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
        end
        
        local children = self.map:getChildren()
        for _, value in ipairs(children) do
            local zorder = math.ceil(value:getPositionY())
            --print(zorder)
            value:setLocalZOrder(mapSize.height - zorder)
        end

        MgrFight:atkTick(detal)
    end

    self.schedulerID = cc.Director:getInstance():getScheduler():scheduleScriptFunc(tick, 0, false)
    
    -- handing touch events
    local touchBeginPoint = nil
    local function onTouchBegan(touch, event)
        local location = touch:getLocation()        
        CMD_MOV(cc.WalkTo:map2TilePos(self.map:convertToNodeSpace(location)))
        if MgrFight.lockTarget then
            MgrFight.lockTarget = nil
        end
        return true
    end

    local function onTouchMoved(touch, event)
        local location = touch:getLocation()
        --cclog("onTouchMoved: %0.2f, %0.2f", location.x, location.y)
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
        --cclog("onTouchEnded: %0.2f, %0.2f", location.x, location.y)
        touchBeginPoint = nil
        --spriteDog.isPaused = false
        if self.localPlayer then
            --local cx, cy = self.localPlayer:getPosition()
            --print(cc.WalkTo)
            --print(cc.WalkTo:create)
            --local action = cc.WalkTo:create({x = cx, y = cy}, 
                --cc.WalkTo:map2TilePos(self.map:convertToNodeSpace(location)), 10)
            --local action = cc.MoveTo:create(2, location)
            --self.localPlayer:runAction(action)
            MoveTo(cc.WalkTo:map2TilePos(self.map:convertToNodeSpace(location)))
        end
    end

    local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
    --listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
    --listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
end

return SceneCity
--endregion