local UIMessage = require "UI.UIMessage"

local comm = require("common.CommonFun")

local UISynthesis = class("UISynthesis", function()
    return require("UI.UIBaseLayer").create()
end)

function UISynthesis:create()
    local layer = UISynthesis.new()
    return layer
end

local tableItems = {} 

function UISynthesis:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
    self.schedulerID = nil
    self.curType = 1
    self:initItems()
    self:createBack()
    self:setSwallowTouch()  
    self:createLeft()
    self:createRight()
    self:createTab()
end

function UISynthesis:initItems()
    tableItems = {} 
    for key, value in pairs(TableSynthesis) do
        local item = {}
        item.id = key
        item.price = value.Synthesis_Price
        local needItems = {}
       
        for i = 1, 3 do
            if value["Material"..i] then
                local str = value["Material"..i]
                local begin, last = string.find(str,":")
                local needItemID = tonumber(string.sub(str, 1, begin - 1))
                local needItemNum = 
                    tonumber(string.sub(str, begin + 1, string.len(str)))
                local needItem = {id = needItemID, count = needItemNum}
                needItems[i] = needItem
            end
        end
        item.needItems = needItems
        if not tableItems[value.Synthesis_Type] then
            tableItems[value.Synthesis_Type] = {}
        end
        table.insert(tableItems[value.Synthesis_Type], item)
    end
end

function UISynthesis:createTab()
    local size = self.visibleSize

    self.createSprite("UI/common/tabBack.png", 
        {x = 95, y = 330}, {self.nodeMid})
        
    local function onBtnTouched(sender, event)
        self.curType = sender:getTag()
        self.btn1:setEnabled(sender ~= self.btn1)
        self.btn2:setEnabled(sender ~= self.btn2)
        self.curIdx = 1
        self.tableSysnthesis:reloadData()
        self:UpdateNeedItem()
    end
    
    local disableColor = {r = 255, g = 241, b = 0}
    self.btn1 = self.createButton{title = "食\n\n品\n\n类",
        pos = { x = 70, y = 415},
        --icon = "UI/common/yellow_btn_light.png",
        handle = onBtnTouched,
        parent = self.nodeMid}
    self.btn1:setTag(1)
    self.btn1:setRotation(8)
    self.btn1:setTitleColorForState(disableColor, cc.CONTROL_STATE_DISABLED)
    local lbl = self.btn1:getTitleLabelForState(cc.CONTROL_STATE_NORMAL)
    lbl:setDimensions(30, 0)
    self.btn1:needsLayout()

    self.btn2 = self.createButton{ title = "工\n\n程\n\n类",
        pos = { x = 60, y = 270},
        --icon = "UI/common/yellow_btn_light.png",
        handle = onBtnTouched,
        parent = self.nodeMid}
    self.btn2:setTag(2)
    self.btn2:setTitleColorForState(disableColor, 
        cc.CONTROL_STATE_DISABLED)
    lbl = self.btn2:getTitleLabelForState(cc.CONTROL_STATE_NORMAL)
    lbl:setDimensions(30, 0)
    self.btn2:needsLayout()
    
    self.createSprite("UI/common/split.png", 
        {x = 400, y = 318}, {self.nodeMid})
    self.createLabel("生 产", 24, 
        {x = 400, y = 550}, nil, {self.nodeMid})
        
    onBtnTouched(self.btn1, nil)
end

