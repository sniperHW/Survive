local UIMessage = class("UIMessage", function()
    return require("UI.UIBaseLayer").create()
end)

function UIMessage.create()
    local layer = UIMessage.new()
    return layer
end

function UIMessage:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
    self.schedulerID = nil
end

function UIMessage.showMessage(msgStr)
    local hud = cc.Director:getInstance():getRunningScene().hud
    local ui = hud:getUI("UIMessage")
    ui:addMessage(msgStr)        
end

function UIMessage:addMessage(msgStr)
    local child = self:getChildren()
    for _, v in ipairs(child) do 
        local posY = v:getPositionY()
        v:setPositionY(posY + 44)
    end
    
    local bk = self.createSprite("UI/common/msgback.png", 
        {x = self.visibleSize.width/2, y = self.visibleSize.height/2}, {self})
    local lbl = self.createLabel(msgStr, nil, {x = 294, y = 22}, nil, {bk}) 
    local delay = cc.DelayTime:create(3)
    local fadeout = cc.FadeOut:create(0.3)
    local remove = cc.RemoveSelf:create()
    bk:runAction(cc.Sequence:create(delay, fadeout, remove))
end

return UIMessage