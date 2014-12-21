local UIShop = class("UIShop", function()
    return require("UI.UIBaseLayer").create()
end)

function UIShop.create()
    local layer = UIShop.new()
    return layer
end

function UIShop:ctor()
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

function UIShop:createUI()
    self.nodeMid = cc.Node:create()
    self.nodeMid:setPositionX((self.visibleSize.width - DesignSize.width)/2)
    self:addChild(self.nodeMid)   
    
    local size = self.visibleSize
    self.createSprite("UI/sign/dkyy.png", {x = 0, y = 0}, {self.nodeMid, {x = 0, y = 0}})
    if self.visibleSize.width/self.visibleSize.height < 1.5 then
        self.nodeMid:setScale(0.9)
        self.nodeMid:setPositionX(0)
    end

    self.createSprite("UI/sign/yuefen.png", {x = 500, y = 550}, {self.nodeMid})
    self.createLabel("商  城", 26, 
        {x = 500, y = 550}, nil, {self.nodeMid})
        
    local btn = self.createButton{title = "材 料",
        pos = {x = 240, y = 460},
        icon = "UI/common/k.png",
        handle = nil,
        parent = self.nodeMid}
    btn:setPreferredSize({width = 120, height = 45})
    
    btn = self.createButton{title = "材 料",
        pos = {x = 400, y = 460},
        icon = "UI/common/k.png",
        handle = nil,
        parent = self.nodeMid}
    btn:setPreferredSize({width = 120, height = 45})
    
    local count = 20
    local scrollView = cc.ScrollView:create({width = 600, height = 360})
    local contenHeight = math.ceil(count/2) * 130
    print(contenHeight)
    
    self.nodeMid:addChild(scrollView)
    scrollView:setPosition(225,100)
    scrollView:setContentSize({width = 600, height = contenHeight})
    scrollView:setDirection(1)
    scrollView:setContentOffset{x = 0, y = 360-contenHeight}    
    
    for i = 1, count do
        local spr = self.createSprite("UI/shop/xk.png", 
            {x = 310 * (((i-1) % 2)), 
                y = (math.ceil(count/2)-math.floor((i-1)/2) - 1)*130+20}, 
            {scrollView, {x = 0, y = 0}})
            
        local back = self.createSprite("UI/bag/iconB.png", 
            {x = 56, y = 50}, {spr})
        back:setScale(1.2)     
        
        local itemInfo = TableItem[5601]
        local itemIcon = self.createSprite("icon/itemIcon/"..itemInfo.Icon..".png", 
            {x = 56, y = 50}, {spr})        
            
        if itemInfo.Quality then
            local qualityIcon = self.createSprite(QualityIconPath[itemInfo.Quality], 
                {x = 0, y = 0}, {itemIcon, {x = 0, y = 0}})
        end
        itemIcon:setScale(0.6)
        
        local lblCount = self.createBMLabel("fonts/shop.fnt", 
            i, {x = 100, y = 32}, {spr, {x = 1, y = 0.5}})
            
        local lblName =  self.createLabel(itemInfo.Item_Name, nil, 
            {x = 105, y = 70},nil, {spr, {x = 0, y = 0.5}})   
        lblName:setColor(ColorBlack)
        
        local lbl =  self.createLabel("单价：", nil, 
            {x = 105, y = 35},nil, {spr, {x = 0, y = 0.5}})   
        lbl:setColor(ColorBlack)

        self.createSprite("UI/shop/zz.png", 
            {x = 205, y = 35}, {spr})
            
        self.createSprite("UI/shop/xg.png", 
            {x = 34, y = 76}, {spr})
            
        local lblPrice = self.createLabel(200, nil, 
            {x = 190, y = 35},nil, {spr, {x = 0, y = 0.5}})   
        lblPrice:enableOutline(ColorBlack, 2)
        
        btn = self.createButton{title = "购 买",
            ignore = false, 
            pos = {x = 130, y = 0},
            icon = "UI/pve/kstz.png",
            handle = nil,
            parent = spr}
        btn:setPreferredSize({width = 100, height = 40})
    end
end

return UIShop