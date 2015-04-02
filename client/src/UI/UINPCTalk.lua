local UINPCTalk = class("UINPCTalk", function()
    return require("UI.UIBaseLayer").create()
end)

function UINPCTalk.create()
    local layer = UINPCTalk.new()
    --layer:ShowTalk(id)
    return layer
end

function UINPCTalk:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
    self.schedulerID = nil
    --self:createUI()
end

function UINPCTalk:ShowTalk(id, onTalkEnd)
    self.step = 1    
    local npcInfo = TableNewbie_Guide[id]
    local bLeft = false
    self.onEnd = onTalkEnd
        
    if bLeft then
        local back = self.createSprite("UI/guide/k.png", {x = 0, y = 0},
            {self, {x = 0, y = 0}})
        back:setFlippedX(true)
        
        local beauty = self.createSprite("UI/guide/newnvhaidao.png", {x = -40, y = 0},
            {self, {x = 0, y = 0}})
        beauty:setFlippedX(true)
        
        self.lblText = self.createLabel(npcInfo.Take_Content1, 20, 
            {x = 220, y = 150}, nil, 
            {self, {x = 0, y = 1}}, {width = 380, height = 0})            
        self.angle = self.createSprite("UI/guide/jt.png", {x = 600, y = 20},
            {self, {x = 0, y = 0}})
        local ac1 = cc.MoveBy:create(0.4,{x = 0, y = 20})
        local ac2 = cc.MoveBy:create(0.3,{x = 0, y = -20})
        self.angle:runAction(cc.RepeatForever:create(cc.Sequence:create(ac1, ac2)))
    else
        self.createSprite("UI/guide/k.png", {x = self.visibleSize.width, y = 0},
            {self, {x = 1, y = 0}})
        self.createSprite("UI/guide/newnvhaidao.png", {x = self.visibleSize.width+40, y = 0},
            {self, {x = 1, y = 0}})

        self.lblText = self.createLabel(npcInfo.Take_Content1, 20, 
            {x = self.visibleSize.width - 620, y = 150}, nil, 
            {self, {x = 0, y = 1}}, {width = 380, height = 0})      
                  
        self.angle = self.createSprite("UI/guide/jt.png", {x = self.visibleSize.width - 650, y = 20},
            {self, {x = 0, y = 0}})
        local ac1 = cc.MoveBy:create(0.4,{x = 0, y = 20})
        local ac2 = cc.MoveBy:create(0.3,{x = 0, y = -20})
        self.angle:runAction(cc.RepeatForever:create(cc.Sequence:create(ac1, ac2)))
    end
    
    local function onTouchBegan(touch, event)
        local step = self.step + 1
        local str = npcInfo["Take_Content"..step]
        if str then
            self.lblText:setString(str)
            if npcInfo["Take_Content"..(step+2)] then
                self.angle:setVisible(true)
            else
                self.angle:setVisible(false)
            end            
        end 
        return true
    end
    
    local function onTouchEnd(...)
        self.step = self.step + 1
        local str = npcInfo["Take_Content"..self.step]
        if not str then
            local onEnd = self.onEnd
            local hud = cc.Director:getInstance():getRunningScene().hud
            hud:closeUI("UINPCTalk")
            
            if onEnd then
                onEnd() 
            end
        end
    end

    local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN)
    listener:registerScriptHandler(onTouchEnd,cc.Handler.EVENT_TOUCH_ENDED)
    listener:setSwallowTouches(true)
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
end

return UINPCTalk