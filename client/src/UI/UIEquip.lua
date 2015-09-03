local comm = require("common.CommonFun")
local UIMessage = require "UI.UIMessage"

local UIEquip = class("UIEquip", function()
    return require("UI.UIBaseLayer").create()
end)

local starPath = {
    [1] = {"UI/equip/star0.png", "UI/equip/star1.png"},
    [2] = {"UI/equip/star0.png", "UI/equip/star2.png"},
    [3] = {"UI/equip/1yl.png", "UI/equip/1yl1.png"},
    [4] = {"UI/equip/1yl.png", "UI/equip/1yl2.png"},
    [5] = {"UI/equip/3ty.png", "UI/equip/3ty1.png"},
    [6] = {"UI/equip/3ty.png", "UI/equip/3ty2.png"},
}

local colorStr = {
    "灰色品质",
    "绿色品质",
    "蓝色品质",
    "紫色品质",
    "橙色品质"
}

function UIEquip.create()
    local layer = UIEquip.new()
    return layer
end

function UIEquip:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
    self.schedulerID = nil
    self:createBack()
    self:setSwallowTouch()
    local sprite = self.createSprite("UI/equip/kk.png", 
        {x = 230, y= 318}, {self.nodeMid})
    sprite:setLocalZOrder(-1)
    sprite:setScaleY(1.1)
    
    sprite = self.createSprite("UI/bag/dw2.png", 
        {x = 610, y = 315}, {self.nodeMid})
    sprite:setLocalZOrder(-1)
    sprite:setScaleX(1.4)
    self.createSprite("UI/common/split.png", {x = 365, y = 318}, {self.nodeMid})
    self.createLabel(Lang.Equip, 24, {x = 370, y = 550}, nil, {self.nodeMid})
    
    self:createEquip()
    self:createUpgrade()
    self:createInlay()
    self:createStar()
    self:createRightTab()

    local function onNodeEvent(event)
        local hud = cc.Director:getInstance():getRunningScene().hud
        if "enter" == event then
            --[[if MgrGuideStep == 23 then
                hud:closeUI("UIGuide")
                local ui = hud:openUI("UIGuide")
                ui:createWidgetGuide(self.btnIntensifyBack, 
                    "UI/equip/btnback0.png", true)
            end]]
        elseif "exit" == event then
            --[[if MgrGuideStep == 23 then
                hud:closeUI("UIGuide")
                local main = hud:getUI("UIMainLayer")  
                main.UpdateGuide()    
            end]]
        end
    end
    self:registerScriptHandler(onNodeEvent)
end

function UIEquip:createRightTab()
    local function onBtnTabTouched(sender, type)
        self.nodeUpgrade:setVisible(sender == self.btnUpgrade)
        self.nodeStar:setVisible(sender == self.btnStar)
        self.nodeInlay:setVisible(sender == self.btnInlay)
        self.btnUpgrade:setEnabled(sender ~= self.btnUpgrade)
        self.btnStar:setEnabled(sender ~= self.btnStar)
        self.btnInlay:setEnabled(sender ~= self.btnInlay) 
    end

    local size = self.visibleSize

    self.createSprite("UI/character/tabBack.png", {x = 866, y = 317.5}, {self.nodeMid})

    self.btnUpgrade = self.createButton{title = "升 \n\n级",
        pos = { x = 855, y = 430},
        handle = onBtnTabTouched,
        parent = self.nodeMid}
    self.btnUpgrade:setRotation(-8)
    self.btnUpgrade:setTitleColorForState({r = 0, g = 255, b = 0}, cc.CONTROL_STATE_DISABLED)
    local lbl = self.btnUpgrade:getTitleLabelForState(cc.CONTROL_STATE_NORMAL)
    self.btnUpgrade:needsLayout()

    self.btnStar = self.createButton{ title = "升\n\n星",
        pos = { x = 865, y = 285},
        handle = onBtnTabTouched,
        parent = self.nodeMid}
    self.btnStar:setTitleColorForState({r = 0, g = 255, b = 0}, cc.CONTROL_STATE_DISABLED)
    lbl = self.btnStar:getTitleLabelForState(cc.CONTROL_STATE_NORMAL)
    self.btnStar:needsLayout()

    self.btnInlay = self.createButton{ title = "镶\n\n嵌",
        pos = { x = 855, y = 140},
        handle = onBtnTabTouched,
        parent = self.nodeMid}
    self.btnInlay:setRotation(5)
    self.btnInlay:setTitleColorForState({r = 0, g = 255, b = 0}, cc.CONTROL_STATE_DISABLED)
    lbl = self.btnInlay:getTitleLabelForState(cc.CONTROL_STATE_NORMAL)
    self.btnInlay:needsLayout()

    onBtnTabTouched(self.btnUpgrade, nil)
end

