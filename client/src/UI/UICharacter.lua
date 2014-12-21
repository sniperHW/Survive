local Name2idx = require "src.net.name2idx"

local UICharacter = class("UICharacter", function()
    return require("UI.UIBaseLayer").create()
end)

function UICharacter:create()
    local layer = UICharacter.new()
    return layer
end

--[[
maincha.id = 1212
maincha.avatarid = 1
maincha.nickname = "一供七个字是吧"
local attr = {}
local Name2idx = require "src.net.name2idx"

for i = 1, 23 do
    attr[Name2idx.name(i)] = 101
end

maincha.attr = attr
maincha.equip = {}
maincha.equip[2] = {id = 5001}
]]
function UICharacter:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
    self.schedulerID = nil
    self:createBack()
    self:setSwallowTouch()  
    self:createCharShow()
    self:createCharAttr()
    self:createAddAttr()
    self:createAchieve()
    self:createRightTab()
    self.nodeAchieve:setVisible(false)
    self.nodeAddAttr:setVisible(false)
    self.createLabel(Lang.Character, 24, {x = 490, y = 550}, nil, {self.nodeMid})
    --[[
    local function onTouchBegan(sender, event)
        return true
    end

    local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
    ]]
end

function UICharacter:createRightTab()
    local function onBtnAttrTouched(sender, type)
        self.nodeShow:setVisible(true)
        self.nodeAttr:setVisible(true)
        self.nodeAttr:setPositionX(460)
        self.nodeAddAttr:setVisible(false)
        self.nodeAchieve:setVisible(false)
        self.btnAttr:setEnabled(false)
        self.btnAddPoint:setEnabled(true)
        self.back1:setVisible(true)
        self.back2:setVisible(false)
        self.back3:setVisible(false)
        self.back4:setVisible(true)
    end

    local function onBtnAddAttrTouched(sender, type)
        self.nodeShow:setVisible(false)
        self.nodeAttr:setVisible(true)
        self.nodeAttr:setPositionX(80)
        if self.nodeAddAttr == nil then
            self:createAddAttr()
        end
        self.nodeAddAttr:setVisible(true)
        self.nodeAchieve:setVisible(false)
        self.btnAttr:setEnabled(true)
        self.btnAddPoint:setEnabled(false)
        
        self.back1:setVisible(false)
        self.back2:setVisible(true)
        self.back3:setVisible(true)
        self.back4:setVisible(false)
    end

    local function onBtnAchieveTouched(sender, type)
        self.nodeShow:setVisible(false)
        self.nodeAttr:setVisible(false)
        self.nodeAddAttr:setVisible(false)
        self.nodeAchieve:setVisible(true)
    end

    local size = self.visibleSize
        
    self.createSprite("UI/character/tabBack.png", {x = 866, y = 317.5}, {self.nodeMid})
    local disableColor = {r = 255, g = 241, b = 0}
    self.btnAttr = self.createButton{title = "属 \n\n性",
        pos = { x = 855, y = 430},
        --icon = "UI/common/yellow_btn_light.png",
        handle = onBtnAttrTouched,
        parent = self.nodeMid}
    self.btnAttr:setRotation(-8)
    self.btnAttr:setTitleColorForState(disableColor, cc.CONTROL_STATE_DISABLED)
    local lbl = self.btnAttr:getTitleLabelForState(cc.CONTROL_STATE_NORMAL)
    lbl:setDimensions(30, 0)
    self.btnAttr:needsLayout()
    
    self.btnAddPoint = self.createButton{ title = "加\n\n点",
        pos = { x = 865, y = 285},
        --icon = "UI/common/yellow_btn_light.png",
        handle = onBtnAddAttrTouched,
        parent = self.nodeMid}
    self.btnAddPoint:setTitleColorForState(disableColor, cc.CONTROL_STATE_DISABLED)
    lbl = self.btnAddPoint:getTitleLabelForState(cc.CONTROL_STATE_NORMAL)
    lbl:setDimensions(30, 0)
    self.btnAddPoint:needsLayout()

    self.btnAchieve = self.createButton{ title = "成\n\n就",
        pos = { x = 855, y = 140},
        --icon = "UI/common/yellow_btn_light.png",
        handle = onBtnAchieveTouched,
        parent = self.nodeMid}
    self.btnAchieve:setRotation(5)
    self.btnAchieve:setTitleColorForState({r = 200, g = 200, b = 200}, cc.CONTROL_STATE_DISABLED)
    lbl = self.btnAchieve:getTitleLabelForState(cc.CONTROL_STATE_NORMAL)
    lbl:setDimensions(30, 0)
    self.btnAchieve:needsLayout()
    self.btnAchieve:setEnabled(false)
   
    onBtnAttrTouched(nil, nil)
