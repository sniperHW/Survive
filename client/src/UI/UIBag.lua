local UIBag = class("UIBag", function()
    return require("UI.UIBaseLayer").create()
end)

function UIBag:create()
    local layer = UIBag.new()
    return layer
end

function UIBag:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
    self.schedulerID = nil
    self:createBack()
    self:createEquip()
    self:createBag()
    self:createBottom()
end
 
function UIBag:createEquip()
    local nodeEquip = cc.Node:create()
    nodeEquip:setPosition(40,60)
    self.nodeMid:addChild(nodeEquip)
    self.nodeEquip = nodeEquip
    
    self.createScale9Sprite("UI/common/bg3.png", nil, {width = 380, height = 550}, {nodeEquip})
    
    local function onEquipTouched(sender, type)
        
    end
    
    local function createItem(pos, btnIdx)
        local back = self.createSprite("UI/common/item_back.png", {x = pos.x, y = pos.y}, 
            {nodeEquip, {x = 0, y = 0}})
        self[btnIdx] = self.createButton{pos = {x = 0, y = 0}, 
            icon = "UI/item/item0.png", 
            handle = onEquipTouched, parent = back}        
    end
    
    createItem({x = 10, y = 400}, "equip")
    createItem({x = 10, y = 300}, "closth")
    createItem({x = 290, y = 400}, "belt")
    createItem({x = 290, y = 300}, "dress")
    
    for k = 0, 5 do
        createItem({x = 10 + (k % 3) * 140, y = 20 + math.floor(k/3) * 100}, "itemFight"..k)
    end
    
    local player = self.createSprite("UI/Character/char.jpg", {x = 190, y = 360}, {nodeEquip})
    player:setScale(0.6)
end

function UIBag:createBag()
    local nodeBag = cc.Node:create()
    nodeBag:setPosition(440,60)
    self.nodeMid:addChild(nodeBag)
    self.nodeBag = nodeBag
   nodeBag.btnTab = {nil, nil, nil, nil}
    
    self.createScale9Sprite("UI/common/bg3.png", nil, {width = 480, height = 550}, {nodeBag})
    local function onTabTouched(sender, type)
    	for i = 0, 3 do
            self.nodeBag.btnTab[i]:setEnabled(
                self.nodeBag.btnTab[i] ~= sender)
    	end
    end
    

    local function createTab(strTitle, i)
        local btnTab = self.createButton{title = strTitle,
                            pos = { x = 20 + 110 * i, y = 460},
                            icon = "UI/common/tab0.png",
                            handle = onTabTouched,
                            parent = nodeBag
        }
        btnTab:setBackgroundSpriteForState(cc.Scale9Sprite:create("UI/common/tab1.png"), 
                                        cc.CONTROL_STATE_DISABLED)     
        btnTab:setEnabled(i ~= 0)      
        self.nodeBag.btnTab[i] = btnTab                                                  
    end
    
    createTab(Lang.All, 0)
    createTab(Lang.Equip, 1)
    createTab(Lang.Material, 2)
    createTab(Lang.Gemstone, 3)
    
    local function numOfCells(table)
        return 10
    end

    local function sizeOfCellIdx(table, idx)
        return 90, 460  --left->height, right->width
    end

    local function cellOfIdx(table, idx)
        local cell = table:dequeueCell()
        
        local function createItem(pos, btnIdx)
            local back = self.createSprite("UI/common/item_back.png", {x = pos.x, y = pos.y}, 
                {cell, {x = 0, y = 0}})
            cell.item[btnIdx] = self.createSprite("UI/item/item0.png", {x = pos.x, y = pos.y}, 
                {cell, {x = 0, y = 0}})  
            --cell.item[btnIdx]:setScale(1.5)
        end        
        
        if cell == nil then
            cell = cc.TableViewCell:create()
            cell.item = {}
            for i = 0, 4 do
                createItem({x = 10 + i * 90, y = 4}, i)
            end
        end
        return cell
    end

    local tableAchieve = cc.TableView:create({width = 460, height = 450})
    tableAchieve:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    tableAchieve:setPosition(10, 30)
    tableAchieve:registerScriptHandler(numOfCells, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
    tableAchieve:registerScriptHandler(sizeOfCellIdx, cc.TABLECELL_SIZE_FOR_INDEX)
    tableAchieve:registerScriptHandler(cellOfIdx, 
        cc.Handler.TABLECELL_AT_INDEX - cc.Handler.SCROLLVIEW_SCROLL)   --TODO cocos2dx lua bug
    nodeBag:addChild(tableAchieve)
    tableAchieve:reloadData()
end

function UIBag:createBottom()
    local nodeBottom = cc.Node:create()
    nodeBottom:setPosition(40,10)
    self.nodeMid:addChild(nodeBottom)
    self.nodeBottom = nodeBottom
    self.createScale9Sprite("UI/common/long_bk.png", nil, 
                            {width = 880, height = 40}, {nodeBottom})
                            
    self.createSprite("UI/common/shell.png", {x = 50, y = 25}, {nodeBottom})    
    self.lblShell = self.createLabel(123456, nil, {x = 80, y = 20}, nil, {nodeBottom, {x = 0, y = 0.5}})                        
    self.createSprite("UI/common/pearl.png", {x = 350, y = 25}, {nodeBottom})    
    self.lblPearl = self.createLabel(123456, nil, {x = 380, y = 20}, nil, {nodeBottom, {x = 0, y = 0.5}}) 
    self.createSprite("UI/common/soul.png", {x = 600, y = 25}, {nodeBottom})   
    self.lblSoul = self.createLabel(123456, nil, {x = 630, y = 20}, nil, {nodeBottom, {x = 0, y = 0.5}}) 
end

return UIBag