function UIEquip:createEquip()
    local nodeEquip = cc.Node:create()
    self.nodeEquip = nodeEquip
    self.nodeMid:addChild(nodeEquip)

    self.EquipWidget = {}

    local function onEquipTouched(sender, event)
        self.selectedBagPos = sender:getTag()
        self.selectedInlayedStone = 0
        self.selectedStonePos = 0
        self:UpdateUpgrade()
        self:UpdateStar()
        self:UpdateInlay()

        for i = 2, 4 do
            self.EquipWidget[i].selectedEff:setVisible(self.selectedBagPos == i)
        end
    end
    
    local star0 = "UI/equip/star0.png"
    local star1 = "UI/equip/star1.png"
    local function createEquipCell(idx)
        self.EquipWidget[idx] = {iconEquip = nil, lblName = nil, 
            lblColor = nil, iconStar = {}, selectedEff = nil}

        local btnBack = self.createButton{
            pos = {x = 235, y = 450 - (idx -2 ) * 140},
            icon = "UI/equip/back0.png",
            handle = onEquipTouched,
            parent = self.nodeEquip,
            ignore = false}

        btnBack:setTag(idx)
        btnBack:setZoomOnTouchDown(false)

        self.EquipWidget[idx].selectedEff = self.createSprite(
            "UI/equip/selectBack.png", {x = 106, y = 61}, {btnBack})
        self.EquipWidget[idx].selectedEff:setLocalZOrder(-1)

        local function showHint(sender, event)
            local idx = sender:getTag()
            if idx > 0 then
                local item = maincha.equip[idx]
                local hud = cc.Director:getInstance():getRunningScene().hud
                hud:showHint(EnumHintType.other, item, nil)
            end
        end

        self.EquipWidget[idx].btnBack = self.createButton{
            icon = "UI/equip/no1.png", 
            pos = {x = 50, y = 72}, 
            parent = btnBack, 
            ignore = false,
            handle = showHint}
        self.EquipWidget[idx].btnBack:setZoomOnTouchDown(false) 
        
        self.EquipWidget[idx].iconEquip = self.createSprite("icon/itemIcon/beixin.png", 
            {x = 50, y = 72}, {btnBack})
        
        self.EquipWidget[idx].iconEquip.qualityIcon = 
            self.createSprite(QualityIconPath[1], 
                {x = 0, y = 0}, {self.EquipWidget[idx].iconEquip, {x = 0, y = 0}})
        self.EquipWidget[idx].iconEquip:setScale(0.45)
        local lbl = self.createLabel("一把贱", nil, {x = 90, y = 85}, 
            nil, {btnBack, {x = 0, y = 0.5}})
        lbl:setColor{r = 0, g = 0, b = 0}
        self.EquipWidget[idx].lblName = lbl

        lbl = self.createLabel("白色武器", nil, {x = 90, y = 60}, nil,
            {btnBack, {x = 0, y = 0.5}})
        lbl:setColor{r = 0, g = 0, b = 0}
        self.EquipWidget[idx].lblColor = lbl
        
        local lblEquipLvl = self.createBMLabel(
            "fonts/jinenglv.fnt", 10, {x = 65, y = 58}, {btnBack})
        lblEquipLvl:setScale(0.8)            
        self.EquipWidget[idx].lblEquipLvl = lblEquipLvl
        
        local equipStar = 5
        for i = 1, 10 do
            local posX = 10 + i * 10
            local iconStar = nil
            iconStar = self.createSprite("UI/equip/star1.png", 
                {x = 20 + i * 16, y = 30}, {btnBack})
            iconStar:setScale(0.6)
            self.EquipWidget[idx].iconStar[i] = iconStar
        end
    end
    
    for bagPos = 2, 4 do
        createEquipCell(bagPos)
    end

    self.selectedBagPos = 2
    self:UpdateEquip()
end

function UIEquip:UpdateEquip()
    local function updateEquipCell(idx)
        local equip = maincha.equip[idx]
        if equip then
            local intensify = bit.rshift(equip.attr[3], 16)
            local itemid = equip.id
            local itemInfo = TableItem[itemid]
            local iconPath = "icon/itemIcon/"..itemInfo.Icon..".png"
            self.EquipWidget[idx].iconEquip:setTexture(iconPath) 
            self.EquipWidget[idx].iconEquip.qualityIcon:setTexture(QualityIconPath[itemInfo.Quality])               
            self.EquipWidget[idx].btnBack:setTag(idx)
            self.EquipWidget[idx].lblEquipLvl:setString(intensify)
            self.EquipWidget[idx].lblName:setString(itemInfo.Item_Name)
            self.EquipWidget[idx].lblName:setColor(QualityColor[itemInfo.Quality])
            self.EquipWidget[idx].lblColor:setColor(QualityColor[itemInfo.Quality])
            self.EquipWidget[idx].lblColor:setString(colorStr[itemInfo.Quality])
            self.EquipWidget[idx].iconEquip:setVisible(true)
            self.EquipWidget[idx].lblName:setVisible(true)
            self.EquipWidget[idx].lblColor:setVisible(true)
            self.EquipWidget[idx].lblEquipLvl:setVisible(true)

            local stars = bit.band(equip.attr[3], 0x0000FFFF)
            local starIdx = 1
            if stars > 0 and stars % 10 == 0 then 
                starIdx = math.ceil((stars - 1)/10)
                stars = 10
            else
                starIdx = math.floor(stars/10) + 1
                stars = stars % 10
            end

            local starIconPath = starPath[starIdx]

            for i = 1, 10 do
                if i <= stars then
                    self.EquipWidget[idx].iconStar[i]:setTexture(starIconPath[2])
                else
                    self.EquipWidget[idx].iconStar[i]:setTexture(starIconPath[1])
                end
            end
        else
            self.EquipWidget[idx].iconEquip:setVisible(false)
            self.EquipWidget[idx].iconEquip:setTag(0)
            self.EquipWidget[idx].lblName:setVisible(false)
            self.EquipWidget[idx].lblColor:setVisible(false)
            self.EquipWidget[idx].lblEquipLvl:setVisible(false)

            for i = 1, 10 do
                self.EquipWidget[idx].iconStar[i]:setTexture(starPath[1][1])
            end
        end

        self.EquipWidget[idx].selectedEff:setVisible(self.selectedBagPos == idx)
    end

    for bagPos = 2, 4 do
        updateEquipCell(bagPos)
    end
end

function UIEquip:createEquipInfo(pos, parent, itemID)
    local spriteBack = self.createSprite("UI/equip/k1.png", 
        pos, {parent})      
        
    self.createSprite("UI/equip/no1.png", 
        {x = 76, y = 165}, {spriteBack})
        
    local btnBack = self.createButton{
        icon = "UI/equip/no1.png", 
        pos = {x = 76, y = 165}, 
        parent = spriteBack, 
        ignore = false}
    btnBack:setZoomOnTouchDown(false)
    
    local iconEquip = self.createSprite("icon/itemIcon/beixin.png", 
        {x = 76, y = 165}, {spriteBack})
    iconEquip:setScale(0.45)
    
    iconEquip.qualityIcon = self.createSprite(QualityIconPath[1], 
        {x = 0, y = 0}, {iconEquip, {x = 0, y = 0}})
    
    local lblEquipLvl = self.createBMLabel(
        "fonts/jinenglv.fnt", 10, {x = 90, y = 150}, {spriteBack})
    lblEquipLvl:setScale(0.8)  
    
    local lblName = self.createLabel("一把贱", nil, {x = 76, y = 110}, nil, {spriteBack})
    lblName:setColor{r = 0, g = 0, b = 0}

    local lblColor = self.createLabel("白色武器", nil, {x = 76, y = 80}, nil, {spriteBack})
    lblColor:setColor{r = 0, g = 0, b = 0}  
    
    local lblAttack = self.createLabel("攻击力:20", 16, {x = 76, y = 40}, nil,
        {spriteBack})
    lblAttack:setColor{r = 0, g = 0, b = 0}

    return spriteBack, iconEquip, lblName, lblColor, lblAttack, btnBack, lblEquipLvl
