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
    
    local textureDog = cc.Director:getInstance():getTextureCache():addImage("Scene/map9.png")--("Back.png")
    local spriteDog = cc.Sprite:createWithTexture(textureDog)
    spriteDog:setAnchorPoint({x = 0.3, y = 0.5})
    self:addChild(spriteDog)
    
    self.hud = require("UI.UIHudLayer").create()
    self:addChild(self.hud, 1)
    self.hud:openUI("UILogin")
    --self.hud:openUI("UIChooseMap")
    --self.hud:openUI("UIMainLayer")
end

return SceneLogin