end

function UICharacter:createCharShow()
    local function onBtnChangeNameTouched(sender, type)
        print("onBtnChangeNameTouched")
    end

    local nodeShow = cc.Node:create()
    self.nodeShow = nodeShow
    nodeShow:setPosition(40,60)
    self.nodeMid:addChild(nodeShow)

    self.back1 = self.createSprite("UI/bag/dw1.png", {x = 295, y= 318}, {self.nodeMid})
    self.back1:setLocalZOrder(-1)
    self.back1:setVisible(false)
    self.back2 = self.createSprite("UI/character/kkkkkk.png", {x = 295, y= 318}, {self.nodeMid})
    self.back2:setFlippedX(true)
    self.back2:setScale(1.1)
    self.back2:setOpacity(200)
    self.back2:setLocalZOrder(-1)
    self.createSprite("UI/common/split.png", {x = 490, y = 318}, {self.nodeMid})    
    self.createSprite("UI/character/k1.png", {x = 260, y = 430}, {nodeShow})

    self.createBMLabel("fonts/LV.fnt", "LV", 
        {x = 130, y = 430}, {nodeShow, {x = 0, y = 0.5}})
    self.lblPlayerLvl = self.createBMLabel("fonts/LV.fnt", maincha.attr.level, 
        {x = 155, y = 430}, {nodeShow, {x = 0, y = 0.5}})
        
    self.lblPlayerName = self.createLabel(maincha.nickname, nil, {x = 270, y = 430},
        cc.TEXT_ALIGNMENT_CENTER, {nodeShow})    
    self.lblPlayerName:setColor{r = 0, g = 0, b = 0}
    
    self.btnChangeName = self.createButton{pos = { x = 380, y = 430},
        icon = "UI/character/gm.png",
        ignore = false,
        handle = onBtnChangeNameTouched,
        parent = nodeShow
    }
    
    --self.iconPlayer = self.createSprite("UI/Character/char.jpg", {x = 185, y = 250}, {nodeShow})
    self.localPlayer = require("Avatar").create(maincha.avatarid, maincha.equip[2])
    self.localPlayer:getChildByTag(1):setRotation3D{x = 0, y = 0, z = 0}
    self.localPlayer:setPosition(270, 220)
    nodeShow:addChild(self.localPlayer)
    
    self.createSprite("UI/character/cj.png", {x = 270, y = 140}, {nodeShow})
    self.createBMLabel("fonts/cj.fnt", "拾贝小菜鸟", {x = 270, y = 140}, {nodeShow})
    
    self.createSprite("UI/character/k2.png", {x = 270, y = 80}, {nodeShow})
    self.createBMLabel("fonts/exp.fnt", "ID: "..(maincha.id or 1), {x = 270, y = 90}, {nodeShow})
    --self.createSprite("UI/common/exp.png", {x = 180, y = 70}, {nodeShow})
    self.lblPlayerExp = self.createBMLabel("fonts/exp.fnt", 
        "EXP:", {x = 180, y = 70}, {nodeShow, {x = 0, y = 0.5}})
    self.lblPlayerExp = self.createBMLabel("fonts/exp.fnt", 
        maincha.attr.exp.."/05645646", {x = 230, y = 70},
        {nodeShow, {x = 0, y = 0.5}})
end

function UICharacter:createCharAttr()
    local nodeAttr = cc.Node:create()
    nodeAttr:setPosition(460,60)
    self.nodeMid:addChild(nodeAttr)
    self.nodeAttr = nodeAttr

    local posY = 420
    local intervalY = 55
    local function createAttrLabel(attrShowName, attrName)
        self.createSprite("UI/character/k.png", {x = 220, y = posY}, {nodeAttr})
        local lbl = self.createLabel(attrShowName, nil, {x = 130, y = posY}, nil, {nodeAttr, {x = 0, y = 0.5}})
        lbl:setColor({r = 0, g = 0, b = 0})
        self["lbl"..attrName] = self.createLabel(maincha.attr[attrName] or -1, nil,
            {x = 240, y = posY}, nil, {nodeAttr, {x = 0, y = 0.5}})
        self["lbl"..attrName]:setColor({r = 0, g = 0, b = 0})
        posY = posY - intervalY
    end

    self.back3 = self.createSprite("UI/bag/dw2.png", {x= 670, y = 315}, {self.nodeMid})
    self.back3:setLocalZOrder(-1)
    self.back3:setVisible(false)
    self.back4 = self.createSprite("UI/character/kkkkkk.png", {x= 670, y = 315}, {self.nodeMid})
    self.back4:setScale(1.1)
    self.back4:setOpacity(200)
    self.back4:setLocalZOrder(-1)
    
    createAttrLabel(Lang.Attack..":", "attack")
    createAttrLabel(Lang.Defencse..":", "defencse")
    createAttrLabel(Lang.Life..":", "maxlife")
    createAttrLabel(Lang.Hit..":", "hit")
    createAttrLabel(Lang.Crit..":", "crit")
    --createAttrLabel(Lang.ActionForce..":", "action_force")
    createAttrLabel(Lang.MoveSpeed..":", "movement_speed")
    createAttrLabel(Lang.Dodge..":", "dodge")
