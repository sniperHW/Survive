local UIChooseMap = class("UIChooseMap", function()
    return require("UI.UIBaseLayer").create()
end)

function UIChooseMap.create()
    local layer = UIChooseMap.new()
    return layer
end

function UIChooseMap:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
    self.schedulerID = nil
    --print("init ui choose map")
    
    local texture = cc.Director:getInstance():getTextureCache():addImage("Main.png")
    local back = cc.Sprite:createWithTexture(texture)
    back:setAnchorPoint(0, 0)
    self:addChild(back)
    
    local function onTouchBegan(sender, event)
        CMD_ENTERMAP(1)
    end
    
    local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
    --listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
    --listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
end
    
return UIChooseMap