local UIMessage = require "UI.UIMessage"
local comm = require "common.CommonFun"

local UIBag = class("UIBag", function()
    return require("UI.UIBaseLayer").create()
end)

local bagSateNormal = 1
local bagStateTake = 2
local bagStateCompound = 3

local bagState = bagSateNormal

function UIBag:create()
    local layer = UIBag.new()
    return layer
end

function UIBag:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
    self.schedulerID = nil
    self:createBack()
    self:setSwallowTouch() 
    self:createEquip()
    self:createBag()
    self:createCompound()
    self.createLabel(Lang.Bag, 24, {x = 490, y = 550}, nil, {self.nodeMid})
    
    local function onNodeEvent(event)
        if "enter" == event then
            if MgrGuideStep == 6 then
                local hud = cc.Director:getInstance():getRunningScene().hud        
                local cell = self.tableBag:cellAtIndex(0)
                
                local equipIdx = 0
                local bagdata = maincha.bag
                if bagdata then
                    for i = 1, 4 do
                        local bagIdx = self.curBagItemsIdx[i]
                        if bagIdx and nil ~= bagdata[bagIdx] then
                            local itemInfo = TableItem[bagdata[bagIdx].id]
                            if itemInfo.Item_Type >= 2 and 
                                itemInfo.Item_Type <= 4 then
                                equipIdx = i
                                break
                            end
                        end
                    end
                end
                
                if equipIdx > 0 then
                    hud:closeUI("UIGuide")
                    local ui = hud:openUI("UIGuide")    
                    ui:createWidgetGuide(cell.item[equipIdx].back, "UI/bag/iconB.png", true)
                end
            elseif MgrGuideStep == 15 then
                local hud = cc.Director:getInstance():getRunningScene().hud 
                hud:closeUI("UIGuide")
                local ui = hud:openUI("UIGuide")    
                ui:createWidgetGuide(self.btnBody[5], "UI/bag/icon.png", false)
            end
        end

        if "exit" == event then
            if MgrGuideStep == 6 then         
                local hud = cc.Director:getInstance():getRunningScene().hud        
                hud:closeUI("UIGuide")  
                
                local main = hud:getUI("UIMainLayer")                                
                main.UpdateGuide()
            elseif MgrGuideStep == 15 then
                CMD_COMMIT_INTRODUCE_STEP(MgrGuideStep)
                local hud = cc.Director:getInstance():getRunningScene().hud 
                hud:closeUI("UIGuide")
                local main = hud:getUI("UIMainLayer")                                
                main.UpdateGuide()
            end
        end
    end
    self:registerScriptHandler(onNodeEvent)
end

