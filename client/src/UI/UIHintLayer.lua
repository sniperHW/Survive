local comm = require "common.CommonFun"
local UIHintLayer = class("UIHintLayer", function()
    return require("UI.UIBaseLayer").create()
end)

function UIHintLayer.create()
    local layer = UIHintLayer.new()
    return layer
end

local EnumBtnTag = {
    {tag = 1, str = "强化"},
    {tag = 2, str = "升星"},
    {tag = 3, str = "镶嵌"},
    {tag = 4, str = "穿戴"},
    {tag = 5, str = "使用"},
    {tag = 6, str = "出售"},
    {tag = 7, str = "兑换"},
    {tag = 8, str = "合成"},
    {tag = 9, str = "携带"},
    {tag = 10, str = "卸下"}
}

local EnumBtnType = {
    Intensify = 1,
    Star = 2,
    Inlay = 3,
    Equip = 4,
    Use = 5,
    Sell = 6,
    Exchange = 7,
    Compound = 8,
    Take = 9,
    Unload = 10
}

local starPath = {
    [1] = {"UI/equip/star0.png", "UI/equip/star1.png"},
    [2] = {"UI/equip/star0.png", "UI/equip/star2.png"},
    [3] = {"UI/equip/1yl.png", "UI/equip/1yl1.png"},
    [4] = {"UI/equip/1yl.png", "UI/equip/1yl2.png"},
    [5] = {"UI/equip/3ty.png", "UI/equip/3ty1.png"},
    [6] = {"UI/equip/3ty.png", "UI/equip/3ty2.png"},
}

function UIHintLayer:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
    self.schedulerID = nil

    local function onTouchBegan(touch, event)
        local touchPos = touch:getLocation()
        local nodePos = self:convertToNodeSpace(touchPos)
        local box = self.back:getBoundingBox()
        local contain = cc.rectContainsPoint(box, nodePos)

        if not contain then
            cc.Director:getInstance():getRunningScene().hud:closeUI(self.class.__cname)
        end

        return contain
    end

    local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN)
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
end

local startPosX = 20
local interval = 5
local interS = 5
function UIHintLayer:showHint(source, itemIdx)
    local item = nil
	if source == EnumHintType.bag then
	   item = maincha.bag[itemIdx]
	elseif source == EnumHintType.body then
        item = maincha.equip[itemIdx]
    elseif source == EnumHintType.other then
        item = itemIdx
	end
	
	if item then
        self.source = source
	    self.item = item
        self.back = self.createScale9Sprite("UI/common/tip.png", {x = 0, y = 0},
            {width = 320, height = 400}, {self, {x = 0, y = 1}})
        local itemInfo = TableItem[item.id]
        local height = 0 
        if itemInfo.Item_Type > 0 and itemInfo.Item_Type <= 4 then  --装备
            height = self:createEquip(item)
        elseif itemInfo.Item_Type == 6 then --宝石
            height = self:createJewel(item)
        else
            height = self:createItem(item)
        end
        if height > 0 then
            self.back:setPreferredSize({width = 320, height = height})
            return 400, height    
        end
	end

	return nil
end 

function UIHintLayer:createBtn(btns, posY)
    if self.source == EnumHintType.other then
        return
    end

    local function handle(sender, event)
        local tag = sender:getTag()
        if tag == EnumBtnType.Intensify then
        elseif tag == EnumBtnType.Star then
        elseif tag == EnumBtnType.Inlay then
        elseif tag == EnumBtnType.Equip then
            local itemInfo = TableItem[self.item.id]
            if itemInfo.Item_Type > 0 and itemInfo.Item_Type <= 4 then
                CMD_CG_SWAP(self.item.bagpos, itemInfo.Item_Type)
            end
        elseif tag == EnumBtnType.Use then
            CMD_CG_USEITEM(self.item.bagpos)
        elseif tag == EnumBtnType.Sell then
            CMD_CG_USEITEM(self.item.bagpos)
        elseif tag == EnumBtnType.Exchange then
        elseif tag == EnumBtnType.Compound then
        elseif tag == EnumBtnType.Take then
            local nilPos = 0
            for i = 5, 10 do
                if maincha.equip[i] == nil then
                    nilPos = i
                    break
                end
            end
            if nilPos > 0 then
                CMD_LOADBATTLEITEM(self.item.bagpos)
            end
        elseif tag == EnumBtnType.Unload then
            local nilPos = 0
        
            for i = 11, 11 + #maincha.bag do
                local bFind = false
                for k, v in pairs(maincha.bag) do
                    if v.bagpos == i then
                        bFind = true
                        break
                    end
                end
                if not bFind then
                    nilPos = i
                end
            end

            if nilPos > 0 then
                CMD_UNLOADBATTLEITEM(self.item.bagpos)
            end
        end
        cc.Director:getInstance():getRunningScene().hud:closeUI(self.class.__cname)
    end
    
    local startx = -80
    local intervelY = 40
    
    for i = 1, #btns do
        local btn = self.createButton{pos = {x = startx + i * 100, y = posY-30},
            title = EnumBtnTag[btns[i]].str,
            icon = "UI/common/k.png",
            handle = handle,
            parent = self
        }
        btn:setPreferredSize({width = 80, height = 40})
        --btn:setAnchorPoint({x = 0, y = 1})
        btn:setTitleColorForState({r = 167, g = 70, b = 0}, cc.CONTROL_STATE_NORMAL)
        btn:setTag(EnumBtnTag[btns[i]].tag)
        --posY = posY - intervelY
    end