function UISynthesis:createLeft()
    local backL = self.createSprite("UI/character/kkkkkk.png", 
        {x= 240, y = 315}, {self.nodeMid})
    backL:setScaleX(0.9)
    backL:setScaleY(1.1)
    backL:setFlippedX(true)
    backL:setOpacity(200)
    backL:setLocalZOrder(-1)
    
    local function numOfCells(table)
        return #tableItems[self.curType]
    end
    
    local function sizeOfCellIdx(table, idx)
        return 90, 300  --left->height, right->width
    end

    local function cellOfIdx(table, idx)
        local cell = table:dequeueCell()
        local items = tableItems[self.curType]
        if cell == nil then
            cell = cc.TableViewCell:create()
            cell.backS = self.createSprite("UI/synthesis/scxz.png", 
                {x = 140, y = 50}, {cell})
            cell.backS:setScaleX(0.4)
            cell.backS:setScaleY(0.5) 
            
            cell.backD = self.createSprite("UI/bag/kuang.png", 
                {x = 140, y = 50}, {cell})
            cell.backD:setScaleX(0.4)
            cell.backD:setScaleY(0.5)
            
            cell.icon = self.createSprite("icon/itemIcon/beixin.png", 
                {x = 50, y = 50}, {cell})  
            cell.icon:setScale(0.5)
            cell.icon.qualityIcon = self.createSprite(QualityIconPath[1], 
                    {x = 0, y = 0}, {cell.icon, {x = 0, y = 0}})
            cell.lblName = self.createLabel("小苹果", 22, 
                {x = 100, y = 50}, nil, {cell, {x = 0, y = 0.5}})
            cell.iconAble = self.createSprite("UI/synthesis/sckhc.png", 
                {x = 200, y = 70}, {cell})  
        end
        
        local bSel = self.curIdx == (idx+1)
        cell.backD:setVisible(not bSel)
        cell.backS:setVisible(bSel)
        
        local tarItem = items[idx+1]
        local itemInfo = TableItem[tarItem.id]        
        cell.icon:setTexture("icon/itemIcon/"..itemInfo.Icon..".png")
        cell.lblName:setString(itemInfo.Item_Name)
        if itemInfo.Quality then
            cell.icon.qualityIcon:setTexture(QualityIconPath[itemInfo.Quality])
            cell.icon.qualityIcon:setVisible(true)
        else
            cell.icon.qualityIcon:setVisible(false)
        end
        cell.iconAble:setVisible(true)
        for i = 1, #tarItem.needItems do
            if tarItem.needItems[i].count >
                comm.getItemCount(tarItem.needItems[i].id) then
                cell.iconAble:setVisible(false)
            end
        end
        return cell
    end
    
    local function onCellTouched(table, tableviewcell)
        local touchPoint = tableviewcell:getTouchedPoint()
        local cellIdx = tableviewcell:getIdx()
        local box = tableviewcell.icon:getBoundingBox()
        if cc.rectContainsPoint(box, touchPoint) then
            local itemid = tableItems[self.curType][tableviewcell:getIdx()+1].id
            local item = {id = itemid}
            if itemid ~= 0 then
                local hud = cc.Director:getInstance():getRunningScene().hud
                hud:showHint(EnumHintType.other, item, nil)
            end
        else
            local idx = tableviewcell:getIdx()+1
            if idx ~= idx then
                self.tableSysnthesis:updateCellAtIndex(self.curIdx-1)
                self.curIdx = idx
                self:UpdateNeedItem(idx)
            end 
        end
    end
    
    local tableSysnthesis = cc.TableView:create({width = 260, height = 400})
    tableSysnthesis:setDelegate()
    tableSysnthesis:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    tableSysnthesis:setPosition(120, 120)
    tableSysnthesis:registerScriptHandler(numOfCells, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
    tableSysnthesis:registerScriptHandler(sizeOfCellIdx, cc.TABLECELL_SIZE_FOR_INDEX)
    tableSysnthesis:registerScriptHandler(onCellTouched, 
        cc.Handler.TABLECELL_TOUCHED - cc.Handler.SCROLLVIEW_SCROLL)
    tableSysnthesis:registerScriptHandler(cellOfIdx, 
        cc.Handler.TABLECELL_AT_INDEX - cc.Handler.SCROLLVIEW_SCROLL)   --TODO cocos2dx lua bug
    self.nodeMid:addChild(tableSysnthesis)
    self.tableSysnthesis = tableSysnthesis
    self.tableSysnthesis:reloadData()
end

function UISynthesis:createRight()
    self.needItemWidget = {}
    local back = self.createSprite("UI/bag/dw2.png", 
        {x = 637, y = 318}, {self.nodeMid})
    back:setScaleX(1.3)
    back:setLocalZOrder(-1)

    local function onItemTouched(sender, event)
        local item = {id = sender:getTag()}
        local hud = cc.Director:getInstance():getRunningScene().hud
        hud:showHint(EnumHintType.other, item, nil)
    end

    self.tarBtnBack = self.createButton{
        pos = {x = 638, y = 430}, 
        icon = "UI/bag/icon.png", 
        ignore = false,
        handle = onItemTouched, parent = self.nodeMid}

    local lbl = self.createLabel("消耗：", 22, 
        {x = 500, y = 140}, nil, {self.nodeMid})
    lbl:setColor({r = 0, g = 0, b = 0})
    self.createSprite("UI/main/bk.png", 
        {x = 550, y = 140}, {self.nodeMid}) 

    self.needShell = self.createLabel("500", 22, 
        {x = 580, y = 140}, nil, {self.nodeMid, {x = 0, y = 0.5}})
    self.needShell:setColor({r = 0, g = 0, b = 0})

    local function onMakeTouched(sender, event)
        local tarItem = tableItems[self.curType][self.curIdx]
        local bagpos = {}
        local bSuccess = maincha.attr.shell >= tarItem.price
        if not bSuccess then
            UIMessage.showMessage(Lang.ShellNotEnough)
            return
        end
        
        for i = 1, #tarItem.needItems do
            local id = tarItem.needItems[i].id
            local hasCount, pos = comm.getItemCount(id)
            if hasCount >= tarItem.needItems[i].count then
                table.insert(bagpos, pos)
            else
                bSuccess = false
            end
        end

        if bSuccess then
            CMD_COMPOSITE(tarItem.id, bagpos)
        else
            UIMessage.showMessage(Lang.MaterialNotEnough)
        end
    end
        
    local btn = self.createButton{title = "生  产",
        pos = {x = 740, y = 140},
        icon = "UI/common/k.png",
        handle = onMakeTouched,
        ignore = false,
        parent = self.nodeMid    
    }
    btn:setPreferredSize({width = 120, height = 50})
        
    self.tarIcon = self.createSprite("icon/itemIcon/beixin.png", 
        {x = 638, y = 430}, {self.nodeMid})  
    self.tarIcon:setScale(0.5)

    self.tarIcon.qualityIcon = self.createSprite(QualityIconPath[1], 
        {x = 0, y = 0}, {self.tarIcon, {x = 0, y = 0}})
            
    local function createNeedItem(parent, pos)
        local btn = self.createButton{
            pos = pos, 
            icon = "UI/bag/icon2.png", 
            ignore = false,
            handle = onItemTouched, parent = parent}
        btn:setScale(0.95)
        local icon = self.createSprite("icon/itemIcon/beixin.png", 
            pos, {parent})  
        icon:setScale(0.48)
        
        icon.qualityIcon = self.createSprite(QualityIconPath[1], 
            {x = 0, y = 0}, {icon, {x = 0, y = 0}})
        local lblNum = self.createLabel("5/2", 20, 
            {x = 100, y = 20}, nil, {icon, {x = 1, y = 0.5}})  
        lblNum:enableOutline(ColorBlack, 2)
        return {back = btn, icon = icon, lblNum = lblNum}
    end

    local node2 = cc.Node:create()
    self.nodeNeed2 = node2
    self.nodeMid:addChild(node2)
    self.createSprite("UI/synthesis/sc2g.png", {x = 637, y = 380}, {node2})
    
    local ceil2 = cc.Sprite:create("UI/synthesis/scf.png")
    ceil2:setPosition({x = 637, y = 264})
    local clipNode = cc.ClippingNode:create(ceil2)
    node2.ceil = ceil2
    node2:addChild(clipNode)
    
    self.createSprite("UI/synthesis/sc2g1.png", 
        {x = 637, y = 380}, {clipNode})
    
    self.needItemWidget[1] = {}
    self.needItemWidget[1][1] = createNeedItem(node2, {x = 570, y = 243})
    self.needItemWidget[1][2] = createNeedItem(node2, {x = 711, y = 243})
    node2:setVisible(true)
    
    local node3 = cc.Node:create()
    self.nodeNeed3 = node3
    self.nodeMid:addChild(node3)
    self.createSprite("UI/synthesis/sc3g.png", {x = 643, y = 385}, {node3})
    
    local ceil3 = cc.Sprite:create("UI/synthesis/scf.png")
    ceil3:setPosition({x = 637, y = 264})
    local clipNode = cc.ClippingNode:create(ceil3)
    node3.ceil = ceil3
    node3:addChild(clipNode)
    
    self.createSprite("UI/synthesis/sc3g1.png", {x = 643, y = 385}, {clipNode})
    node3:setVisible(false)
    self.needItemWidget[2] = {}
    self.needItemWidget[2][1] = createNeedItem(node3, {x = 536, y = 245})
    self.needItemWidget[2][2] = createNeedItem(node3, {x = 640, y = 245})
    self.needItemWidget[2][3] = createNeedItem(node3, {x = 745, y = 245})    

    local iconPro = cc.Sprite:create("UI/synthesis/sc2g2.png")
    iconPro:setPosition({x = 637, y = 380})
    local scy = cc.Sprite:create("UI/synthesis/scy.png")
    local pro = cc.ProgressTimer:create(scy)
    pro:setType(cc.PROGRESS_TIMER_TYPE_RADIAL)
    pro:setMidpoint({x = 0.5, y = 0.5})
    --pro:setAnchorPoint(cc.p(0.5, 0.6))
    pro:setPosition(cc.p(637, 432))
    pro:setPercentage(0)
    pro:setRotation(177)
    self.pro = pro

    local clipNode = cc.ClippingNode:create(pro)
    clipNode:addChild(iconPro)
    self.nodeMid:addChild(clipNode)
end

function UISynthesis:UpdateNeedItem()
    self.nodeNeed2.ceil:setPositionY(143)
    self.nodeNeed3.ceil:setPositionY(143)
    self.pro:setPercentage(0)
    local idx = self.curIdx
    local tarItem = tableItems[self.curType][idx]
    local tarItemInfo = TableItem[tarItem.id]
    self.tarBtnBack:setTag(tarItem.id)
    self.tarIcon:setTexture("icon/itemIcon/"..tarItemInfo.Icon..".png")

    if tarItemInfo.Quality then
        self.tarIcon.qualityIcon:setTexture(QualityIconPath[tarItemInfo.Quality])
        self.tarIcon.qualityIcon:setVisible(true)
    else
        self.tarIcon.qualityIcon:setVisible(false)
    end
    
    self.needShell:setString(tarItem.price)
    
    local widgets = nil
    
    self.nodeNeed3:setVisible(#tarItem.needItems == 3)
    self.nodeNeed2:setVisible(#tarItem.needItems == 2)
    if #tarItem.needItems == 2 then
        widgets = self.needItemWidget[1]
    elseif #tarItem.needItems == 3 then
        widgets = self.needItemWidget[2]
    end
    
    for i = 1, #tarItem.needItems do
        local widget = widgets[i]
        local id = tarItem.needItems[i].id
        widget.back:setTag(id)
        local itemInfo = TableItem[id]
        widget.icon:setTexture("icon/itemIcon/"..itemInfo .Icon..".png")
        if itemInfo.Quality then
            widget.icon.qualityIcon:setTexture(QualityIconPath[tarItemInfo.Quality])
            widget.icon.qualityIcon:setVisible(true)
        else
            widget.icon.qualityIcon:setVisible(false)    
        end
        local hasCount = comm.getItemCount(id)
        widget.lblNum:setString(hasCount.."/"..tarItem.needItems[i].count)
        if hasCount < tarItem.needItems[i].count then
            widget.lblNum:setColor({r = 255, g = 0, b = 0})
        else
            widget.lblNum:setColor({r = 0, g = 255, b = 0})
        end
        --{back = btn, icon = icon, lblNum = lblNum}
    end
end

function UISynthesis:RunSuccessAction(onEnd)
    local tarItem = tableItems[self.curType][self.curIdx]
    local ceil = nil
    if #tarItem.needItems == 2 then
        ceil = self.nodeNeed2.ceil
    elseif #tarItem.needItems == 3 then
        ceil = self.nodeNeed3.ceil
    end
    
    local function acPro()
        local function playEff()            
            local ani = comm.getEffAni(153)            
            local tblEff = TableSpecial_Effects[153]
            local name = string.format(tblEff.Name..".png", tblEff.Start_Frame)
            local spr = cc.Sprite:createWithSpriteFrameName(name)
            spr:setBlendFunc(gl.SRC_ALPHA, gl.ONE)            
            spr:runAction(cc.Sequence:create(ani, 
                cc.RemoveSelf:create(), cc.CallFunc:create(onEnd)))
            spr:setPosition({x = 638, y = 430})
            self.nodeMid:addChild(spr)
        end
        local ac = cc.ProgressFromTo:create(0.4, 0, 100)
        self.pro:runAction(cc.Sequence:create(ac, cc.CallFunc:create(playEff)))
    end
    
    local acMove = cc.MoveBy:create(0.5,{x = 0, y = 121}) 
    ceil:runAction(cc.Sequence:create(acMove, cc.CallFunc:create(acPro)))
    
    local itemInfo = TableItem[tarItem.id]
    UIMessage.showMessage(string.format(Lang.SuccessSynthesis, itemInfo.Item_Name))
end

function UISynthesis:onBagUpdate()
    local function onEnd()
        local offset = self.tableSysnthesis:getContentOffset()
        self.tableSysnthesis:reloadData()
        self.tableSysnthesis:setContentOffset(offset)
        self:UpdateNeedItem()
    end
    self:RunSuccessAction(onEnd)
end

return UISynthesis