function UIBag:createEquip()
    local nodeEquip = cc.Node:create()
    self.nodeMid:addChild(nodeEquip)
    self.nodeEquip = nodeEquip

    self.btnBody = {}
    self.iconBody = {}
    self.lblBodyNum = {}

    local sprite = self.createSprite("UI/bag/dw1.png", {x = 295, y = 318}, {self.nodeMid})
    sprite:setLocalZOrder(-1)

    local function onEquipTouched(sender, type)
        local btnIdx = sender:getTag()
        if btnIdx > 4 and maincha.equip[btnIdx] == nil then        
            if btnIdx >= 8 then
                UIMessage.showMessage(Lang.VipPos)
                return
            end
        
            bagState = bagStateTake
            self:UpdateBag()
            
            if MgrGuideStep == 15 then
                local hud = cc.Director:getInstance():getRunningScene().hud 
                hud:closeUI("UIGuide")
        
                local cell = self.tableBag:cellAtIndex(0)
                local equipIdx = 0
                local bagdata = maincha.bag
                if bagdata then
                    for i = 1, 4 do
                        local bagIdx = self.curBagItemsIdx[i]
                        if bagIdx and nil ~= bagdata[bagIdx] then
                            local itemInfo = TableItem[bagdata[bagIdx].id]
                            if itemInfo.Tag == 0 then
                                equipIdx = i
                                break
                            end
                        end
                    end
                end

                if equipIdx > 0 then
                    local ui = hud:openUI("UIGuide")    
                    ui:createWidgetGuide(cell.item[equipIdx].back, "UI/bag/iconB.png", true)
                end
            end
        else    
            local cellPos = sender:getPosition3D()
            local parent = sender:getParent()
            local pos = parent:convertToWorldSpace({x = cellPos.x, y = cellPos.y})
            
            local hud = cc.Director:getInstance():getRunningScene().hud
            hud:showHint(EnumHintType.body, sender:getTag(), pos)
        end
    end
    
    local back0 = "UI/bag/icon.png"
    local back1 = "UI/bag/icon2.png"
    local function createItem(pos, btnIdx, iconPath)
        self.btnBody[btnIdx] = self.createButton{pos = {x = pos.x+40, y = pos.y+60},--{x = 38, y = 35}, 
            icon = iconPath, 
            ignore = true,
            handle = onEquipTouched, parent = nodeEquip}  
        self.btnBody[btnIdx]:setTag(btnIdx)
        self.btnBody[btnIdx]:setZoomOnTouchDown(false)
        --[[
        if iconPath == back1 then
            self.btnBody[btnIdx]:setEnabled(false)
        end
        ]]
        self.iconBody[btnIdx] = self.createSprite(iconPath, {x = pos.x + 78, y = pos.y + 95}, 
            {nodeEquip})
        self.iconBody[btnIdx].qualityIcon = 
            self.createSprite(QualityIconPath[1], 
                {x = 0, y = 0}, {self.iconBody[btnIdx], {x = 0, y = 0}})
        
        self.lblBodyNum[btnIdx] = self.createLabel("5", 16, 
            {x = pos.x + 100, y = pos.y + 80}, nil, {nodeEquip, {x = 1, y = 0.5}})  
        self.lblBodyNum[btnIdx]:enableOutline(ColorBlack, 2)
        
        self.iconBody[btnIdx]:setScale(0.5)
    end
--[[
    1，时装
    2，武器
    3，腰带
    4，衣服
]]    

    createItem({x = 110, y = 350}, 1, "UI/bag/icon-1.png")
    createItem({x = 330, y = 350}, 2, "UI/bag/icon-2.png")
    createItem({x = 110, y = 250}, 3, "UI/bag/icon-3.png")
    createItem({x = 330, y = 250}, 4, "UI/bag/icon-4.png")
    
    for k = 5, 10 do
        local idx = k - 5
        local iconPath = back0
        if k < 8 then
            iconPath = back0
        elseif maincha.attr and maincha.attr.vip 
            and maincha.attr.vip > 0 then
            iconPath = back0
        else
            iconPath = back1
        end
        createItem({x = 110 + (idx % 3) * 110, y = 155 + math.floor(idx/3) * (-95)}, 
            k, iconPath)
    end
    
    if maincha.equip[2] then
        self.equipid = maincha.equip[2].id 
    else
        self.equipid = 0
    end
    
    self.avatar = require("Avatar").create(maincha.avatarid or 2, maincha.equip[2])
    self.avatar:setPosition(300, 320)
    self.avatar:getChildByTag(EnumAvatar.Tag3D):setRotation3D{x = 0, y = 0, z = 0}
    nodeEquip:addChild(self.avatar)
    self:UpdateEquip()
end

function UIBag:UpdateEquip()
    local bag = maincha.equip

    for i = 1, 10 do
        local bagCell = bag[i]
        if bagCell then
            local itemid = bagCell.id
            local itemInfo = TableItem[itemid]
            local iconPath = "icon/itemIcon/"..itemInfo.Icon..".png"
            self.iconBody[i]:setVisible(true)
            self.iconBody[i]:setTexture(iconPath)
            self.iconBody[i].qualityIcon:setTexture(QualityIconPath[itemInfo.Quality])
            if itemInfo.Bag_Type ~= 1 then
                self.lblBodyNum[i]:setVisible(true)
                self.lblBodyNum[i]:setString(bagCell.count)
            else
                self.lblBodyNum[i]:setVisible(false)
            end
        else
            self.iconBody[i]:setVisible(false)
            self.lblBodyNum[i]:setVisible(false)
        end
    end

    if maincha.equip[2] and maincha.equip[2].id ~= self.equipid then
        self.avatar:removeFromParent()
        self.equipid = maincha.equip[2].id
        self.avatar = require("Avatar").create(maincha.avatarid or 2, maincha.equip[2])
        self.avatar:setPosition(300, 320)
        self.avatar:getChildByTag(EnumAvatar.Tag3D):setRotation3D{x = 0, y = 0, z = 0}
        self.nodeEquip:addChild(self.avatar)
    end