end

function UICharacter:UpdateAttr()
    local attrs = {"attack", "defencse", "maxlife", "hit", "crit", --"action_force",
         "movement_speed", "dodge"}

    for _, attr in pairs(attrs) do
         self["lbl"..attr]:setString(maincha.attr[attr])
    end
    
    local attrpoint = {"power", "endurance", "constitution", 
        "accurate", "lucky", "agile"}

    for _, attr in pairs(attrpoint) do
        self["lbl"..attr]:setColor{r = 255, g = 255, b = 255}
    end
end
--[[
function UICharacter:UpdatePoint()
    local attrs = {"power", "endurance", "constitution", 
        "accurate", "lucky", "agile", "potential_point"}

    for _, attr in pairs(attrs) do
         self["lbl"..attr]:setString(maincha.attr[attr])
    end
    

end
]]
function UICharacter:createAddAttr()
    local nodeAddAttr = cc.Node:create()
    nodeAddAttr:setPosition(460,60)
    self.nodeMid:addChild(nodeAddAttr)
    self.nodeAddAttr = nodeAddAttr

    local attrs = {"power", "endurance", "constitution", 
        "accurate", "lucky", "agile", "potential_point"}
    local attrPoint = {}

    for _, attr in pairs(attrs) do
        attrPoint[attr] = maincha.attr[attr]
    end

    local function function_name( ... )
        -- body
    end

    
    local function updatePoint()
        local attrs = {"power", "endurance", "constitution", 
        "accurate", "lucky", "agile", "potential_point"}

        for _, attr in pairs(attrs) do
            self["lbl"..attr]:setString(attrPoint[attr])
            if attr ~= "potential_point" then
                if attrPoint[attr] ~= maincha.attr[attr]
                     then
                    self["lbl"..attr]:setColor{r = 255, g = 0, b = 0}
                else
                    self["lbl"..attr]:setColor{r = 255, g = 255, b = 255}
                end
            end
        end
    end

    local function onAddAttrTouched(sender, type)
        local idx = sender:getTag()
        local attrName = Name2idx.name(idx)

        if attrPoint["potential_point"] > 0 then
            attrPoint["potential_point"] = attrPoint["potential_point"] - 1
            attrPoint[attrName] = attrPoint[attrName] + 1 
            updatePoint()
        end        
    end

    local function onSubAttrTouched(sender, type)
        local idx = sender:getTag()
        local attrName = Name2idx.name(idx)

        if attrPoint[attrName]  > maincha.attr[attrName] then
            attrPoint["potential_point"] = attrPoint["potential_point"] + 1
            attrPoint[attrName] = attrPoint[attrName] - 1
            updatePoint()
        end 
    end

    local function onRetAddAttrTouched(sender, type)
        self:UpdatePoint()
    end

    local function onConfirmAddTouched(sender, type)
        local addpower =  attrPoint["power"] - maincha.attr["power"]
        local addendurance =  attrPoint["endurance"] - maincha.attr["endurance"]
        local addconstitution =  attrPoint["constitution"] - maincha.attr["constitution"]
        local addaccurate =  attrPoint["accurate"] - maincha.attr["accurate"]
        local addlucky =  attrPoint["lucky"] - maincha.attr["lucky"]
        local addagile =  attrPoint["agile"] - maincha.attr["agile"]

        CMD_ADDPOINT(addpower, addendurance, addconstitution, addagile,
            addlucky, addaccurate)
    end

    local posY = 420
    local intervalY = 45
    local function createAddAttrWidget(attrShowName, attrName)
        self.createSprite("UI/character/heng.png", {x = 220, y = posY}, {nodeAddAttr})
        self["btnAdd"..attrName] = self.createButton{pos = { x = 300, y = posY - 15},
            icon = "UI/character/addH.png",
            handle = onAddAttrTouched,
            parent = nodeAddAttr}
        self["btnAdd"..attrName]:setTag(Name2idx.idx(attrName))
        
        self["btnSub"..attrName] = self.createButton{pos = { x = 100, y = posY - 15},
            icon = "UI/character/subH.png",
            handle = onSubAttrTouched,
            parent = nodeAddAttr}
        self["btnSub"..attrName]:setTag(Name2idx.idx(attrName))

        self.createLabel(attrShowName, nil, {x = 160, y = posY}, nil, {nodeAddAttr, {x = 0, y = 0.5}})
        self["lbl"..attrName] = self.createLabel(maincha.attr[attrName], nil,
            {x = 220, y = posY}, nil, {nodeAddAttr, {x = 0, y = 0.5}})
        posY = posY - intervalY
    end

    createAddAttrWidget(Lang.Power..":", "power")
    createAddAttrWidget(Lang.Endurance..":", "endurance")
    createAddAttrWidget(Lang.Constitution..":", "constitution")
    createAddAttrWidget(Lang.Accurate..":", "accurate")
    createAddAttrWidget(Lang.Lucky..":", "lucky")
    createAddAttrWidget(Lang.Agile..":", "agile")

    local lbl = self.createLabel(Lang.PotentialInfo,
        18, {x = 80, y = 140}, nil, {nodeAddAttr, {x = 0, y = 0.5}})
    lbl:setDimensions(300, 0)
    lbl:setColor(ColorBlack)

    local btn = self.createButton{
        pos = { x = 55, y = 60},
        icon = "UI/character/cz.png",
        handle = onRetAddAttrTouched,
        parent = nodeAddAttr}
    --btn:setPreferredSize({width = 100, height = 50})

    local btn = self.createButton{title = Lang.ConfirmAddPoint,
        pos = { x = 260, y = 60},
        icon = "UI/common/k.png",
        handle = onConfirmAddTouched,
        parent = nodeAddAttr}
    btn:setPreferredSize({width = 112, height = 41})

    lbl = self.createLabel(Lang.Potential..":", nil, {x = 140, y = 80}, nil, {nodeAddAttr, {x = 0, y = 0.5}})
    lbl:setColor(ColorBlack)
    self["lblpotential_point"] = self.createLabel(maincha.attr.potential_point,
         nil, {x = 210, y = 80}, nil, {nodeAddAttr, {x = 0, y = 0.5}})
    self["lblpotential_point"]:setColor(ColorBlack)
