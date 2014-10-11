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
    
    self.map = cc.TMXTiledMap:create("Scene/city.tmx")
    self:addChild(self.map)    
    InitAstar("Scene/city.coll.tmx")
    
    local dog = cc.Sprite:create("dog.png")
    dog:setPosition(self.visibleSize.width/2, self.visibleSize.height/2)
    dog:setPosition(200, 200)
    self.map:addChild(dog)
    local glpro = cc.GLProgram:create("gray.vsh", "gray.fsh")
    glpro:bindAttribLocation(cc.ATTRIBUTE_NAME_POSITION,cc.VERTEX_ATTRIB_FLAG_POSITION)
    glpro:bindAttribLocation(cc.ATTRIBUTE_NAME_COLOR,cc.VERTEX_ATTRIB_COLOR)
    glpro:bindAttribLocation(cc.ATTRIBUTE_NAME_TEX_COORD,cc.VERTEX_ATTRIB_TEX_COORDS)
    glpro:link()
    glpro:updateUniforms()
    dog:setGLProgram(glpro)
    
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
        end
        --[[
        if interval > 3 then           
        avatars[idx]:WalkTo({x = math.random(1,239), y = math.random(1, 239)})
            idx = idx + 1
            if idx > 3 then
                idx = 1
                interval = 0
            end            
        else
            interval = interval + detal
        end]]
        

            
        for key, value in pairs(sprite3ds) do
            local rotation = value:getRotation3D()
            rotation.y = rotation.y == 360 and 1 or rotation.y + 1
            value:setRotation3D(rotation)
            --[[
            local glState = value:getGLProgramState()
            if  glState then
                animLight.x = animLight.x + 0.01
                if animLight.x > 1 then
                    animLight.x = animLight.x - 1
                end
                animLight.y = animLight.y + 0.01
                if animLight.y > 1 then
                    animLight.y = animLight.y - 1
                end
                glState:setUniformVec2("v_animLight", animLight)
            end]]
        end
    end
    
    local texture2 = cc.Director:getInstance():getTextureCache():addImage("caustics.png")
    texture2:setTexParameters(gl.LINEAR, gl.LINEAR_MIPMAP_LINEAR, gl.REPEAT, gl.REPEAT)
--[[    for i = 1, 5 do
        local d3Sprite = cc.Sprite3D:create("animation/player/cat_m.c3b")
        --local d3Sprite = cc.Sprite3D:create("tortoise.c3b")
        local glState = d3Sprite:getGLProgramState()

        d3Sprite:setPosition(math.random(20, 800),math.random(20,200))
        d3Sprite:setScale(0.2)
        d3Sprite:setRotation3D({x = 0, y = 180, z = 0})
        self.map:addChild(d3Sprite)
        
        local animation = cc.Animation3D:create("cat.c3b")
        local action = cc.Animate3D:create(animation)
        d3Sprite:runAction(cc.RepeatForever:create(action))
        
        sprite3ds[i] = d3Sprite]] --[[
        glState:setUniformTexture("u_lightTexture", texture2:getName())
       
        glState:setUniformVec2("v_animLight", {x = 0.1, y = 0.1})
       ]]