end

function UIBag:createCompound()
    local nodeCompound = cc.Node:create()
    nodeCompound:setLocalZOrder(-1)
    nodeCompound:setVisible(false)
    self.nodeMid:addChild(nodeCompound)
    self.nodeCompound = nodeCompound

    local back2 = self.createSprite("UI/character/kkkkkk.png", 
        {x = 295, y= 318}, {nodeCompound})
    back2:setFlippedX(true)    
    back2:setScale(1.1)
    back2:setOpacity(200)
    self.createSprite("UI/bag/kuang.png", {x = 295, y= 460}, {nodeCompound})
    
    self.createLabel("3颗", nil, {x = 200, y = 470}, nil, {nodeCompound})
    self.lblTipSource = self.createLabel("2级生命宝石", nil, {x = 218, y = 470},
        nil, {nodeCompound, {x = 0, y = 0.5}})
    self.createLabel("可以合成", nil, {x = 330, y = 470}, nil, 
        {nodeCompound, {x = 0, y = 0.5}})
        
    self.createLabel("1颗", nil, {x = 240, y = 450}, nil, {nodeCompound})
    self.lblTipTarget = self.createLabel("2级生命宝石", nil, {x = 260, y = 450},
        nil, {nodeCompound, {x = 0, y = 0.5}})
    
    local function showHint(sender, event)
        
    end

    local btnBack = self.createButton{
            icon = "UI/equip/no1.png", 
            pos = {x = 200, y = 340}, 
            parent = nodeCompound, 
            ignore = false,
            handle = nil}
    btnBack:setZoomOnTouchDown(false) 

    self.iconStone1 = self.createSprite("icon/itemIcon/beixin.png", 
        {x = 200, y = 340}, {nodeCompound})
    self.iconStone1.QualityIcon = self.createSprite(QualityIconPath[1], 
        {x = 0, y = 0}, {self.iconStone1, {x = 0, y = 0}})
    self.iconStone1:setScale(0.5)
    self.lblCount1 = self.createBMLabel(
        "fonts/jinenglv.fnt", 10, {x = 220, y = 325}, {nodeCompound})
    self.lblCount1:setScale(0.8)            

    self.lblSourceStone = self.createLabel("2级生命石", 18, {x = 200, y = 300},
        nil, {nodeCompound})

    self.createSprite("UI/bag/jiantou.png", {x = 300, y= 340}, 
        {nodeCompound})
    
    btnBack = self.createButton{
            icon = "UI/equip/no1.png", 
            pos = {x = 400, y = 340}, 
            parent = nodeCompound, 
            ignore = false,
            handle = nil}
    btnBack:setZoomOnTouchDown(false) 

    self.iconStone2 = self.createSprite("icon/itemIcon/beixin.png", 
        {x = 400, y = 340}, {nodeCompound})
    self.iconStone2.QualityIcon = self.createSprite(QualityIconPath[1], 
        {x = 0, y = 0}, {self.iconStone2, {x = 0, y = 0}})
    self.iconStone2:setScale(0.5)
    
    self.lblTargetStone = self.createLabel("3级生命石", 18, {x = 400, y = 300},
        nil, {nodeCompound})

    self.createLabel("合成一个消耗：", nil, {x = 260, y = 220},
        nil, {nodeCompound})  
    self.lblFee = self.createLabel("8000贝壳", nil, {x = 330, y = 220},
        nil, {nodeCompound, {x = 0, y = 0.5}})  

    local function onBtnCompound(sender, event)
        local stoneBag = comm.getItem(self.stoneID)
        if stoneBag then
            local count = stoneBag.count
            if count < 3 then
                UIMessage.showMessage("数量不足") 
                return            
            end    
            
            local stoneInfo = TableStone[self.stoneID]
            local price = TableStone_Synthesis[stoneInfo.Stone_Level].Price
            if sender:getTag() == 1 then
                price = price * math.floor(count/3)
            end
            if maincha.attr.shell < price then
                UIMessage.showMessage(Lang.ShellNotEnough)
                return
            end

            CMD_STONE_COMPOSITE(self.stoneID, 
                stoneBag.bagpos, sender:getTag())
        else
            UIMessage.showMessage("数量不足")
        end
    end
    
    local btn = self.createButton{title = "合成一个",
        icon = "UI/common/k.png",
        ignore = false,
        pos = {x = 220, y = 150}, 
        handle = onBtnCompound, 
        parent = nodeCompound
    }
    btn:setPreferredSize({width = 120, height = 40})
    btn:setTag(0)

    btn = self.createButton{title = "全部合成",
        icon = "UI/common/k.png",
        ignore = false,
        pos = {x = 380, y = 150}, 
        handle = onBtnCompound, 
        parent = nodeCompound
    }
    btn:setPreferredSize({width = 120, height = 40})
    btn:setTag(1)

    local function onBackTouched(sender, event)
        self.nodeCompound:setVisible(false)
        self.nodeEquip:setVisible(true)    
    end
    
    btn = self.createButton{
        icon = "UI/bag/hechengback.png",
        ignore = false,
        pos = {x = 150, y = 520}, 
        handle = onBackTouched, 
        parent = nodeCompound
    }
