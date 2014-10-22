require "Cocos2d"
require "Cocos2dConstants"

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
    print("******************************************")
    local sprMap = cc.Sprite:create("Scene/garde.png")
    sprMap:setAnchorPoint({x = 0, y = 0})
    self.map = sprMap 
    --self.map = cc.TMXTiledMap:create("Scene/city.tmx")
    self:addChild(self.map)    
    InitAstar("Scene/garden.tmx")

    local sprite3ds = {}
    local avatars = {}
    local interval = 0
    local idx = 1
    local animLight = {x = 0.1, y = 0.1}
    
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
            
            --[[
            local cameraPos = camera:getPosition3D()
            cameraPos.y = cameraPos.y + 320
            self.camera:setPosition3D(cameraPos)]]
            
            --self.camera:lookAt({x = px, y = py, z = 0}, {x = 0, y = 1, z = 0})
        end     
            
        for key, value in pairs(sprite3ds) do
            local rotation = value:getRotation3D()
            rotation.y = rotation.y == 360 and 1 or rotation.y + 1
            value:setRotation3D(rotation)
        end
    end
    
    self.schedulerID = cc.Director:getInstance():getScheduler():scheduleScriptFunc(tick, 0, false)

    self.localPlayer = require("Avatar").create(2)
    --self.localPlayer:getChildByTag(1):setScale(1)
    --local camera = cc.Camera:createPerspective(60, self.visibleSize.width/self.visibleSize.height, 0, 1000);
    local camera = cc.Camera:create()
    self.camera = camera
    local cameraPos = camera:getPosition3D()
    cameraPos.y = cameraPos.y + 320
    self.camera:setPosition3D(cameraPos)
    --self.camera:setPosition3D( {x = self.visibleSize.width/2, y = self.visibleSize.height, z = 425 })
    camera:setCameraFlag(4)
    local pos3D = self.localPlayer:getPosition3D()
    --camera:setPosition3D({x = 0, y = 0, z = -100})
    --camera:lookAt({x = 0, y = 0, z = 0}, {x = 0, y = 1, z = 0})
    --camera:setPosition3D({x = self.visibleSize.width/2, y = self.visibleSize.height, z = 0});
    --camera:lookAt({x = self.visibleSize.width/2, y = self.visibleSize.height/2, z = 0}, {x = 0, y = 1, z = 0});
    print("-------------------")
    print(pos3D.x)
    print(pos3D.y)
    print(pos3D.z)
    self.localPlayer:getChildByTag(1):setCameraMask(4)
    --self.localPlayer:getChildByTag(1):setPosition3D({x = 0, y = 320, z = 0})
    
    local camera1 = cc.Camera:create()
    self.map:setCameraMask(2)
    camera1:setCameraFlag(2)
    self:addChild(camera1)
    self:addChild(camera)

    self.localPlayer0 = cc.Sprite3D:create("animation/player/catF.c3b")
    self.localPlayer0:setCameraMask(4)
    self.localPlayer0:setScale(0.2)
    local weapon = cc.Sprite3D:create("animation/player/dao.c3b")
    self.localPlayer0:getAttachNode("Bone020"):addChild(weapon)
    local seAc = cc.Sequence:create(self.localPlayer.actions[5], self.localPlayer.actions[6], self.localPlayer.actions[7])
    local ac = cc.RepeatForever:create(seAc)
    --self.localPlayer:getChildByTag(1):stopActionByTag(1)
    --self.localPlayer:getChildByTag(1):runAction(ac)
    self.localPlayer:setPosition(480,200)
    self.localPlayer0:setPosition(480, 320)
    self.map:addChild(self.localPlayer0)
    self.map:addChild(self.localPlayer)

    self.anima = cc.Animation3D:create("animation/player/catF.c3b")
    print("Animation3D")
    print(self.anima)

    
    --self.atk1Animate:setWeight(0.9)

    --self.hitAction:setWeight(0.1)

    cc.SpriteFrameCache:getInstance():addSpriteFrames("effect/effect0.plist", "effect/effect0.png")
    --self.localPlayer:getChildByTag(EnumAvatar.Tag3D):stopAllActions()
    local function onTouchBegan(touch, event)
        local location = self.map:convertToNodeSpace(touch:getLocation())
        self.localPlayer:WalkTo(cc.WalkTo:map2TilePos(location))

        --[[
        self.localPlayer0:stopAllActions()
        self.hitAction = cc.Animate3D:create(self.anima, 0, 0.583)
        self.hitAction:setWeight(0.01)
        self.atk1Animate = cc.Animate3D:create(self.anima, 0.833, 1.542)
        self.atk1Animate:setWeight(0.99)
        print(self.atk1Animate:getDuration())
        self.localPlayer:getChildByTag(EnumAvatar.Tag3D):runAction(self.atk1Animate:clone())

        --local atkActions =  self.localPlayer.actions[EnumActions.Attack1]
        --atkActions:setWeight(0.99)

        self.localPlayer0:runAction(self.atk1Animate)
        --self.localPlayer0:runAction(self.hitAction)
        self.localPlayer0:runAction(cc.Sequence:create(cc.DelayTime:create(0.5), self.hitAction))
]]
        --cc.Sequence:create(cc.DelayTime:create(0.1), 
        --local pawn = cc.Spawn:create(atkActions, hitAction)
        --self.localPlayer:getChildByTag(EnumAvatar.Tag3D):runAction(pawn)
--[[
        local name = ""
        local animation = cc.Animation:create()
        local frameCache = cc.SpriteFrameCache:getInstance()
        for i = 1, 11 do
            name = string.format("997-%d.png", i)
            animation:addSpriteFrame(frameCache:getSpriteFrame(name))
        end
        animation:setDelayPerUnit(0.03)
        local animate = cc.Animate:create(animation)
        local spr = cc.Sprite:create()
        spr:setTag(100)
        spr:runAction(cc.Sequence:create(animate, cc.RemoveSelf:create()))
        --spr:runAction(cc.RepeatForever:create(animate))
        local rotation = self.localPlayer:getChildByTag(1):getRotation3D()
        print("rotation.y:"..rotation.y)
        spr:setRotation3D({x = 0, y = rotation.y - 90, z = 0})
        self.localPlayer:removeChildByTag(100)
        self.localPlayer:addChild(spr)
    ]]
--[[
        local test = cc.Sprite3D:create("animation/player/catF.c3b")
        local animation = cc.Animation3D:create("animation/player/catF.c3b")
        local animate = cc.Animate3D:create(animation, 20.625, 21.75)
        print("***************************")
        print(animate:getDuration())
        print("---------------------------")

        test:runAction(cc.RepeatForever:create(animate))        
        local weapon = cc.Sprite3D:create("animation/player/gun.c3b")
        test:getAttachNode("Bip01 R Hand"):addChild(weapon)
        self.map:addChild(test)

        weapon = cc.Sprite3D:create("animation/player/gun.c3b")
        weapon:setPosition(location.x, location.y + 100)
        self.map:addChild(weapon)
        test:setPosition(location.x, location.y)
        test:setScale(0.3)
]]

        return true
    end
  
    for i = 1, 5 do
        local player = require("Avatar").create(math.random(1, 4) + 100)
        avatars[i] = player
        player:setPosition(math.random(1, 1920), math.random(1, 640))
        self.map:addChild(player)
    end    
 
    local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN)
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
end

return TestScene
