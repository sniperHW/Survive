local UIChoosePVP = class("UIChoosePVP", function()
    return require("UI.UIBaseLayer").create()
end)

function UIChoosePVP.create()
    local layer = UIChoosePVP.new()
    return layer
end

function UIChoosePVP:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
    self.schedulerID = nil
    self:setSwallowTouch()
    local layer = cc.LayerColor:create({r = 0, g = 0, b = 0, a = 120})
    self:addChild(layer)
    self:createUI()
    local function onBtnCloseTouched(sender, type)
        cc.Director:getInstance():getRunningScene().hud:closeUI(self.class.__cname)
    end

    self.btnClose = self.createButton{pos = {x = 700, y = 420},
        icon = "UI/common/close.png",
        handle = onBtnCloseTouched,
        parent = self.nodeMid}
end

function UIChoosePVP:createUI()
    self.nodeMid = cc.Node:create()
    self.nodeMid:setPositionX((self.visibleSize.width - DesignSize.width)/2)
    self:addChild(self.nodeMid)
    
    self.createSprite("UI/sign/tipBack.png", {x = 480, y = 320}, {self.nodeMid})
    self.createSprite("UI/sign/yuefen.png", {x = 480, y = 440}, {self.nodeMid})
    self.createLabel("选择副本", 24, 
        {x = 480, y = 440}, nil, {self.nodeMid})
        
    self.createLabel("体力消耗：", 16, 
        {x = 600, y = 390}, nil, {self.nodeMid})
        
    self.createLabel("20", 16, 
        {x = 650, y = 390}, nil, {self.nodeMid})

    local spr = self.createSprite("UI/main/tl.png", {x = 680, y = 390}, {self.nodeMid})
    spr:setScale(0.5)
        
    local function onBtnTouched(sender, event)
        local tag = sender:getTag()             
        local hud = cc.Director:getInstance():getRunningScene().hud
        hud:openUI("UIWaitTeamPVE")

        cc.Director:getInstance():getRunningScene().hud:closeUI(self.class.__cname)
        CMD_ENTERMAP(tag)
    end
    
    local btn = self.createButton{pos = {x = 300, y = 280},
        icon = "UI/pve/danrpvp.png",
        ignore = false,
        handle = onBtnTouched,
        parent = self.nodeMid}
    btn:setTag(207)
    btn:setZoomOnTouchDown(false)
    btn:setBackgroundSpriteForState(
        ccui.Scale9Sprite:create("UI/pve/danrpvp2.png"), 
        cc.CONTROL_STATE_HIGH_LIGHTED)
    
    btn = self.createButton{pos = {x = 480, y = 280},
        icon = "UI/pve/shuangrpvp.png",
        ignore = false,
        handle = onBtnTouched,
        parent = self.nodeMid}
    btn:setTag(208)
    btn:setZoomOnTouchDown(false)
    btn:setBackgroundSpriteForState(
        ccui.Scale9Sprite:create("UI/pve/shuangrpvp2.png"), 
        cc.CONTROL_STATE_HIGH_LIGHTED)

    btn = self.createButton{pos = {x = 660, y = 280},
        icon = "UI/pve/duorpvp.png",
        ignore = false,
        handle = onBtnTouched,
        parent = self.nodeMid}
    btn:setTag(204)
    btn:setZoomOnTouchDown(false)
    btn:setBackgroundSpriteForState(
        ccui.Scale9Sprite:create("UI/pve/duorpvp2.png"), 
        cc.CONTROL_STATE_HIGH_LIGHTED)
end

return UIChoosePVP