end 

function UIHintLayer:createEquip(item)
    local itemInfo = TableItem[item.id]
    local nextPosY = self:createIconName(item.id)

    local stars = bit.band(item.attr[3], 0x0000FFFF)
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
        local iconstar = nil
        if i <= stars then
            iconstar = self.createSprite(starIconPath[2], 
                    {x = 110 + i * 18, y = -80}, {self})
        else
            iconstar = self.createSprite(starIconPath[1], 
                    {x = 110+ i * 18, y = -80}, {self})
        end
        iconstar:setScale(0.5)
    end

    nextPosY = self:createBaseInfo(item, nextPosY)
    
    --attr
    local lbl = self.createLabel("装备属性: ", 18,
        {x = startPosX, y = nextPosY}, nil, {self, {x = 0, y = 1}})
   lbl:setColor(QualityColor[itemInfo.Quality])
    nextPosY = nextPosY - lbl:getContentSize().height

    local name, value, attrIdx = comm.calculateEquipAttr(item.attr, item.id)
    local equipInfo = TableEquipment[item.id]

    lbl = self.createLabel(name..": "..equipInfo[attrIdx], 18,
        {x = startPosX, y = nextPosY}, nil, {self, {x = 0, y = 1}})
    lbl:setColor(QualityColor[itemInfo.Quality])

    local lblWidth = lbl:getContentSize().width
    lbl = self.createLabel("+"..value - equipInfo[attrIdx], 18,
        {x = startPosX + lblWidth , y = nextPosY}, nil, {self, {x = 0, y = 1}})
    lbl:setColor({r = 57, g = 134, b = 131})
    
    local jewels = {
        bit.rshift(item.attr[1], 16),
        bit.band(item.attr[1], 0x0000FFFF),
        bit.rshift(item.attr[2], 16),
        bit.band(item.attr[2], 0x0000FFFF)
    }
    
    local attrValue, attrName
    for i = 1, #jewels do
        if jewels[i] > 0 then
            local name, attr, jewelAttrIdx = comm.getJewelAttrValue(jewels[i])
            if name and attr and jewelAttrIdx and jewelAttrIdx ~= attrIdx then
                attrValue = attrValue + attr
                attrName = name
            end        
        end
    end
    
    if attrValue and attrValue > 0 then
        lbl = self.createLabel(attrName, 18,
            {x = 260, y = nextPosY}, nil, {self, {x = 1, y = 1}})
        lbl:setColor(ColorBlack)

        lbl = self.createLabel(attrValue.."%", 18,
            {x = 265, y = nextPosY}, nil, {self, {x = 0, y = 1}})
        lbl:setColor({r = 57, g = 134, b = 131})        
    end

    nextPosY = nextPosY - lbl:getContentSize().height - interval
    
    if item.attr[1] + item.attr[2] > 0 then
        lbl = self.createLabel("镶嵌宝石: ", 18,
            {x = startPosX, y = nextPosY}, nil, {self, {x = 0, y = 1}})
        lbl:setColor(QualityColor[itemInfo.Quality])
        nextPosY = nextPosY - lbl:getContentSize().height

        for i = 1, #jewels do
            local jewelInfo = TableItem[jewels[i]]        
            if jewelInfo then
                local iconPath = "icon/itemIcon/"..jewelInfo.Icon..".png"
                local iconItem = self.createSprite(iconPath, 
                    {x = startPosX + (i - 1) * 40, y = nextPosY}, {self, {x = 0, y = 1}})
                iconItem:setScale(0.3)
            end
        end
        nextPosY = nextPosY - 50
    end

    --end attr
    
    nextPosY = self:createItemDes(itemInfo.Item_Describe, nextPosY)
    nextPosY = self:createSellPrice(item, nextPosY) 
    if self.source ~= EnumHintType.other then
        if self.item.bagpos <= 10 then
            self:createBtn({EnumBtnType.Intensify, 
                    EnumBtnType.Star, EnumBtnType.Inlay}, nextPosY)
        else
            self:createBtn({EnumBtnType.Equip, 
                EnumBtnType.Sell, EnumBtnType.Exchange}, nextPosY)
        end
        nextPosY = nextPosY - 30
    end
    nextPosY = nextPosY - 20
    return math.abs(nextPosY)