end

function UIEquip:createUpgrade()
    local nodeUpgrade = cc.Node:create()
    self.nodeUpgrade = nodeUpgrade
    self.nodeMid:addChild(nodeUpgrade)
    self.Upgrade = {}
    self.UpNeedItem = {}
    
    local function showHint(sender, event)
        local tag = sender:getTag()
        local equip = maincha.equip[self.selectedBagPos]
        if equip then
            local hud = cc.Director:getInstance():getRunningScene().hud
            if tag == 1 then
                hud:showHint(EnumHintType.other, equip, nil)
            else
                --equip.id = tag
                equip.attr[3] = equip.attr[3] + 0x00010000
                hud:showHint(EnumHintType.other, equip, nil)
                equip.attr[3] = equip.attr[3] - 0x00010000
            end
        end
    end
    
    local spriteBack, iconEquip, lblName, lblColor, lblAttr, btnBack, lblEquipLvl = 
        self:createEquipInfo({x = 500, y = 380}, nodeUpgrade, 0)
    btnBack:registerControlEventHandler(showHint, cc.CONTROL_EVENTTYPE_TOUCH_UP_INSIDE)
    btnBack:setTag(1)
    self.Upgrade[1] = {back = spriteBack, icon = iconEquip, lblName = lblName,
        lblColor = lblColor, lblAttr = lblAttr, btnBack = btnBack, lblEquipLvl = lblEquipLvl}    
    self.createSprite("UI/equip/jiantou.png", 
        {x = 615, y = 380}, {nodeUpgrade})
    
    spriteBack, iconEquip, lblName, lblColor, lblAttr, btnBack, lblEquipLvl = 
        self:createEquipInfo({x = 730, y = 380}, nodeUpgrade, 0)
    btnBack:setTag(2)
    btnBack:registerControlEventHandler(showHint, cc.CONTROL_EVENTTYPE_TOUCH_UP_INSIDE)
    self.Upgrade[2] = {back = spriteBack, icon = iconEquip, lblName = lblName,
        lblColor = lblColor, lblAttr = lblAttr, btnBack = btnBack, lblEquipLvl = lblEquipLvl} 

    self.createSprite("UI/equip/suoxucailiao.png", 
        {x = 550, y = 180}, {nodeUpgrade})
    
    local function onNeedItemTouched(sender, event)
    end
    for i = 1, 3 do
        local item = {}        
        
        local btn = self.createButton{icon = "UI/equip/no0.png",
            ignore = false,
            pos = {x = 400 + i * 75, y = 167}, 
            handle = onNeedItemTouched, 
            parent = nodeUpgrade
        }            
        btn:setZoomOnTouchDown(false)
        item.btnBack = btn
        local icon = self.createSprite("UI/main/bk.png", 
            {x = 400 + i * 75, y = 167}, {nodeUpgrade})
        if i > 1 then
            icon:setScale(0.5)
        end
        item.icon = icon
        
        item.lblNum = self.createLabel("10", 16, 
            {x = 425 + i * 75, y = 150}, nil, {nodeUpgrade, {x = 1, y = 0.5}})  
        item.lblNum:enableOutline(ColorBlack, 2)
        
        self.UpNeedItem[i] = item
    end

    local function onUpgradeTouched(sender, event)
        --[[if MgrGuideStep == 23 then
            local hud = cc.Director:getInstance():getRunningScene().hud
            hud:closeUI("UIGuide")
            local ui = hud:openUI("UIGuide")
            ui:createWidgetGuide(self.btnClose, 
                "UI/common/close.png", false)
        end]]--
        
        local equip = maincha.equip[self.selectedBagPos]
        if equip then
            local intensify = bit.rshift(equip.attr[3], 16)
            local intensifyInfo = TableIntensify[intensify]
            
            if intensify >= maincha.attr.level then
                UIMessage.showMessage(Lang.LevelLimit)
                return
            end
            
            if maincha.attr.shell < intensifyInfo.Money then
                UIMessage.showMessage(Lang.ShellNotEnough)
                return 
            end
            
            if intensifyInfo.Prop1 then
                local item = comm.parseOneItem(intensifyInfo.Prop1)
                local count = comm.getItemCount(item[1])
                if count < item[2] then
                    UIMessage.showMessage(Lang.MaterialNotEnough)
                    return
                end
            end
            
            if intensifyInfo.Prop2 then
                local item = comm.parseOneItem(intensifyInfo.Prop2)
                local count = comm.getItemCount(item[1])
                if count < item[2] then
                    UIMessage.showMessage(Lang.MaterialNotEnough)
                    return
                end
            end
            
            CMD_EQUIP_UPRADE(self.selectedBagPos) 
        end
    end
    
    self.btnIntensifyBack = 
        self.createSprite("UI/equip/btnback0.png", {x = 750, y = 180}, {nodeUpgrade})
    self.btnIntensify = self.createButton{icon = "UI/equip/shengji.png",
        ignore = false,
        pos = {x = 753, y = 180}, 
        handle = onUpgradeTouched, 
        parent = nodeUpgrade
    }
    self.btnIntensifyTitle = 
        self.createSprite("UI/equip/sjj.png", {x = 750, y = 180}, {nodeUpgrade})

    self:UpdateUpgrade()
end

