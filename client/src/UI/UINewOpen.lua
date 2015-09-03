local UINewOpen = class("UINewOpen", function()
    return require("UI.UIBaseLayer").create()
end)

function UINewOpen.create()
    local layer = UINewOpen.new()
    return layer
end

function UINewOpen:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
    self.schedulerID = nil    
    self:setLocalZOrder(60001)
    self:setSwallowTouch()
    local layer = cc.LayerColor:create({r = 0, g = 0, b = 0, a = 120})
    self:addChild(layer)
end

function UINewOpen:Show(IconStr, tarPos, onEnd)
	local midPoint = cc.p(self.visibleSize.width/2, self.visibleSize.height/2)
    local spr1 = self.createSprite("UI/newOpen/xgngm.png", midPoint, {self})
    local spr2 = self.createSprite("UI/newOpen/xgngm.png", midPoint, {self})
    --spr2:setRotation{x = 0, y = -12.5}
    spr1:runAction(cc.RepeatForever:create(cc.RotateBy:create(1.5,360)))
    spr2:runAction(cc.RepeatForever:create(cc.RotateBy:create(20,-360)))
    spr1:setOpacity(100)
	local icon = self.createSprite(IconStr, midPoint, {self})
	
    local bezier = {
        cc.p(tarPos.x, midPoint.y-140),
        cc.p(tarPos.x, midPoint.y-140),
        cc.p(tarPos.x, tarPos.y),
    }

    local bezierAc = cc.BezierTo:create(0.8, bezier)
    
    local action = cc.Sequence:create(cc.DelayTime:create(1), bezierAc, cc.CallFunc:create(onEnd))
    icon:runAction(action)
	
    local spr = self.createSprite("UI/newOpen/xgn.png", cc.pSub(midPoint,cc.p(0, 80)), {self})
    spr:setScale(3)
    spr:runAction(cc.EaseIn:create(cc.ScaleTo:create(0.3, 1), 2))
end

return UINewOpen