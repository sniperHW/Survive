local UIPVE = class("UIPVE", function()
    return require("UI.UIBaseLayer").create()
end)

function UIPVE:create()
    local layer = UIPVE.new()
    return layer
end

function UIPVE:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
    self.schedulerID = nil
    self:setSwallowTouch()  
    self:cteateLeft() 
    self:createRight()
end

function UIPVE:cteateLeft()
    local spr = self.createSprite("UI/pve/dt.png", {x = 188, y = 320}, {self})
    spr:setLocalZOrder(1)
    
    local quick = cc.Node:create()
    spr:addChild(quick)    
    self.quick = quick
    quick:setVisible(false)
    self.createSprite("UI/pve/syucisu.png", {x = 160, y = 500}, {quick})
    self.lblRemainTimes = self.createBMLabel("fonts/pve.fnt", 11, 
        {x = 245, y = 500}, {quick, {x = 0, y = 0.5}})
        
    self.createSprite("UI/pve/hk.png", {x = 170, y = 400}, {quick})
    self.createSprite("UI/pve/hk.png", {x = 170, y = 280}, {quick})
    self.createSprite("UI/pve/hk.png", {x = 170, y = 160}, {quick})    
    
    self.lblRemainTimes = self.createBMLabel("fonts/pve.fnt", "第1关", 
        {x = 80, y = 400}, {quick, {x = 0, y = 0.5}})
    
    local function onBeginTouched(sender, event)
    
    end    
    
    self.createButton{
        title = "开始闯关",
        ignore = false,
        icon = "UI/pve/kstz.png",
        pos = {x = 220, y = 400},
        handle = onBeginTouched,
        parent = quick
    }       
    
    local fastNode = cc.Node:create()
    quick:addChild(fastNode)
    
    self.createSprite("UI/main/bk.png", {x = 100, y = 300}, {fastNode})
    self.lblNeedShell = self.createBMLabel("fonts/pve.fnt", "123456", 
        {x = 130, y = 300}, {quick, {x = 0, y = 0.5}})
    self.lblRemainTimes1 = self.createBMLabel("fonts/pve.fnt", "第1关", 
        {x = 80, y = 260}, {quick, {x = 0, y = 0.5}})
    self.createButton{
        title = "快速闯关",
        ignore = false,
        icon = "UI/pve/kstz.png",
        pos = {x = 220, y = 260},
        handle = onBeginTouched,
        parent = quick
    }    

    self.createSprite("UI/main/zz.png", {x = 100, y = 180}, {fastNode})
    self.lblNeedShell = self.createBMLabel("fonts/pve.fnt", "123456", 
        {x = 130, y = 180}, {quick, {x = 0, y = 0.5}})
    self.lblRemainTimes1 = self.createBMLabel("fonts/pve.fnt", "第1关", 
        {x = 80, y = 140}, {quick, {x = 0, y = 0.5}})
    self.createButton{
        title = "极速闯关",
        ignore = false,
        icon = "UI/pve/kstz.png",
        pos = {x = 220, y = 140},
        handle = onBeginTouched,
        parent = quick
    }    
    
    local curInfo = cc.Node:create()
    self.curInfo = curInfo
    spr:addChild(curInfo)
    
    self.createSprite("UI/pve/dixguan.png", {x = 170, y = 500}, {curInfo})
    self.lblNeedShell = self.createBMLabel("fonts/pve.fnt", 1, 
        {x = 180, y = 495}, {curInfo})
        
    self.createLabel("当前累计奖励：", 22, {x = 150, y = 430}, nil, {curInfo})
    self.createSprite("UI/pve/hk.png", {x = 170, y = 350}, {curInfo})
    
    self.createSprite("UI/main/exp.png", {x = 100, y = 370}, {curInfo})
    self.createLabel("经验:", 20, {x = 150, y = 370}, nil, {curInfo})
    self.lblCurGetExp = self.createLabel("123456", 20, {x = 180, y = 370}, 
        nil, {curInfo, {x = 0, y = 0.5}})
    self.createSprite("UI/main/bk.png", {x = 100, y = 330}, {curInfo})
    self.createLabel("贝壳:", 20, {x = 150, y = 330}, nil, {curInfo})
    self.lblCurGetShell = self.createLabel("123456", 20, {x = 180, y = 330}, 
        nil, {curInfo, {x = 0, y = 0.5}})
        
    self.lblFailedCount = self.createLabel("已经有42个人在本关跪了", 20, 
        {x = 60, y = 260}, nil, {curInfo, {x = 0, y = 0}})
        
    local btn = self.createButton{title = "拿奖走人",
        icon = "UI/common/k.png",
        ignore= false,
        pos = {x = 170, y = 180},
        handle = nil,
        parent = curInfo
    }
    btn:setTitleTTFSizeForState(26, cc.CONTROL_STATE_NORMAL)
    self.createLabel("剩余士气值：", 18, {x = 160, y = 130}, nil, {curInfo})
    self.createLabel("20", 18, {x = 210, y = 130}, nil, {curInfo, {x = 0, y = 0.5}})
end

function UIPVE:createRight()
    local map = cc.Sprite:create()
    map:setPositionX(350)
    --map:setLocalZOrder(-1)
    self:addChild(map)

    local spr = self.createSprite("UI/pve/mapp.png", {x = 0, y = 0}, {map, {x = 0, y = 0}})
    spr:setScaleY(1.36)
    spr = self.createSprite("UI/pve/mapp.png", {x = 735, y = 0}, {map, {x = 0, y = 0}})
    spr:setScaleY(1.36)

    local touchBeginPoint = nil

    local function onTouchBegan(touch, event)
        local location = touch:getLocation()
        touchBeginPoint = {x = location.x, y = location.y}
        return true
    end

    local function onTouchMoved(touch, event)
        local location = touch:getLocation()
        local cx, cy = map:getPosition()
        local posX = cx + location.x - touchBeginPoint.x
        touchBeginPoint = {x = location.x, y = location.y}
        posX = math.max(math.min(350, posX), self.visibleSize.width - 1470)
        map:setPositionX(posX)
    end

    local function onTouchEnded(touch, event)

    end

    local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
    listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
    listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, map)
    
    local pos1 = {
        {50, 500, 1},
        {80, 510, 1},
        {50, 20, 1},
        {150, 20, 1},
    }
    
    local pos2 = {
        {40, 40},    
        {40, 80},    
    }
    
    for idx, pos in pairs(pos1) do
        self.createSprite("UI/pve/dd.png", {x = pos1[idx][1], y = pos1[idx][2]}, {map})
    end
    
   for idx, pos in pairs(pos2) do
        self.createSprite("UI/pve/dian.png", {x = pos2[idx][1], y = pos2[idx][2]}, {map})
    end
end

return UIPVE