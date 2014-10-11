local UICharacter = class("UICharacter", function()
    return require("UI.UIBaseLayer").create()
end)

function UICharacter:create()
    local layer = UICharacter.new()
    return layer
end

function UICharacter:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
    self.schedulerID = nil
    self:createBack()
    self:createRightTab()
    self:createCharShow()
    self:createCharAttr()
    self:createAddAttr()
    self:createAchieve()
    self.nodeAchieve:setVisible(false)
    self.nodeAddAttr:setVisible(false)
    local function onTouchBegan(sender, event)
        return true
    end

    local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
end

function UICharacter:createRightTab()
    local function onBtnAttrTouched(sender, type)
        self.nodeShow:setVisible(true)
        self.nodeAttr:setVisible(true)
        self.nodeAttr:setPositionX(460)
        self.nodeAddAttr:setVisible(false)
        self.nodeAchieve:setVisible(false)
    end

    local function onBtnAddAttrTouched(sender, type)
        self.nodeShow:setVisible(false)
        self.nodeAttr:setVisible(true)
        self.nodeAttr:setPositionX(40)
        if self.nodeAddAttr == nil then
            self:createAddAttr()
        end
        self.nodeAddAttr:setVisible(true)
        self.nodeAchieve:setVisible(false)
    end

    local function onBtnAchieveTouched(sender, type)
        self.nodeShow:setVisible(false)
        self.nodeAttr:setVisible(false)
        self.nodeAddAttr:setVisible(false)
        self.nodeAchieve:setVisible(true)
    end

    local size = self.visibleSize

    self.btnAttr = self.createButton{title = Lang.Attr,
        pos = { x = size.width - 160, y = 480},
        icon = "UI/common/yellow_btn_light.png",
        handle = onBtnAttrTouched,
        parent = self}

    self.btnAttr = self.createButton{ title = Lang.AddPoint,
        pos = { x = size.width - 160, y = 380},
        icon = "UI/common/yellow_btn_light.png",
        handle = onBtnAddAttrTouched,
        parent = self}

    self.btnAttr = self.createButton{ title = Lang.Achieve,
        pos = { x = size.width - 160, y = 280},
        icon = "UI/common/yellow_btn_light.png",
        handle = onBtnAchieveTouched,
        parent = self}
end

function UICharacter:createCharShow()
    local function onBtnChangeNameTouched(sender, type)
        print("onBtnChangeNameTouched")
    end

    local nodeShow = cc.Node:create()
    self.nodeShow = nodeShow
    nodeShow:setPosition(40,60)
    self.nodeMid:addChild(nodeShow)

    --[[   local sprite9 = cc.Scale9Sprite:create("UI/common/bg3.png")
    sprite9:setPreferredSize({width = 380, height = 550})
    sprite9:setAnchorPoint(0, 0)
    nodeShow:addChild(sprite9)
    ]]
    self.createScale9Sprite("UI/common/bg3.png", nil, {width = 380, height = 550}, {nodeShow})

    self.lblPlayerName = self.createLabel(maincha.nickname, nil, {x = 160, y = 500},
        cc.TEXT_ALIGNMENT_CENTER, {nodeShow})
    self.createSprite("UI/common/LV.png", {x = 220, y = 500}, {nodeShow})
    self.lblPlayerLvl = self.createLabel(tostring(maincha.attr.level), nil, {x = 260, y = 500},
        cc.TEXT_ALIGNMENT_CENTER, {nodeShow})
    self.btnChangeName = self.createButton{title = Lang.ChangeName,
        pos = { x = 280, y = 480},
        icon = "UI/common/yellow_btn_light.png",
        handle = onBtnChangeNameTouched,
        parent = nodeShow
    }
    self.btnChangeName:setPreferredSize({width = 100, height = 50})
    
    self.iconPlayer = self.createSprite("UI/Character/char.jpg", {x = 185, y = 250}, {nodeShow})
    self.createLabel("ID:", 20, {x = 60, y = 40}, nil, {nodeShow})
    self.lblPlayerID = self.createLabel(tostring(maincha.id), 20, {x = 110, y = 40}, nil, {nodeShow})
    self.createSprite("UI/common/exp.png", {x = 180, y = 40}, {nodeShow})
    self.lblPlayerExp = self.createLabel(tostring(maincha.attr.exp), nil, {x = 250, y = 40},
        nil, {nodeShow})