end

function UICharacter:createAchieve()
    local nodeAchieve = cc.Node:create()
    nodeAchieve:setPosition(40,60)
    self.nodeMid:addChild(nodeAchieve)
    self.nodeAchieve = nodeAchieve
    
    self.createScale9Sprite("UI/common/bg3.png", nil, {width = 280, height = 550}, {nodeAchieve})
    self.createScale9Sprite("UI/common/bg3.png", {x = 320, y = 0}, {width = 480, height = 550}, {nodeAchieve})
    
    local function onAllTouched(sender, type)
    	
    end
    
    local function onCompleteTouched(sender, type)
    
    end
    
    local function onUndoneTouced(sender, type)
    	
    end
    --[[
    self.createButton{title = Lang.All,
        pos = { x = 60, y = 400},
        icon = "UI/common/yellow_btn_light.png",
        handle = onAllTouched,
        parent = nodeAchieve}

    self.createButton{ title = Lang.Done,
        pos = { x = 60, y = 250},
        icon = "UI/common/yellow_btn_light.png",
        handle = onCompleteTouched,
        parent = nodeAchieve}

    self.createButton{ title = Lang.Undone,
        pos = { x = 60, y = 100},
        icon = "UI/common/yellow_btn_light.png",
        handle = onUndoneTouced,
        parent = nodeAchieve}
     ]]
    local function numOfCells(table)
        return 30
    end
    
    local function sizeOfCellIdx(table, idx)
        return 80, 460  --left->height, right->width
    end
    
    local function cellOfIdx(table, idx)
        local cell = table:dequeueCell()
        if cell == nil then
        	cell = cc.TableViewCell:create()
            self.createScale9Sprite("UI/common/item_bk.png", {x = 0, y = 5}, {width = 460, height = 70}, {cell})
            cell.lbl = self.createLabel(tostring(idx), nil, {x = 230, y = 40}, nil, {cell})
        end
        cell.lbl:setString(tostring(idx))
    	return cell
    end
    
    local tableAchieve = cc.TableView:create({width = 460, height = 520})
    tableAchieve:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    tableAchieve:setPosition(330, 15)
    tableAchieve:registerScriptHandler(numOfCells, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
    tableAchieve:registerScriptHandler(sizeOfCellIdx, cc.TABLECELL_SIZE_FOR_INDEX)
    tableAchieve:registerScriptHandler(cellOfIdx, 
        cc.Handler.TABLECELL_AT_INDEX - cc.Handler.SCROLLVIEW_SCROLL)   --TODO cocos2dx lua bug
    nodeAchieve:addChild(tableAchieve)
    tableAchieve:reloadData()
end

return UICharacter