end

function UIBag:UpdateCompound(stoneID)
    local itemInfo = TableItem[stoneID]
    local stoneInfo = TableStone[stoneID]
    local tarItemInfo = TableItem[stoneInfo.Next_Level]
    
    if itemInfo and stoneInfo then
        local quality = itemInfo.Quality or 1
        local color = QualityColor[quality]
        self.lblTipSource:setString(itemInfo.Item_Name)
        self.lblTipSource:setColor(color)
        self.lblSourceStone:setString(itemInfo.Item_Name)
        self.lblSourceStone:setColor(color)
        local count = 0
        local stoneBag = comm.getItem(stoneID)
        if stoneBag then
            count = stoneBag.count
        end
        self.lblCount1:setString(count)
        self.iconStone1:setTexture("icon/itemIcon/"..itemInfo.Icon..".png") 
        self.iconStone1.QualityIcon:setTexture(QualityIconPath[quality])
        local price = TableStone_Synthesis[stoneInfo.Stone_Level].Price
        self.lblFee:setString(price.."贝壳")       
    else

    end

    if tarItemInfo then
        local quality = tarItemInfo.Quality or 1
        local color = QualityColor[quality]
        self.lblTipTarget:setString(tarItemInfo.Item_Name)
        self.lblTipTarget:setColor(color)
        self.lblTargetStone:setString(tarItemInfo.Item_Name)
        self.lblTargetStone:setColor(color)
        self.iconStone2:setTexture("icon/itemIcon/"..tarItemInfo.Icon..".png")    
        self.iconStone2.QualityIcon:setTexture(QualityIconPath[quality])
    else

    end
end

function UIBag:ShowCompound(stone)
	self.nodeCompound:setVisible(true)
	self.nodeEquip:setVisible(false)
	self.stoneID = stone.id
	self:UpdateCompound(stone.id)
end

