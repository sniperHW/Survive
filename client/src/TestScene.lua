local Plants = {
    [202] = {{path = "Scene/1.png", pos = cc.p(374, 147.5), tag = 111, zorder = 65535},
        {path = "Scene/2.png", pos = cc.p(1173, 142), tag = 111, zorder = 65535}},
    [206] = {{path = "Scene/1400005_1.png", pos = cc.p(324, 137.5), tag = 111, zorder = 65535},
        {path = "Scene/1400005_2.png", pos = cc.p(1390, 165.5), tag = 111, zorder = 65535}}        
}

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

    local i = cc.Texture2D:getDefaultAlphaPixelFormat()
    print(i)
--    cc.Texture2D:setDefaultAlphaPixelFormat(4)
    local i = cc.Texture2D:getDefaultAlphaPixelFormat()
    print(i)
    local cache = cc.Director:getInstance():getTextureCache()
    --local text = cache:addImage("Scene/fivePVE.png")
    local text = cache:addImage("Scene/1400005.png")
    
--    cc.Texture2D:setDefaultAlphaPixelFormat(2)
    local sprMap = cc.Sprite:createWithTexture(text)

    sprMap:setAnchorPoint({x = 0, y = 0})
    self.map = sprMap 
    self:addChild(self.map)    
    InitAstar("Scene/1400005.meta")
    
    if Plants[206] then
        local items = Plants[206]
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
    
        
    self.hud = require("UI.UIHudLayer").create()
    self:addChild(self.hud, 100)
    self.hud:openUI("UITestLayer")
    
    local draw = cc.DrawNode:create()
    self:addChild(draw, 10)
    
    local sprite3ds = {}
    local avatars = {}
    local interval = 0
    local idx = 1
    local animLight = {x = 0.1, y = 0.1}
    local count = 1 
    local interval = 0
    local players = {}
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
        end     
    end
    
    self.schedulerID = cc.Director:getInstance():getScheduler():scheduleScriptFunc(tick, 0, false)

    self.localPlayer = require("Avatar").create(2, {id = 5001})
    local function onEnd()
    end
    self.localPlayer:Attack(11, onEnd)
    --self.localPlayer:setScale(0.2)
    self.localPlayer:setPosition({x = 960, y = 320})
    maincha.player = self.localPlayer
    self.map:addChild(self.localPlayer)
    --self.localPlayer:Death()
    --self.localPlayer:unAction(self.localPlayer.actions[EnumActions.Repel])
    table.insert(players, self.localPlayer)
    
    --[[
    local weapon = cc.Sprite3D:create("animation/player/shotgun.c3b")
    weapon:setScale(3)
    weapon:setPosition(480, 320)
    self.map:addChild(weapon)
    ]]
    
    --[[
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
    ]]
    --[[
    for i = 1, 4 do
        local player = require("Avatar").create(100+i)
        player:setPosition({x = math.random(200,960), y = math.random(100, 500)})
        self.map:addChild(player)
        table.insert(players, player)
    end
]]
    --self.localPlayer:setPosition(720, 400)
    

--    cc.SpriteFrameCache:getInstance():addSpriteFrames("effect/effect0.plist", "effect/effect0.png")
    --self.localPlayer:getChildByTag(EnumAvatar.Tag3D):stopAllActions()
    local function onTouchBegan(touch, event)
    
        local location = self.map:convertToNodeSpace(touch:getLocation())
        self.localPlayer:WalkTo(cc.WalkTo:map2TilePos(location), 27)
        
        --self.localPlayer:Attack(14, onEnd)
        --[[
        local ac1 = cc.ScaleTo:create(0.06,1.3)
        local ac2 = cc.ScaleTo:create(0.06,1.0)
        local shake = cc.Sequence:create(ac1, ac2)
        self.map:runAction(cc.Repeat:create(shake, 2))
        ]]
        --[[
        local mapPosX, mapPoxY = self.map:getPosition()
        local effPosX = 0
        local effPosY = 0

        if math.abs(mapPosX) > 20 then
            effPosX = 20
        else
            effPosX = -20
        end 

        local ac1 = cc.MoveBy:create(0.05,{x = effPosX, y = effPosY})
        local ac2 = cc.MoveBy:create(0.05,{x = -effPosX, y = -effPosY})
        local ac3 = cc.MoveBy:create(0.05,{x = effPosX, y = effPosY})
        local ac4 = cc.MoveBy:create(0.05,{x = -effPosX, y = -effPosY})

        local delay = 0.5

        local ac = cc.Sequence:create(ac1, ac2, ac3, ac4)
        self.map:runAction(ac)
        ]]
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
    
    local function onKeyPressed(keyCode, event)
        local cache = cc.Director:getInstance():getTextureCache()
        if keyCode == cc.KeyCode.KEY_D then            
            cc.Texture2D:setDefaultAlphaPixelFormat(cc.TEXTURE2_D_PIXEL_FORMAT_DEFAULT)
            local strInfo = cache:getCachedTextureInfo()
            print(strInfo)
        end
        if keyCode == cc.KeyCode.KEY_DELETE then
            local frameCache = cc.SpriteFrameCache:getInstance()
            frameCache:removeUnusedSpriteFrames()
            cache:removeUnusedTextures()
            cc.Texture2D:setDefaultAlphaPixelFormat(cc.TEXTURE2_D_PIXEL_FORMAT_RG_B565)
        end
    end
    local keyLis = cc.EventListenerKeyboard:create()
    keyLis:registerScriptHandler(onKeyPressed, cc.Handler.EVENT_KEYBOARD_PRESSED)
    eventDispatcher:addEventListenerWithSceneGraphPriority(keyLis, self)
end

return TestScene