function UIEquip:UpdateUpgrade()
    local equip = maincha.equip[self.selectedBagPos]
    if equip then
        local intensify = bit.rshift(equip.attr[3], 16)
        local itemid = equip.id
        local itemInfo = TableItem[itemid]
        local iconPath = "icon/itemIcon/"..itemInfo.Icon..".png"
        
        local intensifyInfo = TableIntensify[intensify]
        self.UpNeedItem[1].lblNum:setVisible(true)
        self.UpNeedItem[1].lblNum:setString(intensifyInfo.Money)
        self.UpNeedItem[1].icon:setVisible(true)
        self.UpNeedItem[1].btnBack:setVisible(true)
        
        local str = intensifyInfo.Prop1
        if str then
            local begin, last = string.find(str,":")
            local needItemID = tonumber(string.sub(str, 1, begin - 1))
            local needItemNum = tonumber(string.sub(str, begin + 1, string.len(str)))
            local needItemInfo = TableItem[needItemID]
            local needIconPath = "icon/itemIcon/"..needItemInfo.Icon..".png"
            self.UpNeedItem[2].icon:setTexture(needIconPath)
            self.UpNeedItem[2].btnBack:setTag(needItemID)
            self.UpNeedItem[2].lblNum:setVisible(true)
            self.UpNeedItem[2].lblNum:setString(needItemNum)
            self.UpNeedItem[2].icon:setVisible(true)
            self.UpNeedItem[2].btnBack:setVisible(true)
        else
            self.UpNeedItem[2].lblNum:setVisible(false)
            self.UpNeedItem[2].icon:setVisible(false)
            self.UpNeedItem[2].btnBack:setVisible(false)
        end
        
        local str = intensifyInfo.Prop2
        if str then
            local begin, last = string.find(str,":")
            local needItemID = tonumber(string.sub(str, 1, begin - 1))
            local needItemNum = tonumber(string.sub(str, begin + 1, string.len(str)))
            local needItemInfo = TableItem[needItemID]
            local needIconPath = "icon/itemIcon/"..needItemInfo.Icon..".png"
            self.UpNeedItem[3].icon:setTexture(needIconPath)
            self.UpNeedItem[3].btnBack:setTag(needItemID)
            self.UpNeedItem[3].lblNum:setVisible(true)
            self.UpNeedItem[3].lblNum:setString(needItemNum)
            self.UpNeedItem[3].icon:setVisible(true)
            self.UpNeedItem[3].btnBack:setVisible(true)
        else
            self.UpNeedItem[3].lblNum:setVisible(false)
            self.UpNeedItem[3].icon:setVisible(false)
            self.UpNeedItem[3].btnBack:setVisible(false)
        end

        self.Upgrade[1].icon:setTexture(iconPath)
        self.Upgrade[1].icon.qualityIcon:setTexture(QualityIconPath[itemInfo.Quality])
        self.Upgrade[1].lblEquipLvl:setString(intensify)                 
        self.Upgrade[1].lblName:setString(itemInfo.Item_Name)
        self.Upgrade[1].lblColor:setString(colorStr[itemInfo.Quality])
        self.Upgrade[1].lblName:setColor(QualityColor[itemInfo.Quality])
        self.Upgrade[1].lblColor:setColor(QualityColor[itemInfo.Quality])
        self.Upgrade[1].icon:setVisible(true)
        self.Upgrade[1].lblName:setVisible(true)
        self.Upgrade[1].lblColor:setVisible(true)
        self.Upgrade[1].lblEquipLvl:setVisible(true)

        local name, value = comm.calculateEquipAttr(equip.attr, itemid)
        if not name then
            print("error attr:"..itemid)
        end

        self.Upgrade[1].lblAttr:setString(name..":"..value)       

        local nextItemid = itemid
        
        if intensify == itemInfo.Use_level + 4 then
            nextItemid = nextItemid + 1
            self.btnIntensifyBack:setTexture("UI/equip/dz.png")
            self.btnIntensify:setBackgroundSpriteForState(
                ccui.Scale9Sprite:create("UI/equip/jinjie.png"), 
                cc.CONTROL_STATE_NORMAL)
            self.btnIntensifyTitle:setTexture("UI/equip/dzz.png")
        else
            self.btnIntensifyBack:setTexture("UI/equip/btnback0.png")
            self.btnIntensify:setBackgroundSpriteForState(
                ccui.Scale9Sprite:create("UI/equip/shengji.png"), 
                cc.CONTROL_STATE_NORMAL)
            self.btnIntensifyTitle:setTexture("UI/equip/sjj.png")
        end

        local nextItemInfo = TableItem[nextItemid]
        local nextIconPath = "icon/itemIcon/"..nextItemInfo.Icon..".png"
        self.Upgrade[2].icon:setTexture(iconPath)
        self.Upgrade[2].icon.qualityIcon:setTexture(QualityIconPath[nextItemInfo.Quality])
        self.Upgrade[2].lblEquipLvl:setString(intensify+1)    
        self.Upgrade[2].icon:setTag(nextItemid)
        self.Upgrade[2].lblName:setString(nextItemInfo.Item_Name)
        self.Upgrade[2].lblColor:setString(colorStr[nextItemInfo.Quality])
        self.Upgrade[2].lblName:setColor(QualityColor[nextItemInfo.Quality])
        self.Upgrade[2].lblColor:setColor(QualityColor[nextItemInfo.Quality])
        self.Upgrade[2].icon:setVisible(true)
        self.Upgrade[2].lblName:setVisible(true)
        self.Upgrade[2].lblColor:setVisible(true)   
        self.Upgrade[2].lblEquipLvl:setVisible(true)

        equip.attr[3] = equip.attr[3] + 0x00010000
        name, value = comm.calculateEquipAttr(equip.attr, nextItemid)
        self.Upgrade[2].lblAttr:setString(name..":"..value)     
        equip.attr[3] = equip.attr[3] - 0x00010000
    else
        self.Upgrade[1].icon:setVisible(false)
        self.Upgrade[1].lblName:setVisible(false)
        self.Upgrade[1].lblColor:setVisible(false)
        self.Upgrade[2].icon:setVisible(false)
        self.Upgrade[2].lblName:setVisible(false)
        self.Upgrade[2].lblColor:setVisible(false)
        self.Upgrade[2].lblEquipLvl:setVisible(false)
        
        for i = 1, 3 do
            self.UpNeedItem[i].lblNum:setVisible(false)
            self.UpNeedItem[i].icon:setVisible(false)
            self.UpNeedItem[i].btnBack:setVisible(false)
        end
    end
