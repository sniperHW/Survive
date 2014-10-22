local UIHudLayer = class("UIHudLayer",function()
    return cc.Node:create()
end)

function UIHudLayer.create()
    local hud = UIHudLayer.new()
    
    return hud
end

function UIHudLayer:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
    self.schedulerID = nil
end

function UIHudLayer:openUI(className)
    if self[className] == nil then
        print("UI."..className)
        local ui = require("UI."..className).create()
        self[className] = ui
        self:addChild(ui)
    end
end

function UIHudLayer:closeUI(className)
    if self[className] ~= nil then
        self[className]:removeFromParentAndCleanup()
        self[className] = nil
    end
end

return UIHudLayer


