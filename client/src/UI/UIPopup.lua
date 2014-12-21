local UIPopup = class("UIPopup", function()
    return require("UI.UIBaseLayer").create()
end)

function UIPopup.create()
    local layer = UIPopup.new()
    return layer
end

function UIPopup:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
    self.schedulerID = nil
    self:setSwallowTouch()
end

function UIPopup.Popup(msgStr, extra, popType)
    local hud = cc.Director:getInstance():getRunningScene().hud
    local ui = require("UI.UIPopup").create()
    ui.popType = popType
    ui.extra = extra
    ui:setPosition(ui.visibleSize.width/2, ui.visibleSize.height/2)
    ui:showPopMessag(msgStr)
    hud:addChild(ui)
end

function UIPopup:showPopMessag(msgStr)
    self.createScale9Sprite("UI/common/tip.png", {x = 0, y = 0}, 
        {width = 400, height = 247}, {self, {x = 0.5, y = 0.5}})
    --local msgStr = "洗点功能按钮点击有弹出确认框，玩家花费相应的货币洗点（加点界面）"
    self.createLabel(msgStr, nil, 
        { x = 0, y = 80}, nil, {self, {x = 0.5, y = 1}},
        {width = 360, height = 0})
        
    local function onConfirmTouched(sender, event)
        if sender == self.btnConfirm then
            if self.popType == EnumPopupType.cancelGarden then
                CMD_HOMEBALANCE(self.extra)
            end
        end
        self:removeFromParent()
    end

    self.btnConfirm  = self.createButton{
        pos = {x = -100, y = -60},
        icon = "UI/common/kuang2.png",
        handle = onConfirmTouched,
        ignore = false,
        parent =  self    
    }
    self.btnSkillHandle  = self.createButton{
        pos = {x = 100, y = -60},
        icon = "UI/common/kuang1.png",
        handle = onConfirmTouched,
        ignore = false,
        parent =  self    
    }

end

return UIPopup