--    end
    
    self.schedulerID = cc.Director:getInstance():getScheduler():scheduleScriptFunc(tick, 0, false)
    
    if false then
        cc.SpriteFrameCache:getInstance():addSpriteFrames("animation/monster/gouxiong.plist", 
            "animation/monster/gouxiong.png")
        local animation = cc.Animation:create()
        for i = 1, 10 do
            local name = string.format("gouxiong%04d.png", i)            
            animation:addSpriteFrame(cc.SpriteFrameCache:getInstance():getSpriteFrameByName(name))
        end
        animation:setDelayPerUnit(0.03)
        local animate = cc.Animate:create(animation)
        local test = cc.Sprite:create()
        local action = cc.RepeatForever:create(animate)
        action:setTag(10)
        test:runAction(action)
        test:setPosition(450, 200)
        self.map:addChild(test)
        self.localPlayer = test
    end
    
    local function switchIdle()
        local animation = cc.Animation:create()
        for i = 1, 30 do
            local name = string.format("gouxiong%04d.png", i)            
            animation:addSpriteFrame(cc.SpriteFrameCache:getInstance():getSpriteFrameByName(name))
        end
        animation:setDelayPerUnit(0.03)
        local animate = cc.Animate:create(animation)
        local action = cc.RepeatForever:create(animate)
        action:setTag(10)
        self.localPlayer:stopAction(self.localPlayer:getActionByTag(10))
        self.localPlayer:runAction(action)
    end
    
    local function switchWalk()
        local animation = cc.Animation:create()
        for i = 31, 60 do
            local name = string.format("gouxiong%04d.png", i)            
            animation:addSpriteFrame(cc.SpriteFrameCache:getInstance():getSpriteFrameByName(name))
        end
        animation:setDelayPerUnit(0.03)
        local animate = cc.Animate:create(animation)
        local action = cc.RepeatForever:create(animate)
        action:setTag(10)
        self.localPlayer:stopAction(self.localPlayer:getActionByTag(10))
        self.localPlayer:runAction(action)
    end
    
    self.localPlayer = require("Avatar").create(1)
    self.localPlayer:setPosition(200,200)
    self.map:addChild(self.localPlayer)
    local function onTouchBegan(touch, event)
        local location = self.map:convertToNodeSpace(touch:getLocation())
        self.localPlayer:WalkTo(cc.WalkTo:map2TilePos(location))
        return true
    end
  
    for i = 1, 5 do
        local player = require("Avatar").create(math.random(1, 5) + 100)
        avatars[i] = player
        player:setPosition(math.random(1, 1920), math.random(1, 640))
        self.map:addChild(player)
    end    
 
    local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
    
    local function onNodeEvent(event)
        if "enter" == event then
            local dog = cc.Sprite:create("dog.png")
            dog:setPosition(self.visibleSize.width/2, self.visibleSize.height/2)
            --dog:setPosition(0, 0)
            --self:addChild(dog)
            local glpro = cc.GLProgram:create("gray.vsh", "gray.fsh")
            glpro:bindAttribLocation(cc.ATTRIBUTE_NAME_POSITION,cc.VERTEX_ATTRIB_FLAG_POSITION)
            glpro:bindAttribLocation(cc.ATTRIBUTE_NAME_COLOR,cc.VERTEX_ATTRIB_COLOR)
            glpro:bindAttribLocation(cc.ATTRIBUTE_NAME_TEX_COORD,cc.VERTEX_ATTRIB_TEX_COORDS)
            glpro:link()
            glpro:updateUniforms()
            dog:setGLProgram(glpro)

            --local player = cc.Sprite3D:create("cat.c3b")
            --local player = cc.Sprite3D:create("tortoise.c3b")
            local player = cc.Sprite3D:create("box.obj")
            player:setTexture(cc.Director:getInstance():getTextureCache():addImage("cat.jpg"))
            player:setPosition(450, 450)
            player:setScale(5)
            player:setTag(100)
            local animation = cc.Animation3D:create("tortoise.c3b")
            local action = cc.Animate3D:create(animation)
            --player:runAction(cc.RepeatForever:create(action))
            self:addChild(player)
            local fileUtils = cc.FileUtils:getInstance()

            local glprogram = cc.GLProgram:createWithFilenames("", "UVAnimation.fsh")
            --local glprogram = cc.GLProgram:createWithFilenames("UVAnimation.vsh", "ccShader_3D_ColorTex.frag")
            local glprogramstate = cc.GLProgramState:getOrCreateWithGLProgram(glprogram)

            --player:setTexture(cc.Director:getInstance():getTextureCache():addImage("caustics.png"))

            --local texture1 = cc.Director:getInstance():getTextureCache():addImage("tortoise.png")
            local texture1 = cc.Director:getInstance():getTextureCache():addImage("cat.jpg")
            glprogramstate:setUniformTexture("u_texture1", texture1:getName())

            local texture2 = cc.Director:getInstance():getTextureCache():addImage("caustics.png")
            glprogramstate:setUniformTexture("u_lightTexture", texture2:getName())

            texture2:setTexParameters(gl.LINEAR, gl.LINEAR_MIPMAP_LINEAR, gl.REPEAT, gl.REPEAT)
            glprogramstate:setUniformVec4("v_LightColor", {x = 1.0, y = 1.0, z = 1.0, w = 1.0})

            --[[
            local offset = 0
            local s_attributeName = {"a_position", "a_color", "a_texCoord", "a_normal", 
            "a_blendWeight", "a_blendIndex"}
            --print(s_attributeName[1])
            local attributeCount = player:getMesh():getMeshVertexAttribCount()
            for k = 0, attributeCount - 1 do
            local meshattribute = player:getMesh():getMeshVertexAttribute(k)
            glprogramstate:setVertexAttribPointer(s_attributeName[meshattribute.vertexAttrib+1],
            meshattribute.size,
            meshattribute.type,
            false,
            player:getMesh():getVertexSizeInBytes(), 
            offset)
            offset = offset + meshattribute.attribSizeBytes      
            end
            ]]

            player:resetAttribPointer()
            player:setGLProgramState(glprogramstate)

            glprogramstate:setUniformVec2("v_animLight", {x = 0.1, y = 0.1})
            local animLight = {x = 0.1, y = 0.1}
            local function tick(detal)
                local state = self:getChildByTag(100):getGLProgramState()
                if  state then
                    animLight.x = animLight.x + 0.01
                    if animLight.x > 1 then
                        animLight.x = animLight.x - 1
                    end
                    animLight.y = animLight.y + 0.01
                    if animLight.y > 1 then
                        animLight.y = animLight.y - 1
                    end
                    state:setUniformVec2("v_animLight", animLight)
                end
            end

            self.schedulerID = cc.Director:getInstance():getScheduler():scheduleScriptFunc(tick, 0, false)
        end
    end

    if false then
        self:registerScriptHandler(onNodeEvent)
    end
    --[[
    local label = cc.Label:createWithBMFont("fonts/ttt.fnt", "95431221", 
                cc.TEXT_ALIGNMENT_LEFT, 0, {x = 0, y = 0})
    label:setPosition({x = 100, y = 200})
    self:addChild(label)]]
end

return TestScene