end

function UIEquip:createStar()
    local nodeStar = cc.Node:create()
    self.nodeStar = nodeStar
    self.nodeMid:addChild(nodeStar)
    self.Star = {stars = {}}
    self.UpStar = {}
    
    local function showHint(sender, event)
        local tag = sender:getTag()
        local equip = maincha.equip[self.selectedBagPos]
        if equip then
            local hud = cc.Director:getInstance():getRunningScene().hud
            local stars = bit.band(equip.attr[3], 0x0000FFFF)
            if tag == 1 then
                hud:showHint(EnumHintType.other, equip, nil)
            else
                if stars < 60 then
                    equip.attr[3] = equip.attr[3] + 1        
                end
                hud:showHint(EnumHintType.other, equip, nil)
                if stars < 60 then
                    equip.attr[3] = equip.attr[3] - 1        
                end
            end
        end
    end

    local spriteBack, iconEquip, lblName, lblColor, lblAttr, btnBack, lblEquipLvl = 
        self:createEquipInfo({x = 500, y = 400}, nodeStar, 0)
    self.Star[1] = {back = spriteBack, icon = iconEquip, lblName = lblName,
        lblColor = lblColor, lblAttr = lblAttr, btnBack = btnBack, lblEquipLvl = lblEquipLvl}
    btnBack:setTag(1)
    btnBack:registerControlEventHandler(showHint, cc.CONTROL_EVENTTYPE_TOUCH_UP_INSIDE)
    
    self.createSprite("UI/equip/jiantou.png", 
        {x = 615, y = 400}, {nodeStar})
    
    spriteBack, iconEquip, lblName, lblColor, lblAttr, btnBack, lblEquipLvl = 
        self:createEquipInfo({x = 730, y = 400}, nodeStar, 0)
    self.Star[2] = {back = spriteBack, icon = iconEquip, lblName = lblName,
        lblColor = lblColor, lblAttr = lblAttr, btnBack = btnBack, 
        lblEquipLvl = lblEquipLvl}
    btnBack:setTag(2)
    btnBack:registerControlEventHandler(showHint, cc.CONTROL_EVENTTYPE_TOUCH_UP_INSIDE)
    
    local equipStar = 5
    for i = 1, 10 do
        local posX = 10 + i * 10
        local iconStar = nil
        if i <= 5 then
            iconStar = self.createSprite("UI/equip/star1.png", 
                {x = 400 + i * 40, y = 260}, {nodeStar})
        else
            iconStar = self.createSprite("UI/equip/star0.png", 
                {x = 400 + i * 40, y = 260}, {nodeStar})
        end
        self.Star.stars[i] = iconStar
    end
    
    self.createSprite("UI/equip/suoxucailiao.png", 
        {x = 550, y = 170}, {nodeStar})
    
    local function onNeedItemTouched(sender, event)
    end
        
    for i = 1, 3 do
        local item = {}        
        
        local btn = self.createButton{icon = "UI/equip/no0.png",
            ignore = false,
            pos = {x = 400 + i * 75, y = 157}, 
            handle = onNeedItemTouched, 
            parent = nodeStar
        }            
        btn:setZoomOnTouchDown(false)
        item.btnBack = btn
        local icon = self.createSprite("UI/main/bk.png", 
            {x = 400 + i * 75, y = 157}, {nodeStar})
        if i > 1 then
            icon:setScale(0.5)
        end
        item.icon = icon
        
        item.lblNum = self.createLabel("10", 16, 
            {x = 425 + i * 75, y = 140}, nil, {nodeStar, {x = 1, y = 0.5}})  
        item.lblNum:enableOutline(ColorBlack, 2)
        
        self.UpStar[i] = item
    end

    local function onStarTouched(sender, event)   
        local equip = maincha.equip[self.selectedBagPos]
        if equip then
            local stars = bit.band(equip.attr[3], 0x0000FFFF)
            local starInfo = TableRising_Star[stars]
            
            if stars >= maincha.attr.level then
                UIMessage.showMessage(Lang.LevelLimit)
                return
            end
            
            if maincha.attr.shell < starInfo.Money then
                UIMessage.showMessage(Lang.ShellNotEnough)
                return 
            end
            
            if starInfo.Prop1 then
                local item = comm.parseOneItem(starInfo.Prop1)
                local count = comm.getItemCount(item[1])
                if count < item[2] then
                    UIMessage.showMessage(Lang.MaterialNotEnough)
                    return
                end
            end
            
            if starInfo.Prop2 then
                local item = comm.parseOneItem(starInfo.Prop2)
                local count = comm.getItemCount(item[1])
                if count < item[2] then
                    UIMessage.showMessage(Lang.MaterialNotEnough)
                    return
                end
            end
            CMD_EQUIP_ADDSTAR(self.selectedBagPos)
        end
    end
    
    self.createSprite("UI/equip/btnback0.png", {x = 750, y = 180}, {nodeStar})
    self.createButton{icon = "UI/equip/xing.png",
        ignore = false,
        pos = {x = 753, y = 180}, 
        handle = onStarTouched, 
        parent = nodeStar
    }
    self.createSprite("UI/equip/sxx.png", {x = 750, y = 180}, {nodeStar})
    
    self:UpdateStar()
end