end

function UIHintLayer:createItem(item)
    local itemInfo = TableItem[item.id]
    local nextPosY = self:createIconName(item.id)
    nextPosY = self:createBaseInfo(item, nextPosY)
    
    nextPosY = self:createGetMethod(itemInfo.Gain, nextPosY)
    nextPosY = self:createItemDes(itemInfo.Item_Describe, nextPosY)
     
    nextPosY = self:createSellPrice(item, nextPosY) 
    if self.source ~= EnumHintType.other then
        if self.item.bagpos <= 10 then
            --self:createBtnUnload({x = 315, y = -60})
            self:createBtn({EnumBtnType.Unload}, nextPosY)
        else
            if itemInfo.Tag == 0 then
                self:createBtn({EnumBtnType.Take, EnumBtnType.Sell}, nextPosY)
            else 
                self:createBtn({EnumBtnType.Sell}, nextPosY)
            end
        end 
        nextPosY = nextPosY - 30
    end
    
    nextPosY = nextPosY - 20
    return math.abs(nextPosY)
end

function UIHintLayer:createJewel(item)
    local itemInfo = TableItem[item.id]
    local stoneInfo = TableStone[item.id]
    local nextPosY = self:createIconName(item.id)
    nextPosY = self:createBaseInfo(item, nextPosY)
    
    local seat = ""
    if stoneInfo.Seat == 2 then
        seat = "武器"
    elseif stoneInfo.Seat == 3 then
        seat = "腰带"
    elseif stoneInfo.Seat == 4 then
        seat = "衣服"
    end
    
    local lbl = self.createLabel("镶嵌部位: "..seat, 18,
        {x = startPosX, y = nextPosY}, nil, {self, {x = 0, y = 1}})
    lbl:setColor(QualityColor[itemInfo.Quality])
    nextPosY = nextPosY - lbl:getContentSize().height
    
    local name, attr, jewelAttrIdx = comm.getJewelAttrValue(item.id)
    local lbl = self.createLabel("镶嵌效果: "..name.."+"..attr.."%", 18,
        {x = startPosX, y = nextPosY}, nil, {self, {x = 0, y = 1}})
    lbl:setColor(QualityColor[itemInfo.Quality])
    nextPosY = nextPosY - lbl:getContentSize().height - interval
    nextPosY = self:createGetMethod(itemInfo.Gain, nextPosY)
    nextPosY = self:createItemDes(itemInfo.Item_Describe, nextPosY)
    nextPosY = self:createSellPrice(item, nextPosY) 
    
    if self.source ~= EnumHintType.other then
        self:createBtn({EnumBtnType.Inlay, EnumBtnType.Compound, 
            EnumBtnType.Sell}, nextPosY)
        nextPosY = nextPosY - 30
    end
    nextPosY = nextPosY - 20
    return math.abs(nextPosY)    
end

function UIHintLayer:createIconName(itemID)
    local itemInfo = TableItem[itemID]
    local iconPath = "icon/itemIcon/"..itemInfo.Icon..".png"
    local iconItem = self.createSprite(iconPath, {x = startPosX, y = -20},
        {self, {x = 0, y = 1}})
    iconItem:setScale(0.7)
    local lblItemName = self.createLabel(itemInfo.Item_Name, 20, 
        {x = 140, y = -50}, nil, {self, {x = 0, y = 0.5}})
    lblItemName:setColor(QualityColor[itemInfo.Quality or 1])
    local height = iconItem:getContentSize().height
    return - height
end

