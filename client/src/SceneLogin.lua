local comm = require("common.CommonFun")
MgrLoadedMap = {}

local SceneLogin = class("SceneLogin",function()
    return cc.Scene:create()
end)

function SceneLogin.create()
    local scene = SceneLogin.new()
    return scene
end

function SceneLogin:setOpenUI(uiName)
    self.defaultUI = uiName
end

function SceneLogin:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
    self.schedulerID = nil
    
    local textureDog = cc.Director:getInstance():getTextureCache():addImage("UI/createCharacter/back.png")--("Back.png")
    local spriteDog = cc.Sprite:createWithTexture(textureDog)
    --spriteDog:setAnchorPoint({x = 0.3, y = 0.5})
    spriteDog:setPosition(self.visibleSize.width/2, self.visibleSize.height/2)
    spriteDog:setScaleX(self.visibleSize.width/DesignSize.width)
    self:addChild(spriteDog)
    
    self.hud = require("UI.UIHudLayer").create()
    self:addChild(self.hud, 1)

    local function onNodeEvent(event)
        if "enter" == event then
            self.hud:openUI(self.defaultUI or "UILogin")
            --local ui = self.hud:openUI("UIFightLayer")
            --ui:createUI(10)
            --self.hud:openUI("UIPVE")
            --[[
            local ui = self.hud:openUI("UINPCTalk")
            ui:ShowTalk(1, nil)
            ]]
            
            --[[
            local i = math.random(1,2)
            local iconStar = nil
            if i == 1 then
                iconStar = cc.Sprite:create("xingxing.png")
            elseif i == 2 then
                iconStar = cc.Sprite:create("xingxing2.png")
            end
            
            iconStar:setPosition(200, 320)
            iconStar:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.FadeTo:create(0.3,180), cc.FadeTo:create(0.3,255))))
            self:addChild(iconStar)
            ]]
            
            comm.playMusic("music/login.mp3",true)
            local cache = cc.Director:getInstance():getTextureCache()
            for idx, path in pairs(MgrLoadedMap) do
                cache:removeTextureForKey(path)    
            end
            MgrLoadedMap = {}
            --cache:removeUnusedTextures()
        elseif "exit" == event and self.schedulerID then
            cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.schedulerID)
            cc.SimpleAudioEngine:getInstance():stopMusic()
            --self:unregisterScriptHandler()
        end
    end
    self:registerScriptHandler(onNodeEvent)
    
    local function onTouchBegan(...)

    end
    
    local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
    --listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
    --listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
    listener:setSwallowTouches(true)
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
end

return SceneLogin