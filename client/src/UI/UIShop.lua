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
    self:UpdateUI(1)
    local size = self.scrollView:getContentSize()
    self.scrollView:setContentOffset{x = 0, y = 360-size.height}  
    
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
    self.itemWidget = {}
    
    local size = self.visibleSize
    self.createSprite("UI/sign/dkyy.png", {x = 0, y = 0}, {self.nodeMid, {x = 0, y = 0}})
    if self.visibleSize.width/self.visibleSize.height < 1.5 then
        self.nodeMid:setScale(0.9)
        self.nodeMid:setPositionX(0)
    end

    self.createSprite("UI/sign/yuefen.png", {x = 500, y = 550}, {self.nodeMid})
    self.createLabel("商  城", 26, 
        {x = 500, y = 550}, nil, {self.nodeMid})
        
    local function onBtnTypeTouched(sender, event)        
        self:UpdateUI(sender:getTag())
        local size = self.scrollView:getContentSize()
        self.scrollView:setContentOffset{x = 0, y = 360-size.height}   
    end
        
    local btn = self.createButton{title = "道 具",
        pos = {x = 220, y = 460},
        icon = "UI/shop/clk.png",
        handle = onBtnTypeTouched,
        parent = self.nodeMid}
    btn:setPreferredSize({width = 120, height = 45})
    btn:setTag(1)
    
    btn = self.createButton{title = "材 料",
        pos = {x = 350, y = 460},
        icon = "UI/shop/clk.png",
        handle = onBtnTypeTouched,
        parent = self.nodeMid}
    btn:setPreferredSize({width = 120, height = 45})
    btn:setTag(2)
    
    local count = 20
    local scrollView = cc.ScrollView:create({width = 600, height = 360})
    self.scrollView = scrollView
    self.nodeMid:addChild(scrollView)
    scrollView:setPosition(225,100)
    scrollView:setDirection(1)    
    self:createWidget(5)
    local size = scrollView:getContentSize()
    --scrollView:setContentOffset{x = 0, y = 360-size.height}   
end

function UIShop:createWidget(count)
    local contenHeight = math.ceil(count/2) * 130
    local scrollView = self.scrollView 
    scrollView:setContentSize({width = 600, height = contenHeight})
    local createdCount = #self.itemWidget 
    
    if createdCount < count then
        for i = 1, createdCount do
            local pos = {x = 310 * (((i-1) % 2)), 
                y = (math.ceil(count/2)-math.floor((i-1)/2) - 1)*130+20}
            self.itemWidget[i].back:setPosition(pos)
        end
        
        for i = createdCount+1, count do
            local widget = {}
            local pos = {x = 310 * (((i-1) % 2)), 
                y = (math.ceil(count/2)-math.floor((i-1)/2) - 1)*130+20}
            local spr = self.createSprite("UI/shop/xk.png", 
                pos, 
                {scrollView, {x = 0, y = 0}})
            print(i..":".." x:"..pos.x.." y:"..pos.y)
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

            local iconLimit = self.createSprite("UI/shop/xg.png", 
                {x = 34, y = 76}, {spr})
            
            local lblPrice = self.createLabel(200, nil, 
                {x = 190, y = 35}, nil, {spr, {x = 0, y = 0.5}})   
            lblPrice:enableOutline(ColorBlack, 2)
            
            local btn = self.createButton{title = "购 买",
                ignore = false, 
                pos = {x = 130, y = 0},
                icon = "UI/pve/kstz.png",
                handle = nil,
                parent = spr}
            btn:setPreferredSize({width = 100, height = 40})        
            btn:setTag(i)
            
            widget.back = spr
            widget.itemIcon = itemIcon
            widget.lblCount = lblCount
            widget.lblName = lblName
            widget.iconLimit = iconLimit
            widget.lblPrice = lblPrice
            self.itemWidget[i] = widget
        end
    else
        for i = count + 1, createdCount do
            self.itemWidget[i].back:setVisible(false)
        end
    end
end

function UIShop:UpdateUI(type)
    local shopids = {}
    if self.curType == type then
        return
    end
    self.curType = type
    for i = 1, #TableShop do
        if TableShop[i].Type == type then
            table.insert(shopids, i)
        end
    end
    
    self:createWidget(#shopids)
    for i = 1, #shopids do
        local shopInfo = TableShop[shopids[i]]
        local itemInfo = TableItem[shopInfo.Goods_ID]
        local widget = self.itemWidget[i]
        widget.back:setVisible(true)        
        widget.itemIcon:setTexture("icon/itemIcon/"..itemInfo.Icon..".png")
        widget.lblCount:setString(shopInfo.Number or "")
        widget.lblName:setString(itemInfo.Item_Name)
        widget.iconLimit:setVisible(shopInfo.Conditions == 1)
        widget.lblPrice:setString(shopInfo.Price)
    end
end

return UIShop