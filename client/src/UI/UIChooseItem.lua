local UIChooseItem = class("UIChooseItem", function()
    return require("UI.UIBaseLayer").create()
end)

function UIChooseItem.create()
    local layer = UIChooseItem.new()
    return layer
end

function UIChooseItem:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
    self.schedulerID = nil
    self:setSwallowTouch()
    local layer = cc.LayerColor:create({r = 0, g = 0, b = 0, a = 180})
    self:addChild(layer)
    
    local back = self.createSprite("UI/chooseItem/back.png", 
        {x = self.visibleSize.width/2, y = 20}, 
        {self, {x = 0.5, y = 0}})
    back:setScaleX(self.visibleSize.width/DesignSize.width)
    
    self.nodeMid = cc.Node:create()
    self.nodeMid:setPositionX((self.visibleSize.width - DesignSize.width)/2)
    self:addChild(self.nodeMid) 
        
    local function onBtnCloseTouched(sender, type)
        local scene = cc.Director:getInstance():getRunningScene()
        scene.hud:closeUI(self.class.__cname)
    end
    
    self.btnClose = self.createButton{
        pos = {x = self.visibleSize.width-80, y = 560},
        icon = "UI/common/close.png",
        handle = onBtnCloseTouched,
        parent = self.nodeMid}
    self.btnClose:setLocalZOrder(1)       
end

function UIChooseItem:createUI(count)    
    local title = self.createSprite("UI/synthesis/scxz.png", {x = 480, y = 570}, 
        {self.nodeMid})
    title:setScaleX(1.8)
    title:setScaleY(0.8)
    
    self.createLabel("请选择一个道具带入战场", 26, 
        {x = 500, y = 570}, nil, {self.nodeMid})

    local function onBtnTouched(...)
        self.tipBack:setVisible(true)
    end
    
    local btn = self.createButton{title = "规则说明",
        pos = {x = 100, y = 480},
        icon = "UI/shop/clk.png",
        handle = onBtnTouched,
        parent = self.nodeMid}
    btn:setPreferredSize({width = 120, height = 45})
    
    local function onBtnTouched(sender, event)
        local tag = sender:getTag()
        if tag <= 3 then
            CMD_SURVIVE_CONFIRM(1)
        else
            CMD_SURVIVE_CONFIRM(0)
        end        
    end
    local path0 = "UI/chooseItem/box.png"
    local path1 = "UI/chooseItem/boxopen.png"
    local path2 = "UI/chooseItem/vipbox.png"
    local path3 = "UI/chooseItem/vipboxopen.png"
    local path = path0
    local t = {}
    for i = 1, 46 do
        t[i] = i
    end
    
    local res = {}
    for i = 4, count+3 do
        local idx = math.random(1, #t)
        res[t[idx]+4] = 1
        table.remove(t, idx)
    end
    local vipCount = {}
    for i = 1, 3 do
        local idx = math.random(1, 3)
        vipCount[idx] = i
    end
     
    for i = 1, 50 do
        local bAble = false
        if i <= 3 then
            if vipCount[i] then
                path = path2
                bAble = true
            else
                path = path3
                bAble = false
            end
        else
            if res[i] then
                path = path0
                bAble = true
            else
                path = path1
                bAble = false
            end
        end
        
        local btn = self.createButton{
            pos = {x = 40+ (i-1)%10 * 90, y = 370 - math.floor((i-1)/10) * 80},
            icon = path,
            handle = onBtnTouched,
            parent = self.nodeMid}
        btn:setTag(i)
        btn:setEnabled(bAble)
    end

    self.tipBack = self.createScale9Sprite("UI/sign/tipBack.png", {x = 240, y = 100}, 
        {width = 580, height = 450}, {self.nodeMid})
    
    local lblTip = self.createLabel([[1.活动开放时间为每天9点至23点
2.每个整点的前5分钟为报名时间，当报名人数达到45人，活动提前开始，若5分钟内报名人数未达到45人，则活动照常开启
3.活动共有12张地图，每隔2分钟有一张地图会爆炸，处在地图中的玩家按死亡计算，玩家可以通过地图中的传送阵传送至未爆炸的地图
4.玩家可以抽取一件随机道具带入战场
5.IP玩家可以抽取一件随机VIP道具带入战场
6.背包中的道具带入战场无效
7.战场后，没有武器无法进行攻击
8.中会随机刷新一些道具，玩家可以拾取后使用
9.玩家在战场中击杀对方，最后存活的一人获得胜利，系统将给予丰厚的奖励
10.玩家提前离开活动按死亡处理，且本次活动无法再次进入
    ]], 20, {x = 40, y = 420}, nil, {self.tipBack, {x = 0, y = 1}}, {width = 500, height = 0})
    lblTip:setColor{r = 255, g = 247, b = 153}
    self.tipBack:setVisible(false)
    
    local function onTouchBegan(touch, event)
        if self.tipBack:isVisible() then
            local location = touch:getLocation()
            local box = self.tipBack:getBoundingBox()
            local nodePos = self.tipBack:getParent():convertToNodeSpace(location)
            if not cc.rectContainsPoint(box, nodePos) then
                self.tipBack:setVisible(false)
            end
            return true
        end
        return false
    end
    
    local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN)
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, lblTip)
end

return UIChooseItem