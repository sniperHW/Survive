local UICreatePlayer = class("UICreatePlayer", function()
    return require("UI.UIBaseLayer").create()
end)

function UICreatePlayer:create()
    local layer = UICreatePlayer.new()
    return layer
end

function UICreatePlayer:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
    self.schedulerID = nil
    
    local size = self.visibleSize
    self.back = cc.Sprite:create("UI/common/bg.jpg")
    self.back:setAnchorPoint(0, 0)
    self:addChild(self.back)
    
    self.nodeMid = cc.Node:create()
    self.nodeMid:setPositionX((self.visibleSize.width - DesignSize.width)/2)
    self:addChild(self.nodeMid)
    
    if self.visibleSize.width/self.visibleSize.height < 1.5 then
        self.nodeMid:setScale(0.9)
        self.nodeMid:setPositionX(0)
    end
    
    self:createPlayer()
    self:createWeapon()
end

function UICreatePlayer:createPlayer()
    local nodePlayer = cc.Node:create()
    nodePlayer:setPosition(40,20)
    self.nodeMid:addChild(nodePlayer)
    self.nodePlayer = nodePlayer
    
    local bkSize = {width = 350, height = 400}
    
 --   self.createScale9Sprite("UI/createCharacter/frameLeft.png", {x = 0, y = 10}, 
 --       {width = 480, height = 530}, {nodePlayer})
    local scrollIndicator = {}
    for i = 1, 4 do
        scrollIndicator[i] = self.createSprite("UI/createCharacter/scrollIndicatorD.png",
            {x = 50 + 80* i, y = 50}, {nodePlayer})
    end

    
    local function numOfCells(table)
        return 4
    end
 
    local function sizeOfCellIdx(table, idx)
        return bkSize.height, bkSize.width--left->height, right->width
    end

    local function cellOfIdx(table, idx)
        local cell = table:dequeueCell()

        if cell == nil then
            cell = cc.TableViewCell:create()
            local back = self.createScale9Sprite("UI/createCharacter/frameLeft.png", nil, bkSize, {cell})
            cell.lbl = self.createLabel("", nil, {x = 200, y = 250}, nil, {cell} )
        end
        
        cell.lbl:setString(tostring(idx + 1))
        return cell
    end
    
    local tablePlayer = cc.TableViewAutoAlign:create(bkSize, {x = bkSize.width, y = 0})
    
    local function onScroll()
        local textureChche = cc.Director:getInstance():getTextureCache()
        local textureH = textureChche:addImage("UI/createCharacter/scrollIndicatorH.png")
        local textureD = textureChche:addImage("UI/createCharacter/scrollIndicatorD.png")
        
        local offset = tablePlayer:getContentOffset()
        local offX = math.abs(math.min(offset.x, 0))
        local idx = math.ceil((offX/bkSize.width)) + 1
        idx = math.min(math.max(1,idx), 4)
        
        for i = 1, 4 do
            if idx == i then
                scrollIndicator[i]:setTexture(textureH)
            else
                scrollIndicator[i]:setTexture(textureD)
            end
        end
    end
    
    tablePlayer:setDirection(cc.SCROLLVIEW_DIRECTION_HORIZONTAL)
    tablePlayer:setPosition(80, 100)
    tablePlayer:setDelegate()
    tablePlayer:registerScriptHandler(onScroll, 0)--cc.Handler.SCROLLVIEW_SCROLL)
    tablePlayer:registerScriptHandler(numOfCells, 
        cc.Handler.TABLEVIEW_NUMS_OF_CELLS - cc.Handler.SCROLLVIEW_SCROLL)
    tablePlayer:registerScriptHandler(sizeOfCellIdx, 
        cc.Handler.TABLECELL_SIZE_FOR_INDEX - cc.Handler.SCROLLVIEW_SCROLL)
    tablePlayer:registerScriptHandler(cellOfIdx, 
        cc.Handler.TABLECELL_AT_INDEX - cc.Handler.SCROLLVIEW_SCROLL)   --TODO cocos2dx lua bug
    nodePlayer:addChild(tablePlayer)
    tablePlayer:reloadData()    
end

function UICreatePlayer:createWeapon()
    local nodeWeapon = cc.Node:create()
    nodeWeapon:setPosition(560,30)
    self.nodeMid:addChild(nodeWeapon)
    self.nodeWeapon = nodeWeapon
    
    self.createScale9Sprite("UI/createCharacter/frameRight.png", {x = 0, y = 0}, {width = 360, height = 582}, {nodeWeapon})
    local function onBtnTouched(sender, type)
    end

    for i = 1, 3 do
        self.createSprite("UI/createCharacter/weaponBk.png",
            {x = 20, y = 110 + 130 * i}, {nodeWeapon, {x = 0, y = 0.5}})
    end
    
    self.createLabel(Lang.Gun, nil, {x = 200, y = 270}, nil, {nodeWeapon})
    self.createLabel(Lang.Rod, nil, {x = 200, y = 390}, nil, {nodeWeapon})
    self.createLabel(Lang.Sword, nil, {x = 200, y = 510}, nil, {nodeWeapon})
    
    self.createButton{
        pos = {x = 30, y = 450},
        icon = "UI/createCharacter/sword.png",
        handle = onBtnTouched,
        parent = nodeWeapon   
    }
    
    self.createButton{
        pos = {x = 20, y = 310},
        icon = "UI/createCharacter/rod.png",
        handle = onBtnTouched,
        parent = nodeWeapon   
    }
    
    self.createButton{
        pos = {x = 18, y = 190},
        icon = "UI/createCharacter/gun.png",
        handle = onBtnTouched,
        parent = nodeWeapon   
    }

    local function onTextHandle(typestr)
        if typestr == "began" then
        elseif typestr == "changed" then
            local input = self.txtUserName:getText()
            local len = cc.utils.getLenInUtf8(input)
            if string.len(input) ~= len then    --
                if len > 5 then
                    self.txtUserName:setText("")
                end    	
            else
                if len > 15 then
                    self.txtUserName:setText("")
                end
            end
        elseif typestr == "ended" then
        elseif typestr == "return" then
        end
        --return true
    end
    
    self.txtUserName = cc.EditBox:create({width = 323, height = 51},
        self.createScale9Sprite("UI/createCharacter/editbox.png", nil, {widht = 200, height = 100}, {}))
    self.txtUserName:setPosition(20, 140)
    self.txtUserName:setAnchorPoint(0, 0.5)
    self.txtUserName:registerScriptEditBoxHandler(onTextHandle)
    nodeWeapon:addChild(self.txtUserName)
    
    self.createButton{pos = {x = 240, y = 115},
        icon = "UI/createCharacter/random.png",
        handle = onBtnTouched,
        parent = nodeWeapon   
    } 
    
    self.createButton{pos = {x = 60, y = 25},
        icon = "UI/createCharacter/start.png",
        handle = onBtnTouched,
        parent = nodeWeapon   
    }
end

return UICreatePlayer