function UIHintLayer:createBaseInfo(item, posY)
    local itemInfo = TableItem[item.id]
    local nextPosY = posY
    if itemInfo.Explain then
        local lblItemDes = self.createLabel(itemInfo.Explain, 18, 
            { x = startPosX, y = posY}, nil, {self, {x = 0, y = 1}}, 
            {width = 280, height = 0})
        lblItemDes:setColor(ColorBlack)    
        local height = lblItemDes:getContentSize().height
        nextPosY = nextPosY - height - interS
    end
    
    local lbl = self.createLabel("使用等级: "..itemInfo.Use_level, 18,
        {x = startPosX, y = nextPosY}, nil, {self, {x = 0, y = 1}})
    lbl:setColor(ColorBlack)

    
    local lbl = self.createLabel("类型:", 18,
        {x = 260, y = nextPosY}, nil, {self, {x = 1, y = 1}})
    lbl:setColor(ColorBlack)

    local kind = " "
    if itemInfo.Bag_Type == 1 then  --装备细分
        if itemInfo.Item_Type == 1 then
            kind = "时装"
    elseif itemInfo.Item_Type == 2 then
            kind = "武器"
        elseif itemInfo.Item_Type == 3 then
            kind = "腰带"
        elseif itemInfo.Item_Type == 4 then
            kind = "衣服"
        end
    elseif itemInfo.Bag_Type == 2 then
        kind = "材料"
    elseif itemInfo.Bag_Type == 3 then
        kind = "特殊"
    end
    
    local lbl = self.createLabel(kind, 18,
        {x = 265, y = nextPosY}, nil, {self, {x = 0, y = 1}})
    lbl:setColor(ColorBlack)
    
    local height = lbl:getContentSize().height
    nextPosY = nextPosY - height

    if item.attr and #item.attr > 0 then
        lbl = self.createLabel("强化等级: "..bit.rshift(item.attr[3], 16),
        18, {x = startPosX, y = nextPosY}, nil, {self, {x = 0, y = 1}})
        lbl:setColor(ColorBlack)

        lbl = self.createLabel("装备战斗力:", 18,
            {x = 260, y = nextPosY}, nil, {self, {x = 1, y = 1}})
        lbl:setColor(ColorBlack)

        local _, value = comm.calculateEquipAttr(item.attr, item.id)
        lbl = self.createLabel(value, 18,
        {x = 265, y = nextPosY}, nil, {self, {x = 0, y = 1}})
        lbl:setColor(ColorBlack)

        local height = lbl:getContentSize().height
        nextPosY = nextPosY - height
    end
    
    nextPosY = nextPosY - interval
    
    return nextPosY
end 

function UIHintLayer:createItemDes(des, posY)
    local lblItemDes = self.createLabel(des, 18, 
        { x = startPosX, y = posY}, nil, {self, {x = 0, y = 1}}, 
        {width = 280, height = 0})
    lblItemDes:setColor{r = 167, g = 70, b = 9}
    local height = lblItemDes:getContentSize().height
    return posY - height - interval
end

function UIHintLayer:createGetMethod(way, posY)
     local lbl = self.createLabel("获得方法: "..way, 18, 
        { x = startPosX, y = posY}, nil, {self, {x = 0, y = 1}}, 
        {width = 280, height = 0})
    lbl:setColor{r = 167, g = 70, b = 9}
    local height = lbl:getContentSize().height
    return posY - height - interval
end 

function UIHintLayer:createSellPrice(item, posY)
    local nextposY = posY
    local itemInfo = TableItem[item.id]
    local lblPrice = nil
    local height = 0
    if itemInfo.Sale_Price then
        lblPrice = self.createLabel("出售价格："..itemInfo.Sale_Price, nil,
            {x = startPosX, y = nextposY }, nil, {self, {x = 0, y = 1}})
        lblPrice:setColor({r = 230, g = 0, b = 18})
        height = lblPrice:getContentSize().height
    end
    
    if itemInfo.Sale_Soul and itemInfo.Sale_Soul > 0 then
        nextposY = nextposY - height 
        lblPrice = self.createLabel("兑换价格："..itemInfo.Sale_Soul, nil,
            {x = startPosX, y = nextposY}, nil, {self, {x = 0, y = 1}})
        lblPrice:setColor({r = 230, g = 0, b = 18})
        height = lblPrice:getContentSize().height
    end
    
    return nextposY - height - 20
end 

