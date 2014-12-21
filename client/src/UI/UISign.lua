local UISign = class("UISign", function()
    return require("UI.UIBaseLayer").create()
end)

function UISign.create()
    local layer = UISign.new()
    return layer
end

function UISign:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
    self.schedulerID = nil
    self:setSwallowTouch()
    local layer = cc.LayerColor:create({r = 0, g = 0, b = 0, a = 120})
    self:addChild(layer)
    self:createUI()
    self.createSprite("UI/sign/dk.png", {x = 0, y = 0}, 
        {self.nodeMid, {x = 0, y = 0}})
        
    local function onBtnCloseTouched(sender, type)
        cc.Director:getInstance():getRunningScene().hud:closeUI(self.class.__cname)
    end
    
    self.btnClose = self.createButton{pos = {x = 795, y = 540},
        icon = "UI/common/close.png",
        handle = onBtnCloseTouched,
        parent = self.nodeMid}
    self.btnClose:setLocalZOrder(1)
end

function UISign:createUI()
    self.nodeMid = cc.Node:create()
    self.nodeMid:setPositionX((self.visibleSize.width - DesignSize.width)/2)
    self:addChild(self.nodeMid)
    self.signWidgets = {}
    local selfSign = MgrSign --or {daycount = 31, count = 6, sighAble = 0}
    
    local size = self.visibleSize
    self.createSprite("UI/sign/dkyy.png", {x = 0, y = 0}, {self.nodeMid, {x = 0, y = 0}})
    if self.visibleSize.width/self.visibleSize.height < 1.5 then
        self.nodeMid:setScale(0.9)
        self.nodeMid:setPositionX(0)
    end
    
    self.createSprite("UI/sign/yuefen.png", {x = 500, y = 550}, {self.nodeMid})
    
    local curMonth = os.date("*t", os.time()).month
    self.lblCurMonth = self.createLabel(curMonth.."月签到奖励", 22, 
        {x = 500, y = 550}, nil, {self.nodeMid})
    self.lblCurMonth:setColor{r = 254, g = 255, b = 196}
    
    local function showSignTip(sender, event)
        self.tipBack:setVisible(true)
    end
    
    self.createButton{
        icon = "UI/sign/gz.png",
        pos = {x = 280, y = 510},
        ignore = false,
        handle = showSignTip,
        parent = self.nodeMid
    }
    
    local label = self.createLabel("本月已累计签到      次", 18, 
        {x = 500, y = 510}, nil, {self.nodeMid})
    label:setColor{r = 207, g = 169, b = 114}
    self.lblSignTimes = self.createLabel("10", 18, 
        {x = 555, y = 510}, nil, {self.nodeMid})

    self.createSprite("UI/sign/k.png", {x = 510, y = 260}, {self.nodeMid})
    
    local scrollView = cc.ScrollView:create({width = 600, height = 400})
    local contenHeight = math.ceil(selfSign.daycount/5) * 118
    
    self.nodeMid:addChild(scrollView)
    scrollView:setPosition(225,60)
    scrollView:setContentSize({width = 600, height = contenHeight})
    scrollView:setDirection(1)
    scrollView:setContentOffset{x = 0, y = 400-contenHeight}

    local touchBeginPoint = nil
    local bTouchMoved = false
    local beginPoint = nil
    local chooseIdx = 0
    local function onTouchBegan(touch, event)
        bTouchMoved = false
        local location = touch:getLocation()
        touchBeginPoint = {x = location.x, y = location.y}
        beginPoint = touchBeginPoint
        
        if self.tipBack:isVisible() then
            local box = self.tipBack:getBoundingBox()
            local nodePos = self.tipBack:getParent():convertToNodeSpace(beginPoint)
            if not cc.rectContainsPoint(box, nodePos) then
                self.tipBack:setVisible(false)
            end
            return true
        end
        
        for key, value in pairs(self.signWidgets) do
            local icon = value.iconBack
            local box = icon:getBoundingBox()
            local nodePos = icon:getParent():convertToNodeSpace(beginPoint)
            if cc.rectContainsPoint(box, nodePos) then
                chooseIdx = key
                break
            end
        end
        return true
    end

    local function onTouchMoved(touch, event)
        local location = touch:getLocation()
        --cclog("onTouchMoved: %0.2f, %0.2f", location.x, location.y)
        if touchBeginPoint then
            touchBeginPoint = {x = location.x, y = location.y}
            if cc.pGetDistance(beginPoint,touchBeginPoint) > 20 
                and not bTouchMoved 
                and chooseIdx > 0 then
                bTouchMoved = true
            end
        end
    end

    local function onTouchEnded(touch, event)
        if not bTouchMoved and chooseIdx > 0 then
            local signInfo = TableSign[chooseIdx]   
            if chooseIdx == selfSign.count+1 then
                if selfSign.signAble > 0 then
                    CMD_EVERYDAYSIGN()
                else
                    local hud = cc.Director:getInstance():getRunningScene().hud
                    hud:showHint(EnumHintType.other, {id = signInfo.Item_ID}, nil)
                end
            else
                local hud = cc.Director:getInstance():getRunningScene().hud
                hud:showHint(EnumHintType.other, {id = signInfo.Item_ID}, nil)
            end
            chooseIdx = 0
        end
    end

    local eventNode = cc.Sprite:create()
    self.nodeMid:addChild(eventNode)
    local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN)
    listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
    listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, eventNode)

    for i = 1, selfSign.daycount do
        local signInfo = TableSign[i]                
        local widget = {}
        local spr = self.createSprite("UI/sign/xkk.png", 
            {x = 113 * (((i-1) % 5)), 
            y = (math.ceil(selfSign.daycount/5)-math.floor((i-1)/5)-1)*118}, 
            {scrollView, {x = 0, y = 0}})
        widget.iconBack = spr            
            
        local back = self.createSprite("UI/bag/iconB.png", 
            {x = 56, y = 59}, {spr})
        back:setScale(1.2)
        local itemInfo = TableItem[signInfo.Item_ID]
        widget.itemIcon = self.createSprite("icon/itemIcon/"..itemInfo.Icon..".png", 
            {x = 56, y = 59}, {spr})  
        if itemInfo.Quality then
            local qualityIcon = self.createSprite(QualityIconPath[itemInfo.Quality], 
                {x = 0, y = 0}, {widget.itemIcon, {x = 0, y = 0}})
        end
        widget.itemIcon:setScale(0.6)
        
        local lblCount = self.createBMLabel("fonts/shop.fnt", 
            "x"..signInfo.Number1, {x = 120, y = 32}, 
            {spr, {x = 1, y = 0.5}})
        
        if signInfo.VIP_Level > 0 then
            widget.iconDouble = self.createSprite("UI/sign/sb.png", 
                {x = 33, y = 88}, {spr})
            
            widget.lblVIP = self.createBMLabel("fonts/qiandaovip.fnt", "V18", 
                {x = 35, y = 100}, {spr, {x = 1, y = 0.5}})
            widget.lblVIP:setRotation(-45)
        end
        
        widget.iconSigned = self.createSprite("UI/sign/zhe.png", 
            {x = 56, y = 59}, {spr})
        widget.iconSigned:setVisible(i > 8)
        self.createSprite("UI/sign/q.png", {x = 75, y = 40}, {widget.iconSigned})
        
        self.signWidgets[i] = widget
    end
    
    self.createSprite("UI/sign/yy.png", {x = 510, y = 90}, {self.nodeMid})
    
    self.tipBack = self.createSprite("UI/sign/tipBack.png", {x = 520, y = 280}, {self.nodeMid})
    local lblTip = self.createLabel([[每月累计签到天数，领取对应的签到奖励。

特定签到日，达到对应VIP等级及其以上的玩家可获取双倍奖励，其中第二份奖励可以在当日升级VIP等级后领取。

注：每日凌晨，签到奖励计算到隔天，当天未领取的奖励隔天不可补领。
    ]], 20, {x = 40, y = 300}, nil, {self.tipBack, {x = 0, y = 1}}, {width = 500, height = 0})
    lblTip:setColor{r = 255, g = 255, b = 0}
    self.tipBack:setVisible(false)
    self:UpdateSign()
end

function UISign:UpdateSign()
    --local selfSign = {daycount = 31, count = 6, sighAble = 0}--MgrSign -- MgrSign 
    local selfSign = MgrSign
    self.lblSignTimes:setString(selfSign.count)
    for i = 1, selfSign.daycount do
        self.signWidgets[i].iconSigned:setVisible(i <= selfSign.count)
        self.signWidgets[i].iconBack:setTexture("UI/sign/xk.png")
    end
    
    if selfSign.signAble == 0 then        
        if true and TableSign[selfSign.count].VIP_Level > 0 then    --TODO VIP
            self.signWidgets[selfSign.count].iconBack:setTexture("UI/sign/xkkk.png")
            self.signWidgets[selfSign.count].iconSigned:setVisible(false)
        end
    else
        if selfSign.count < selfSign.daycount then
            self.signWidgets[selfSign.count+1].iconBack:setTexture("UI/sign/xkk.png")
        end
    end
end

return UISign