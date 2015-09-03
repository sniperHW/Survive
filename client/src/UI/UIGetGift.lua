local UIGetGift = class("UIGetGift", function()
    return require("UI.UIBaseLayer").create()
end)

function UIGetGift.create()
    local layer = UIGetGift.new()
    return layer
end

function UIGetGift:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
    self.schedulerID = nil
    self:setSwallowTouch()
    local layer = cc.LayerColor:create({r = 0, g = 0, b = 0, a = 120})
    self:addChild(layer)
    
    self:createUI()
    
    local function onBtnCloseTouched(...)
        cc.Director:getInstance():getRunningScene().hud:closeUI(self.class.__cname)
    end
    
    self.btnClose = self.createButton{pos = {x = 700, y = 420},
        icon = "UI/common/close.png",
        handle = onBtnCloseTouched,
        parent = self.nodeMid}
end

function UIGetGift:createUI()
    self.nodeMid = cc.Node:create()
    self.nodeMid:setPositionX((self.visibleSize.width - DesignSize.width)/2)
    self:addChild(self.nodeMid)
    
    local spr = self.createSprite("UI/sign/tipBack.png", {x = 480, y = 350}, {self.nodeMid})
    self.createSprite("UI/sign/yuefen.png", {x = 480, y = 440}, {self.nodeMid})
    spr:setScaleY(0.8)
    local function onTextHandle(typestr)
        
    end
    
    self.txtUserName = ccui.EditBox:create({width = 380, height = 60},
        "UI/common/jihuoma.png")
    self.txtUserName:setPosition(480, 360)
    self.txtUserName:setAnchorPoint(0.5, 0.5)
    self.txtUserName:registerScriptEditBoxHandler(onTextHandle)
    --self.txtUserName:setPlaceHolder("请输入兑换码")
    self.nodeMid:addChild(self.txtUserName)
    
    local btn = self.createButton{
        title = "确 定",
        ignore = false,
        icon = "UI/common/k.png",
        pos = {x = 480, y = 280},
        handle = nil,
        parent = self.nodeMid
    }    
    btn:setTitleTTFSizeForState(26, cc.CONTROL_STATE_NORMAL)
    local lbl = btn:getTitleLabelForState(cc.CONTROL_STATE_NORMAL)
    lbl:enableOutline(ColorBlack, 2)
    btn:setPreferredSize{width = 120, height = 50}
end

return UIGetGift 