local UIPopupGetItem  = class("UIPopupGetItem", function()
    return require("UI.UIBaseLayer").create()
end)

function UIPopupGetItem.create()
    local layer = UIPopupGetItem.new()
    return layer
end

function UIPopupGetItem:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
    self.schedulerID = nil
end

function UIPopupGetItem.showItems(items)
    local hud = cc.Director:getInstance():getRunningScene().hud
    local ui = hud:getUI("UIPopupGetItem")
    if ui then
        hud:closeUI("UIPopupGetItem")
    end        

    ui = hud:openUI("UIPopupGetItem")
    ui:createBack(items)
end

function UIPopupGetItem:createBack(items)
    local midPos = cc.p(self.visibleSize.width/2, self.visibleSize.height/2)
    
    local preH = 100 + #items * 120
    local back = self.createScale9Sprite("UI/sign/tipBack.png",
        midPos, {width = 400, height = preH}, {self})
    back:setOpacity(230)
    back:setAnchorPoint(0.5, 0.5)
    
    local titlePos = cc.pAdd(midPos, cc.p(0, preH/2-40))
    local bkTitle = self.createSprite("UI/sign/yuefen.png", 
        titlePos, {self})
    bkTitle:setScale(0.7)
    
    local lbl = self.createLabel("获得物品", 22, 
        titlePos, nil, {self})
    lbl:setColor{r = 254, g = 255, b = 196}

    local beginPos = cc.pAdd(titlePos, cc.p(0, 30))
    for i = 1, #items do
        local itemBack = self.createSprite("UI/sign/kk.png", 
            cc.pSub(beginPos,cc.p(0, 120*i)), {self})
            
        local itemInfo = TableItem[items[i].id]
        local iconPath = "icon/itemIcon/"..itemInfo.Icon..".png"
        local icon = self.createSprite(iconPath, 
            {x = 60, y = 54.5}, 
            {itemBack})  
        
        if itemInfo.Quality then
            icon.qualityIcon = 
                self.createSprite(QualityIconPath[itemInfo.Quality], 
                    {x = 0, y = 0}, {icon, {x = 0, y = 0}})
        end
        
        icon:setScale(0.5)
        self.createLabel(itemInfo.Item_Name, 20, 
            {x = 110, y = 54.5}, nil, {itemBack, {x = 0, y = 0.5}})
        self.createLabel("x "..items[i].count, 20, 
            {x = 240, y = 54.5}, nil, {itemBack, {x = 0, y = 0.5}})
    end
end

return UIPopupGetItem