end

function UICharacter:createCharAttr()
    local nodeAttr = cc.Node:create()
    nodeAttr:setPosition(460,60)
    self.nodeMid:addChild(nodeAttr)
    self.nodeAttr = nodeAttr

    local posY = 480
    local intervalY = 60
    local function createAttrLabel(attrShowName, attrName)
        self.createLabel(attrShowName, nil, {x = 100, y = posY}, nil, {nodeAttr, {x = 0, y = 0.5}})
        self["lbl"..attrName] = self.createLabel(tostring(maincha.attr[attrName]), nil,
            {x = 200, y = posY}, nil, {nodeAttr, {x = 0, y = 0.5}})
        posY = posY - intervalY
    end

    self.createScale9Sprite("UI/common/bg3.png", nil, {width = 380, height = 550}, {nodeAttr})

    createAttrLabel(Lang.Attack..":", "attack")
    createAttrLabel(Lang.Defencse..":", "defencse")
    createAttrLabel(Lang.Life..":", "life")
    createAttrLabel(Lang.Hit..":", "hit")
    createAttrLabel(Lang.Crit..":", "crit")
    createAttrLabel(Lang.ActionForce..":", "action_force")
    createAttrLabel(Lang.MoveSpeed..":", "movement_speed")
    createAttrLabel(Lang.Dodge..":", "dodge")
end

function UICharacter:createAddAttr()
    local nodeAddAttr = cc.Node:create()
    nodeAddAttr:setPosition(460,60)
    self.nodeMid:addChild(nodeAddAttr)
    self.nodeAddAttr = nodeAddAttr

    local function onAddAttrTouched(sender, type)

    end

    local function onSubAttrTouched(sender, type)

    end

    local function onRetAddAttrTouched(sender, type)

    end

    local function onConfirmAddTouched(sender, type)

    end

    local posY = 480
    local intervalY = 60
    local function createAddAttrWidget(attrShowName, attrName)
        self["btnAdd"..attrName] = self.createButton{pos = { x = 40, y = posY - 40},
            icon = "UI/common/red_add.png",
            handle = onAddAttrTouched,
            parent = nodeAddAttr}
        self["btnSub"..attrName] = self.createButton{pos = { x = 260, y = posY - 40},
            icon = "UI/common/red_sub.png",
            handle = onSubAttrTouched,
            parent = nodeAddAttr}
        self.createLabel(attrShowName, nil, {x = 140, y = posY}, nil, {nodeAddAttr, {x = 0, y = 0.5}})
        self["lbl"..attrName] = self.createLabel("123", nil,
            {x = 200, y = posY}, nil, {nodeAddAttr, {x = 0, y = 0.5}})
        posY = posY - intervalY
    end

    self.createScale9Sprite("UI/common/bg3.png", nil, {width = 380, height = 550}, {nodeAddAttr})

    createAddAttrWidget(Lang.Power..":", "power")
    createAddAttrWidget(Lang.Endurance..":", "endurance")
    createAddAttrWidget(Lang.Constitution..":", "constitution")
    createAddAttrWidget(Lang.Accurate..":", "accurate")
    createAddAttrWidget(Lang.Lucky..":", "lucky")
    createAddAttrWidget(Lang.Agile..":", "agile")

    local lbl = self.createLabel(Lang.PotentialInfo,
        20, {x = 40, y = 100}, nil, {nodeAddAttr, {x = 0, y = 0.5}})
    lbl:setDimensions(300, 0)

    local btn = self.createButton{title = Lang.Reset,
        pos = { x = 10, y = 15},
        icon = "UI/common/yellow_btn_light.png",
        handle = onRetAddAttrTouched,
        parent = nodeAddAttr}
    btn:setPreferredSize({width = 100, height = 50})

    local btn = self.createButton{title = Lang.ConfirmAddPoint,
        pos = { x = 250, y = 15},
        icon = "UI/common/yellow_btn_light.png",
        handle = onConfirmAddTouched,
        parent = nodeAddAttr}
    btn:setPreferredSize({width = 100, height = 50})

    self.createLabel(Lang.Potential..":", nil, {x = 120, y = 40}, nil, {nodeAddAttr, {x = 0, y = 0.5}})
    self.createLabel("123", nil, {x = 200, y = 40}, nil, {nodeAddAttr, {x = 0, y = 0.5}})
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