function UIEquip:UpdateStar()
    local equip = maincha.equip[self.selectedBagPos]
    if equip then
        local itemid = equip.id
        local itemInfo = TableItem[itemid]
        local iconPath = "icon/itemIcon/"..itemInfo.Icon..".png"
        local intensify = bit.rshift(equip.attr[3], 16)
        local stars = bit.band(equip.attr[3], 0x0000FFFF)
        
        local starInfo = TableRising_Star[stars]
        self.UpStar[1].lblNum:setVisible(true)
        self.UpStar[1].lblNum:setString(starInfo.Money)
        self.UpStar[1].icon:setVisible(true)
        self.UpStar[1].btnBack:setVisible(true)

        local str = starInfo.Prop1
        if str then
            local begin, last = string.find(str,":")
            local needItemID = tonumber(string.sub(str, 1, begin - 1))
            local needItemNum = tonumber(string.sub(str, begin + 1, string.len(str)))
            local needItemInfo = TableItem[needItemID]
            local needIconPath = "icon/itemIcon/"..needItemInfo.Icon..".png"
            self.UpStar[2].icon:setTexture(needIconPath)
            self.UpStar[2].btnBack:setTag(needItemID)
            self.UpStar[2].lblNum:setVisible(true)
            self.UpStar[2].lblNum:setString(needItemNum)
            self.UpStar[2].icon:setVisible(true)
            self.UpStar[2].btnBack:setVisible(true)
        else
            self.UpStar[2].lblNum:setVisible(false)
            self.UpStar[2].icon:setVisible(false)
            self.UpStar[2].btnBack:setVisible(false)
        end

        local str = starInfo.Prop2
        if str then
            local begin, last = string.find(str,":")
            local needItemID = tonumber(string.sub(str, 1, begin - 1))
            local needItemNum = tonumber(string.sub(str, begin + 1, string.len(str)))
            local needItemInfo = TableItem[needItemID]
            local needIconPath = "icon/itemIcon/"..needItemInfo.Icon..".png"
            self.UpStar[3].icon:setTexture(needIconPath)
            self.UpStar[3].btnBack:setTag(needItemID)
            self.UpStar[3].lblNum:setVisible(true)
            self.UpStar[3].lblNum:setString(needItemNum)
            self.UpStar[3].icon:setVisible(true)
            self.UpStar[3].btnBack:setVisible(true)
        else
            self.UpStar[3].lblNum:setVisible(false)
            self.UpStar[3].icon:setVisible(false)
            self.UpStar[3].btnBack:setVisible(false)
        end

        self.Star[1].icon:setTexture(iconPath)
        self.Star[1].icon.qualityIcon:setTexture(QualityIconPath[itemInfo.Quality])
        self.Star[1].lblEquipLvl:setString(intensify)                 
        self.Star[1].lblName:setString(itemInfo.Item_Name)
        self.Star[1].lblColor:setString(colorStr[itemInfo.Quality])
        self.Star[1].lblName:setColor(QualityColor[itemInfo.Quality])
        self.Star[1].lblColor:setColor(QualityColor[itemInfo.Quality])
        self.Star[1].icon:setVisible(true)
        self.Star[1].lblName:setVisible(true)
        self.Star[1].lblColor:setVisible(true)

        local name, value = comm.calculateEquipAttr(equip.attr, itemid)
        if not name then
            print("error attr:"..itemid)
        end

        self.Star[1].lblAttr:setString(name..":"..value)
        
        local stars = bit.band(equip.attr[3], 0x0000FFFF)
        if stars < 60 then
            equip.attr[3] = equip.attr[3] + 1        
        end
        name, value = comm.calculateEquipAttr(equip.attr, itemid)
        self.Star[2].lblAttr:setString(name..":"..value)
        if stars < 60 then
            equip.attr[3] = equip.attr[3] - 1        
        end

        self.Star[2].icon:setTexture(iconPath)
        self.Star[2].icon.qualityIcon:setTexture(QualityIconPath[itemInfo.Quality])
        self.Star[2].lblEquipLvl:setString(intensify)                 
        self.Star[2].lblName:setString(itemInfo.Item_Name)
        self.Star[2].lblColor:setString(colorStr[itemInfo.Quality])
        self.Star[2].lblName:setColor(QualityColor[itemInfo.Quality])
        self.Star[2].lblColor:setColor(QualityColor[itemInfo.Quality])
        self.Star[2].icon:setVisible(true)
        self.Star[2].lblName:setVisible(true)
        self.Star[2].lblColor:setVisible(true)

        local stars = bit.band(equip.attr[3], 0x0000FFFF)
        local starIdx = 1
        if stars > 0 and stars % 10 == 0 then 
            starIdx = math.ceil((stars - 1)/10)
            stars = 10
        else
            starIdx = math.floor(stars/10) + 1
            stars = stars % 10
        end
        
        local starIconPath = starPath[starIdx]

        for i = 1, 10 do
            if i <= stars then
                self.Star.stars[i]:setTexture(starIconPath[2])
            else
                self.Star.stars[i]:setTexture(starIconPath[1])
            end
        end
    else
        self.Star[1].icon:setVisible(false)
        self.Star[1].lblName:setVisible(false)
        self.Star[1].lblColor:setVisible(false)
        self.Star[2].icon:setVisible(false)
        self.Star[2].lblName:setVisible(false)
        self.Star[2].lblColor:setVisible(false)

        for i = 1, 10 do
            self.EquipWidget[idx].iconStar[i]:setTexture(starPath[1][1])
        end
    end
end

function UIEquip:createJewelNode(pos, parent)
    local function showHint(sender, event)
        local tag = sender:getTag()
        local item = {id = tag}
        if tag ~= 0 then
            local hud = cc.Director:getInstance():getRunningScene().hud
            hud:showHint(EnumHintType.other, item, nil)
        end
    end
    
    local back = self.createButton{
        icon = "UI/equip/no1.png", 
        pos = pos, 
        parent = parent,
        ignore = false,
        handle = showHint}
    back:setZoomOnTouchDown(false)
    
    local iconJewel = self.createSprite("UI/equip/no1.png", pos, {parent}) 
    iconJewel.qualityIcon = self.createSprite(QualityIconPath[1], 
        {x = 0, y = 0}, {iconJewel, {x = 0, y = 0}})
    
    local lblName = self.createLabel("二级宝石", 16, {x = 110, y = 50}, nil, {back})
    self.createSprite("UI/equip/splitLine.png", {x = 110, y = 35}, {back}) 
    lblName:setColor{r = 0, g = 0, b = 255}
    local lblAttr = self.createLabel("攻击力 +12", 18, {x = 110, y = 20}, nil, {back})
    lblAttr:setColor{r = 0, g = 0, b = 255}

    return back, iconJewel, lblName, lblAttr    