function UIBag:createBag()
    local nodeBag = cc.Node:create()
    nodeBag:setPosition(440,60)
    self.nodeMid:addChild(nodeBag)
    self.nodeBag = nodeBag
    nodeBag.btnTab = {nil, nil, nil, nil}
    self.curBagItemsIdx = {}
    self.curBagType = 0 -- all
    
    --self.createScale9Sprite("UI/bag/dw2.png", nil, {width = 480, height = 550}, {nodeBag})
    local sprite = self.createSprite("UI/bag/dw2.png", {x = 660, y = 315}, {self.nodeMid})
    sprite:setLocalZOrder(-1)
    self.createSprite("UI/common/split.png", {x = 50, y = 258}, {nodeBag})
    self.createSprite("UI/bag/rightback.png", {x = 240, y = 238}, {nodeBag})
    local function onTabTouched(sender, type)
    	for i = 0, 3 do
            self.nodeBag.btnTab[i]:setEnabled(
                self.nodeBag.btnTab[i] ~= sender)
            if self.nodeBag.btnTab[i] == sender then
                self.curBagType = i     
                self:UpdateBag()    
            end
    	end
    end
    
    local function createTab(strTitle, i)
        local btnTab = self.createButton{title = strTitle,
            pos = { x = 60 + 80 * i, y = 408},
            --icon = "UI/common/tab0.png",
            handle = onTabTouched,
            parent = nodeBag
        }
        btnTab:setPreferredSize({width = 120, height = 27})
        btnTab:setBackgroundSpriteForState(
            ccui.Scale9Sprite:create("UI/bag/dianzhong.png"), 
            cc.CONTROL_STATE_DISABLED)
        btnTab:setTitleColorForState({r = 255, g = 255, b = 0}, cc.CONTROL_STATE_DISABLED)     
        btnTab:setEnabled(i ~= 0)      
        self.nodeBag.btnTab[i] = btnTab                                                  
    end
   
    createTab(Lang.All, 0)
    createTab(Lang.Equip, 1)
    createTab(Lang.Material, 2)
    createTab(Lang.Special, 3)
   
    local function numOfCells(table)
        return 13
    end

    local function sizeOfCellIdx(table, idx)
        return 70, 460  --left->height, right->width
    end

    local bagdata = maincha.bag
    local function cellOfIdx(table, idx)
        local cell = table:dequeueCell()

        local function createItem(pos, btnIdx)
            cell.item[btnIdx] = {}
            cell.item[btnIdx].back = self.createSprite("UI/bag/iconB.png", 
                {x = pos.x, y = pos.y}, 
                {cell})
                
            cell.item[btnIdx].selEff = self.createSprite("UI/bag/select.png",
                {x = pos.x, y = pos.y}, {cell})    
            
            cell.item[btnIdx].selEff:setVisible(false)
            cell.item[btnIdx].icon = self.createSprite("icon/itemIcon/beixin.png", 
                {x = pos.x, y = pos.y}, 
                {cell})  

            cell.item[btnIdx].icon.qualityIcon = 
                self.createSprite(QualityIconPath[1], 
                    {x = 0, y = 0}, {cell.item[btnIdx].icon, {x = 0, y = 0}})
                    
            cell.item[btnIdx].lblNum = self.createLabel("100", 16, 
                {x = pos.x + 22, y = pos.y - 16}, nil, {cell, {x = 1, y = 0.5}})  
            cell.item[btnIdx].lblNum:enableOutline(ColorBlack, 2)
            cell.item[btnIdx].icon:setScale(0.5)
        end        
        
        if cell == nil then
            cell = cc.TableViewCell:create()
            cell.item = {}
            for i = 1, 4 do
                createItem({x = 53 + i * 70, y = 37}, i)
            end
        end

        if bagdata then
            for i = 1, 4 do
                local bagIdx = self.curBagItemsIdx[idx * 4 + i]
                if bagIdx and nil ~= bagdata[bagIdx] then
                    local itemInfo = TableItem[bagdata[bagIdx].id]
                    local iconPath = "icon/itemIcon/"..itemInfo.Icon..".png"
                    local textureCache = cc.Director:getInstance():getTextureCache()
                    cell.item[i].icon:setTexture(textureCache:addImage(iconPath))
                    cell.item[i].icon:setVisible(true)
                    cell.item[i].icon.qualityIcon:setTexture(QualityIconPath[itemInfo.Quality])
                    if itemInfo.Bag_Type ~= 1 then
                        cell.item[i].lblNum:setVisible(true)
                        cell.item[i].lblNum:setString(bagdata[bagIdx].count)
                    else
                        cell.item[i].lblNum:setVisible(false)
                    end
                    
                    if bagState == bagStateTake then
                        cell.item[i].selEff:setVisible(itemInfo.Tag == 0)
                    else
                        cell.item[i].selEff:setVisible(false)
                    end
                else
                    cell.item[i].icon:setVisible(false)
                    cell.item[i].lblNum:setVisible(false)
                    cell.item[i].selEff:setVisible(false)
                end
            end
        else
            for i = 1, 4 do
                cell.item[i]:setVisible(false)
            end
        end

        return cell
    end

    local function onCellTouched(table, tableviewcell)
        local touchPoint = tableviewcell:getTouchedPoint()
        local cellIdx = tableviewcell:getIdx()

        for i, value in pairs(tableviewcell.item) do
            local cellPos = value.icon:getPosition3D()
            local modeX = touchPoint.x - cellPos.x
            local modeY = touchPoint.y - cellPos.y
            local pos = tableviewcell:convertToWorldSpace({x = cellPos.x, y = cellPos.y})

            if modeX > -33 and modeX < 33 and modeY > -33 and modeY < 33 then
                if  self.curBagItemsIdx[cellIdx * 4 + i] then
                    local bagIdx = self.curBagItemsIdx[cellIdx * 4 + i] 
                    local itemid = bagdata[bagIdx].id
                    local itemInfo = TableItem[itemid]
                    if itemInfo.Tag == 0 and bagState == bagStateTake then
                        CMD_LOADBATTLEITEM(bagdata[bagIdx].bagpos)
                        bagState = bagSateNormal
                        
                        if MgrGuideStep == 15 then              
                            local hud = cc.Director:getInstance():getRunningScene().hud        
                            hud:closeUI("UIGuide")              
                            local ui = hud:openUI("UIGuide")
                            local bag = hud:getUI("UIBag")    
                            ui:createWidgetGuide(bag.btnClose, "UI/common/close.png", false)
                        end
                    --[[                        
                    elseif TableStone[itemid] then
                        self:UpdateCompound(itemid)
                    ]]
                    else
                        local hud = cc.Director:getInstance():getRunningScene().hud
                        hud:showHint(1, self.curBagItemsIdx[cellIdx * 4 + i], pos)
                        break
                    end
                end
            end
        end
    end

    local tableBag = cc.TableView:create({width = 460, height = 300})
    tableBag:setDelegate()
    tableBag:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    tableBag:setPosition(10, 100)
    tableBag:registerScriptHandler(numOfCells, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
    tableBag:registerScriptHandler(sizeOfCellIdx, cc.TABLECELL_SIZE_FOR_INDEX)
    tableBag:registerScriptHandler(onCellTouched, cc.Handler.TABLECELL_TOUCHED - cc.Handler.SCROLLVIEW_SCROLL)
    tableBag:registerScriptHandler(cellOfIdx, 
        cc.Handler.TABLECELL_AT_INDEX - cc.Handler.SCROLLVIEW_SCROLL)   --TODO cocos2dx lua bug
    nodeBag:addChild(tableBag)
    self.tableBag = tableBag
    
    local function onAddTouched(sender, event)
    end
    
    self.lblSoul = self.createBMLabel("fonts/tili.fnt", maincha.attr.soul or -1, {x = 190, y = 62}, {nodeBag})
    self.createButton{icon = "UI/common/add.png",
        pos = {x = 230, y = 45},
        handle = onAddTouched,
        parent = nodeBag
    }

    self:UpdateBag()
end

function UIBag:UpdateBag()
    self.curBagItemsIdx = {}   
    for i = 1, #maincha.bag do
        if self.curBagType == 0 then
            table.insert(self.curBagItemsIdx, i)
        else
            local itemInfo = TableItem[maincha.bag[i].id]
            if itemInfo.Bag_Type == self.curBagType then
                table.insert(self.curBagItemsIdx, i)    
            end
        end
    end

    self.tableBag:reloadData()
    self.lblSoul:setString(maincha.attr.soul or -1)
end

function UIBag:onBagUpdate()
    self:UpdateBag()
    self:UpdateEquip()
    if self.stoneID then
        self:UpdateCompound(self.stoneID)
    end
end

return UIBag