function UIHintLayer:createItemInfo(itemID)
    self.back = self.createScale9Sprite("UI/common/tip.png", {x = 0, y = 0},
    	{width = 320, height = 400}, {self, {x = 0, y = 1}})

	local itemInfo = TableItem[itemID]
	local iconPath = "icon/itemIcon/"..itemInfo.Icon..".png"
	local iconItem = self.createSprite(iconPath, {x = 10, y = -10},
		{self, {x = 0, y = 1}})
	iconItem:setScale(0.8)
	local lblItemName = self.createLabel(itemInfo.Item_Name, 20, 
		{x = 140, y = -15}, nil, {self, {x = 0, y = 0.5}})

	local lblItemDes = self.createLabel(itemInfo.Item_Describe, nil, 
		{ x = 10, y = -140}, nil, {self, {x = 0, y = 1}}, 
		{width = 300, height = 0})

	local height = lblItemDes:getContentSize().height
	self.back:setPreferredSize({width = 320, height = height + 150})
	self.back:setLocalZOrder(-1)
    
    if self.item.bagpos <= 10 then
        self:createBtnUnload({x = 315, y = -60})
    else
	   self:createBtnEquip({x = 315, y = -60})
	end
	self:createBtnUse({x = 315, y = -120})

	return 400, height + 150
end

function UIHintLayer:createBtnEquip(position)
	local function onBtnTouched(sender, type)
	    local itemInfo = TableItem[self.item.id]
        if itemInfo.Item_Type > 0 and itemInfo.Item_Type <= 4 then
	       CMD_CG_SWAP(self.item.bagpos, itemInfo.Item_Type)
	    end
		cc.Director:getInstance():getRunningScene().hud:closeUI(self.class.__cname)
	end

	self.createButton{pos = position,
		title = "装备",
        icon = "UI/common/tip2.png",
        handle = onBtnTouched,
        parent = self
    }
end

function UIHintLayer:createBtnUnload(position)
    local function onBtnTouched(sender, type)
        local nilPos = 0
        
        for i = 11, 11 + #maincha.bag do
            local bFind = false
            for k, v in pairs(maincha.bag) do
                if v.bagpos == i then
                    bFind = true
                    break
                end
            end
            if not bFind then
                nilPos = i
            end
        end

        if nilPos > 0 then
            CMD_CG_SWAP(self.item.bagpos, nilPos)
        end
        cc.Director:getInstance():getRunningScene().hud:closeUI(self.class.__cname)
    end

    self.createButton{pos = position,
        title = "卸下",
        icon = "UI/common/tip2.png",
        handle = onBtnTouched,
        parent = self
    }
end

function UIHintLayer:createBtnUse(position)
    local function onBtnTouched(sender, type)
        CMD_CG_USEITEM(self.item.bagpos)
        cc.Director:getInstance():getRunningScene().hud:closeUI(self.class.__cname)
    end

    self.createButton{pos = position,
        title = "使用",
        icon = "UI/common/tip2.png",
        handle = onBtnTouched,
        parent = self
    }
end

function UIHintLayer:createBtnStrength(position)
    local function onBtnTouched(sender, type)
        --CMD_CG_USEITEM(self.item.bagpos)
        cc.Director:getInstance():getRunningScene().hud:closeUI(self.class.__cname)
    end

    self.createButton{pos = position,
        title = "强化",
        icon = "UI/common/tip2.png",
        handle = onBtnTouched,
        parent = self
    }
end

function UIHintLayer:createBtnStar(position)
    local function onBtnTouched(sender, type)
        --CMD_CG_USEITEM(self.item.bagpos)
        cc.Director:getInstance():getRunningScene().hud:closeUI(self.class.__cname)
    end

    self.createButton{pos = position,
        title = "升星",
        icon = "UI/common/tip2.png",
        handle = onBtnTouched,
        parent = self
    }
end

function UIHintLayer:createBtnInlay(position)
    local function onBtnTouched(sender, type)
        --CMD_CG_USEITEM(self.item.bagpos)
        cc.Director:getInstance():getRunningScene().hud:closeUI(self.class.__cname)
    end

    self.createButton{pos = position,
        title = "镶嵌",
        icon = "UI/common/tip2.png",
        handle = onBtnTouched,
        parent = self
    }
end

function UIHintLayer:createBtnSell(position)
    local function onBtnTouched(sender, type)
        --CMD_CG_USEITEM(self.item.bagpos)
        cc.Director:getInstance():getRunningScene().hud:closeUI(self.class.__cname)
    end

    self.createButton{pos = position,
        title = "出售",
        icon = "UI/common/tip2.png",
        handle = onBtnTouched,
        parent = self
    }
end

return UIHintLayer