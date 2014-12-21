local comm = require("common.CommonFun")

local SceneLogin = class("SceneLogin",function()
    return cc.Scene:create()
end)

function SceneLogin.create()
    local scene = SceneLogin.new()
    return scene
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

    self.hud:openUI("UILogin")
    
    local function onNodeEvent(event)
        if "enter" == event then
            comm.playMusic("music/login.mp3",true)
            local cache = cc.Director:getInstance():getTextureCache()
            cache:removeUnusedTextures()
        elseif "exit" == event and self.schedulerID then
            cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.schedulerID)
            cc.SimpleAudioEngine:getInstance():stopMusic()
            --self:unregisterScriptHandler()
        end
    end
    self:registerScriptHandler(onNodeEvent)
end

return SceneLogin