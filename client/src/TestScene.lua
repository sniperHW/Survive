local TestScene = class("TestScene",function()
    return cc.Scene:create()
end)

function TestScene.create()
    local scene = TestScene.new()
    return scene
end

function TestScene:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
    self.schedulerID = nil

    local sprMap = cc.Sprite:create("Scene/fivePVE.png")
    sprMap:setAnchorPoint({x = 0, y = 0})
    self.map = sprMap 
    self:addChild(self.map)    
    InitAstar("Scene/fivePVE.meta")
        
    self.hud = require("UI.UIHudLayer").create()
    self:addChild(self.hud, 100)
    
    local sprite3ds = {}
    local avatars = {}
    local interval = 0
    local idx = 1
    local animLight = {x = 0.1, y = 0.1}
    local count = 1 
    local function tick(detal)
        if self.localPlayer then
            local cx, cy = self.map:getPosition()
            local viseSize = cc.Director:getInstance():getVisibleSize()
            local mapSize = self.map:getContentSize()
            local px, py = self.localPlayer:getPosition()
            local mapMid = self.map:convertToWorldSpace({x = px, y = py})
            local posX = math.min(0, 
                math.max(viseSize.width - mapSize.width, cx + viseSize.width / 2 - mapMid.x))
            local posY = 
                math.min(math.max(viseSize.height - mapSize.height, 
                    cy + viseSize.height / 2 - mapMid.y), 0)
            self.map:setPosition(posX, posY)
            if count ~= 1 then 
                local popUp = require("UI.UIPopup")   
                popUp.Popup("hello", {}) 
                count = 0
            end
        end     
            
        for key, value in pairs(sprite3ds) do
            local rotation = value:getRotation3D()
            rotation.y = rotation.y == 360 and 1 or rotation.y + 1
            value:setRotation3D(rotation)
        end
    end
    
    self.schedulerID = cc.Director:getInstance():getScheduler():scheduleScriptFunc(tick, 0, false)

    self.localPlayer = require("Avatar").create(102, nil)
    --self.localPlayer:setScale(0.2)
    self.localPlayer:setPosition({x = 720, y = 320})
    maincha.player = self.localPlayer
    self.map:addChild(self.localPlayer)
    self.localPlayer:Death()
    --self.localPlayer:unAction(self.localPlayer.actions[EnumActions.Repel])
    
    local ava = cc.Sprite3D:create("animation/monster/jijuxie.c3b")
    local ani = cc.Animation3D:create("animation/monster/jijuxie.c3b")
    local ac = cc.Animate3D:create(ani)
    ava:runAction(cc.RepeatForever:create(ac))
    ava:setPosition(360,320)
    ava:setScale(2)
    ava:setRotation3D({x = 0, y = 0, z = 0})
    local spr = cc.Sprite:create()
    spr:addChild(ava)
    spr:setRotation({x = -35, y = 0, z = 0})
    self.map:addChild(spr)
    
    --[[
    for i = 1, 10 do
        local player = require("Avatar").create(1)
        player:setPosition({x = math.random(200,400), y = math.random(100, 500)})
        self.map:addChild(player)
    end
]]
    --self.localPlayer:setPosition(720, 400)
    
    self.anima = cc.Animation3D:create("animation/player/catF.c3b")

--    cc.SpriteFrameCache:getInstance():addSpriteFrames("effect/effect0.plist", "effect/effect0.png")
    --self.localPlayer:getChildByTag(EnumAvatar.Tag3D):stopAllActions()
    local function onTouchBegan(touch, event)
        local location = self.map:convertToNodeSpace(touch:getLocation())
        self.localPlayer:WalkTo(cc.WalkTo:map2TilePos(location))
        return true
    end
--[[
    for i = 1, 5 do
        local player = require("Avatar").create(i + 100)
        avatars[i] = player
        player:setPosition(math.random(200, 800), math.random(1, 640))
        self.map:addChild(player)
    end    
]]
    local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN)
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
end

return TestScene
