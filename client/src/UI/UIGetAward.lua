local UIGetAward = class("UIGetAward", function()
    return require("UI.UIBaseLayer").create()
end)

function UIGetAward.create()
    local layer = UIGetAward.new()
    return layer
end

function UIGetAward:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
    self.schedulerID = nil
    self:setSwallowTouch()
    local layer = cc.LayerColor:create({r = 0, g = 0, b = 0, a = 120})
    self:addChild(layer)
    self:creatUI()
end

function UIGetAward:creatUI()
    local size = self.visibleSize
    local preSize = {width = 350, height = 400}
    self.createScale9Sprite("UI/sign/tipBack.png", 
        {x = size.width/2-preSize.width/2, y = size.height/2-preSize.height/2},
	   preSize, {self})	
	
    preSize = {width = 300, height = 200}
    self.createScale9Sprite("UI/sign/tipBack.png", 
        {x = size.width/2-preSize.width/2, y = size.height/2-preSize.height/2+50},
        preSize, {self})
    local str = [[奉上珍珠50，不成敬意]]
    local lbl = self.createLabel(str, 22, 
        {x = size.width/2, y = size.height/2+170}, nil, {self})
    lbl:setColor{r = 191, g = 182, b = 113} 
    str = [[一点小意思]]
    lbl = self.createLabel(str, 22, 
        {x = size.width/2, y = size.height/2-20}, nil, {self})
    lbl:setColor{r = 191, g = 182, b = 113} 
    
    self.createSprite("icon/itemIcon/zhenzhu.png",  
        {x = size.width/2, y = size.height/2+70},{self})
    self.createBMLabel(
        "fonts/jinenglv.fnt", 50, {x = size.width/2+50, y = size.height/2+20}, {self})
        
    local function onGetTouched(...)
        local onEnd = self.onEnd
        local hud = cc.Director:getInstance():getRunningScene().hud
        hud:closeUI("UIGetAward")
        onEnd()
    end 
           
    local btn = self.createButton{
        title = "领 取",
        ignore = false,
        icon = "UI/common/k.png",
        pos = {x = size.width/2, y = size.height/2-120},
        handle = onGetTouched,
        parent = self
    }    
    btn:setTitleTTFSizeForState(26, cc.CONTROL_STATE_NORMAL)
end

function UIGetAward:setOnEnd(onEnd)
	self.onEnd = onEnd
end

return UIGetAward