end
 
function UIEquip:createInlay()
    local nodeInlay = cc.Node:create()
    self.nodeInlay = nodeInlay
    self.nodeMid:addChild(nodeInlay)
    self.InlayedJewel = {}
    self.selectedStonePos = 0
    self.selectedInlayedStone = 0
    
    self.createSprite("UI/equip/bsk.png", 
        {x = 620, y = 330}, {nodeInlay})

    local function onInlayTouched(sender, event)
        local equip = maincha.equip[self.selectedBagPos]
        if equip and #self.CanInlayJewel > 0 then
            local inlayedJewel1 = bit.rshift(equip.attr[1], 16)
            local inlayedJewel2 = bit.band(equip.attr[1], 0x0000FFFF)
            local inlayedJewel3 = bit.rshift(equip.attr[2], 16)
            local inlayedJewel4 = bit.band(equip.attr[2], 0x0000FFFF)

            local inlayPos = 0
            if inlayedJewel1 == 0 then
                inlayPos = 1            
            elseif maincha.attr.level >= 30 and inlayedJewel2 == 0 then
                inlayPos = 2
            elseif maincha.attr.level >= 40 and inlayedJewel3 == 0 then
                inlayPos = 3
            elseif maincha.attr.level >= 50 and inlayedJewel4 == 0 then
                inlayPos = 4
            end

            if inlayPos > 0 then
                local item = maincha.bag[self.CanInlayJewel[self.selectedStonePos]]
                self.selectedStonePos = 0
                CMD_EQUIP_INSET(self.selectedBagPos, inlayPos, 
                    item.id)
            else
                UIMessage.showMessage(Lang.NoJewelInlay)
            end
        end 
    end

    local function onUninlayTouched(sender, event)
        local equip = maincha.equip[self.selectedBagPos]
        if equip then
            local inlayedJewel1 = bit.rshift(equip.attr[1], 16)
            local inlayedJewel2 = bit.band(equip.attr[1], 0x0000FFFF)
            local inlayedJewel3 = bit.rshift(equip.attr[2], 16)
            local inlayedJewel4 = bit.band(equip.attr[2], 0x0000FFFF)

            local inlayPos = 0
            if inlayedJewel1 ~= 0 and 
                self.selectedInlayedStone == 1 then
                inlayPos = 1            
            elseif maincha.attr.level >= 30 and inlayedJewel2 ~= 0 
                and self.selectedInlayedStone == 2 then
                inlayPos = 2
            elseif maincha.attr.level >= 40 and inlayedJewel3 ~= 0 
                and self.selectedInlayedStone == 3 then
                inlayPos = 3
            elseif maincha.attr.level >= 50 and inlayedJewel4 ~= 0
                and self.selectedInlayedStone == 4 then
                inlayPos = 4
            end
            if inlayPos > 0 then
                self.selectedInlayedStone = 0
                CMD_CG_EQUIP_UNINSET(self.selectedBagPos, inlayPos)
            else
                UIMessage.showMessage(Lang.NoJewelUninlay)
            end
        end
    end
        
    self.createButton{title = "卸 下",
        icon = "UI/common/k.png",
        ignore = false,
        pos = {x = 530, y = 150}, 
        handle = onUninlayTouched, 
        parent = nodeInlay
    }
    
    self.createButton{title = "镶 嵌",
        icon = "UI/common/k.png",
        ignore = false,
        pos = {x = 715, y = 150}, 
        handle = onInlayTouched, 
        parent = nodeInlay
    }
    
    local function onInlayedStoneTouched(sender, event)
        local equip = maincha.equip[self.selectedBagPos]
        if not equip then 
            return 
        end
        
        local inlayedStone = {
            bit.rshift(equip.attr[1], 16),
            bit.band(equip.attr[1], 0x0000FFFF),
            bit.rshift(equip.attr[2], 16),
            bit.band(equip.attr[2], 0x0000FFFF)
        }
        
        local idx = sender:getTag()
        if inlayedStone[idx] > 0 then
            if self.selectedInlayedStone > 0 then
                local beforeSel = self.selectedInlayedStone 
                self.InlayedJewel[beforeSel].btnBack:setOpacity(0)
            end
            self.selectedInlayedStone = idx
            self.InlayedJewel[idx].btnBack:setOpacity(255)
        end
    end

    for i = 1, 4 do
        local back, icon, lblName, lblAttr = 
            self:createJewelNode({x = 480, y = 510 - i * 70}, nodeInlay)
        self.InlayedJewel[i] = {back = back, icon = icon, 
            lblName = lblName, lblAttr = lblAttr}
        self.InlayedJewel[i].btnBack = self.createButton{
            icon = "UI/equip/selectIcon.png",
            pos = {x = -5, y = 0},
            parent = self.InlayedJewel[i].back,
            handle = onInlayedStoneTouched
            }
        self.InlayedJewel[i].btnBack:setTag(i)
        self.InlayedJewel[i].btnBack:setZoomOnTouchDown(false)
        self.InlayedJewel[i].btnBack:setLocalZOrder(-1)
        self.InlayedJewel[i].btnBack:setOpacity(0)
    end
    -- -----------------------------------------------------   
    
    local function numOfCells(table)
        return #self.CanInlayJewel
    end

    local function sizeOfCellIdx(table, idx)
        return 70, 460  --left->height, right->width
    end

    local function cellOfIdx(table, idx)
        local cell = table:dequeueCell()    

        if cell == nil then
            cell = cc.TableViewCell:create()
            local back, icon, lblName, lblAttr = 
                self:createJewelNode({x = 31, y = 31}, cell)
            cell.back = back
            cell.icon = icon
            cell.selEff = self.createSprite("UI/equip/selectIcon.png", 
                {x = -10, y = 0}, {cell, {x = 0, y = 0}}) 
            cell.selEff:setLocalZOrder(-1)
            cell.icon:setScale(0.45)
            cell.lblName = lblName
            cell.lblAttr = lblAttr
            cell.lblNum = self.createBMLabel(
                "fonts/exp.fnt", 0, {x = 55, y = 15}, {cell})
            --cell.lblNum:setScale(0.8)
        end
        
        local item = maincha.bag[self.CanInlayJewel[idx+1]]
        local itemid = item.id
        local itemInfo = TableItem[itemid]
        local iconPath = "icon/itemIcon/"..itemInfo.Icon..".png"

        cell.icon:setTexture(iconPath) 
        cell.icon.qualityIcon:setTexture(QualityIconPath[itemInfo.Quality])
        cell.selEff:setVisible(self.selectedStonePos - 1 == idx)
        cell.back:setTag(itemid)
        cell.lblName:setString(itemInfo.Item_Name)
        local attrName, attrValue = comm.getJewelAttrValue(itemid)
        cell.lblAttr:setString(attrName.."+"..attrValue)     
        cell.lblNum:setString(item.count)   
        return cell
    end

    local function onCellTouched(table, tableviewcell)
        local cellIdx = tableviewcell:getIdx()
        table:updateCellAtIndex(self.selectedStonePos - 1)
        self.selectedStonePos = cellIdx + 1
        table:updateCellAtIndex(cellIdx)
    end

    local tableJewel = cc.TableView:create({width = 460, height = 280})
    tableJewel:setDelegate()
    tableJewel:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    tableJewel:setPosition(635, 200)
    tableJewel:registerScriptHandler(numOfCells, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
    tableJewel:registerScriptHandler(sizeOfCellIdx, cc.TABLECELL_SIZE_FOR_INDEX)
    tableJewel:registerScriptHandler(onCellTouched, 
        cc.Handler.TABLECELL_TOUCHED - cc.Handler.SCROLLVIEW_SCROLL)
    tableJewel:registerScriptHandler(cellOfIdx, 
        cc.Handler.TABLECELL_AT_INDEX - cc.Handler.SCROLLVIEW_SCROLL)   --TODO cocos2dx lua bug
    nodeInlay:addChild(tableJewel)
    self.tableJewel = tableJewel
    self:UpdateInlay()
end

function UIEquip:UpdateInlay()
    local equip = maincha.equip[self.selectedBagPos]
    if equip then
        local inlayedJewel1 = bit.rshift(equip.attr[1], 16)
        local inlayedJewel2 = bit.band(equip.attr[1], 0x0000FFFF)
        local inlayedJewel3 = bit.rshift(equip.attr[2], 16)
        local inlayedJewel4 = bit.band(equip.attr[2], 0x0000FFFF)        

        local function updateNode(locked, itemid, jewelNode)
            local lockIcon = {[30] = "UI/equip/unlock30.png",
                [40] = "UI/equip/unlock40.png",
                [50] = "UI/equip/unlock50.png"}

            if locked > 0 then
                jewelNode.icon:setTexture(lockIcon[locked])
                jewelNode.icon:setScale(1)
                jewelNode.icon.qualityIcon:setVisible(false)
                jewelNode.back:setTag(0)
                jewelNode.lblName:setString("")
                jewelNode.lblAttr:setString("")
                jewelNode.btnBack:setOpacity(0)
            else
                local itemInfo = TableItem[itemid]
                if itemInfo then
                    local iconPath = "icon/itemIcon/"..itemInfo.Icon..".png"
                    jewelNode.icon:setTexture(iconPath)                    
                    jewelNode.back:setTag(itemid)
                    --jewelNode.icon:setPreferredSize{width = 150, height = 150}
                    jewelNode.icon:setScale(0.45)
                    jewelNode.icon.qualityIcon:setVisible(true)
                    jewelNode.icon.qualityIcon:setTexture(QualityIconPath[itemInfo.Quality])
                    jewelNode.lblName:setString(itemInfo.Item_Name)
                    local attrName, attrValue = comm.getJewelAttrValue(itemid)
                    jewelNode.lblAttr:setString(attrName.."+"..attrValue)   
                else
                    jewelNode.icon:setTexture("UI/equip/add.png")
                    jewelNode.back:setTag(0)
                    jewelNode.icon:setScale(1)
                    jewelNode.icon.qualityIcon:setVisible(false)
                    --jewelNode.icon:setPreferredSize{width = 52, height = 51}
                    jewelNode.lblName:setString("")
                    jewelNode.lblAttr:setString("")
                    jewelNode.btnBack:setOpacity(0)
                end
            end
        end

        updateNode(0, inlayedJewel1, self.InlayedJewel[1])   
        local alpha = 0
        if self.selectedInlayedStone == 1 then
            alpha = 255 
        end
        self.InlayedJewel[1].btnBack:setOpacity(alpha)
        
        local inlayedJewel = {inlayedJewel1, inlayedJewel2, 
            inlayedJewel3, inlayedJewel4}
        self.InlayedJewel[1].back:setVisible(true)
        for i = 2, 4 do 
            self.InlayedJewel[i].back:setVisible(true)
            local lockLevel = (i + 1)* 10
            if maincha.attr.level < lockLevel then
                updateNode(lockLevel, 0, self.InlayedJewel[i]) 
            else
                updateNode(0,  inlayedJewel[i], self.InlayedJewel[i]) 
            end    
                    
            alpha = 0
            if self.selectedInlayedStone == 1 then
                alpha = 255 
            end                     
            self.InlayedJewel[i].btnBack:setOpacity(alpha)
        end  
    else
        for i = 1, 4 do
            self.InlayedJewel[i].back:setVisible(false)
        end
    end

    self.CanInlayJewel = {}
    
    if equip then
        local equipType = TableItem[equip.id].Item_Type
        for i = 1, #maincha.bag do
            local item = maincha.bag[i]
            local jewelInfo = TableStone[item.id]
            if jewelInfo and jewelInfo.Seat == equipType then
                table.insert(self.CanInlayJewel, i)
            end
        end
    end
    self.tableJewel:reloadData()
end

return UIEquip