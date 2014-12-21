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

local bkSize = {width = 400, height = 600}
local selectedWeapon = 5001

function UICreatePlayer:createPlayer()
    local nodePlayer = cc.Node:create()
    nodePlayer:setPosition(0,20)
    self.nodeMid:addChild(nodePlayer)
    self.nodePlayer = nodePlayer
    
 --   self.createScale9Sprite("UI/createCharacter/frameLeft.png", {x = 0, y = 10}, 
 --       {width = 480, height = 530}, {nodePlayer})
    local scrollIndicator = {}
    for i = 1, 6 do
        scrollIndicator[i] = self.createSprite("UI/createCharacter/scrollIndicatorD.png",
            {x = 50 + 60* i, y = 50}, {nodePlayer})
    end
    
    local function numOfCells(table)
        return 6
    end
    
    local function cellWillRecycle(table, cell)
    	--cell:setTag(5001)
    end
 
    local function sizeOfCellIdx(table, idx)
        return bkSize.height, bkSize.width  --left->height, right->width
    end

    local function cellOfIdx(table, idx)
        local cell = table:dequeueCell()

        if cell == nil then
            cell = cc.TableViewCell:create()
            cell:setTag(5001)
        end
        
        local avatarID = idx + 1
        local weapon = {id = selectedWeapon}
        local avatarShow = require("Avatar").create(avatarID, weapon) 
        local spr = avatarShow:GetAvatar3D()
        avatarShow:getChildByTag(EnumAvatar.Tag3D):setRotation3D{x = 0, y = 0, z = 0}
        spr:setScale(0.35)
        avatarShow:setPosition({x = 175, y = 50})    
        avatarShow:setTag(32432)
        cell:removeChildByTag(32432)
        cell:addChild(avatarShow)

        return cell
    end
    
    local tablePlayer = cc.TableViewAutoAlign:create(bkSize, {x = bkSize.width, y = 0})
    self.tablePlayer = tablePlayer
    local function onScroll()
        local textureChche = cc.Director:getInstance():getTextureCache()
        local textureH = textureChche:addImage("UI/createCharacter/scrollIndicatorH.png")
        local textureD = textureChche:addImage("UI/createCharacter/scrollIndicatorD.png")
        
        local offset = tablePlayer:getContentOffset()
        local offX = math.abs(math.min(offset.x, 0))
        local idx = math.ceil((offX/bkSize.width)) + 1
        idx = math.min(math.max(1,idx), 6)
        
        for i = 1, 6 do
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
    tablePlayer:registerScriptHandler(cellWillRecycle, 
        cc.Handler.TABLECELL_WILL_RECYCLE - cc.Handler.SCROLLVIEW_SCROLL) 
    
    nodePlayer:addChild(tablePlayer)
    tablePlayer:reloadData()    
end

function UICreatePlayer:getCurAvatarIdx()
    local offset = self.tablePlayer:getContentOffset()
    local offX = math.abs(math.min(offset.x, 0))
    local idx = math.ceil((offX/bkSize.width)) + 1
    idx = math.min(math.max(1,idx), 6)
    return idx
end

function UICreatePlayer:createWeapon()
    local nodeWeapon = cc.Node:create()
    nodeWeapon:setPosition(560,30)
    self.nodeMid:addChild(nodeWeapon)
    self.nodeWeapon = nodeWeapon
    
    self.createScale9Sprite("UI/createCharacter/frameRight.png", 
        {x = 0, y = 0}, {width = 360, height = 582}, {nodeWeapon})
        
    local function onBtnTouched(sender, type)
        local weaponID = 5001
        if sender == self.btnSword then
            weaponID = 5001
        elseif sender == self.btnRod then
            weaponID = 5101
        --[[elseif sender == self.btnGun then
            weaponID = 5201]]
        end

        local idx = self:getCurAvatarIdx()
        local cell = self.tablePlayer:cellAtIndex(idx - 1)
        if weaponID ~= selectedWeapon then
            selectedWeapon = weaponID
            self.tablePlayer:updateCellAtIndex(idx - 1)
        end
    end
--[[
    for i = 1, 3 do
        self.createSprite("UI/createCharacter/weaponBk.png",
            {x = 20, y = 110 + 130 * i}, {nodeWeapon, {x = 0, y = 0.5}})
    end
    ]]
    --[[
    self.createLabel(Lang.Gun, nil, {x = 200, y = 270}, nil, {nodeWeapon})
    self.createLabel(Lang.Rod, nil, {x = 200, y = 390}, nil, {nodeWeapon})
    self.createLabel(Lang.Sword, nil, {x = 200, y = 510}, nil, {nodeWeapon})
    ]]
    
    self.btnSword = self.createButton{
        pos = {x = 30, y = 420},
        icon = "UI/createCharacter/sword.png",
        handle = onBtnTouched,
        parent = nodeWeapon   
    }
    
    self.btnRod = self.createButton{
        pos = {x = 30, y = 285},
        icon = "UI/createCharacter/rod.png",
        handle = onBtnTouched,
        parent = nodeWeapon   
    }
    
    self.btnGun = self.createButton{
        pos = {x = 30, y = 150},
        icon = "UI/createCharacter/gun.png",
        handle = onBtnTouched,
        parent = nodeWeapon   
    }
    --self.btnGun:setEnable(false)

    local function onTextHandle(typestr)
        if typestr == "began" then
        elseif typestr == "changed" then
            local input = self.txtUserName:getText()
            local len = getLenInUtf8(input)
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

    self.txtUserName = ccui.EditBox:create({width = 244, height = 47},
        "UI/createCharacter/editbox.png")
    self.txtUserName:setPosition(60, 110)
    self.txtUserName:setAnchorPoint(0, 0.5)
    self.txtUserName:setFontColor({r = 0, g = 0, b = 0})
    self.txtUserName:registerScriptEditBoxHandler(onTextHandle)
    nodeWeapon:addChild(self.txtUserName)
    
    self.createButton{pos = {x = 230, y = 85},
        icon = "UI/createCharacter/random.png",
        handle = onBtnTouched,
        parent = nodeWeapon   
    } 

    local function onBtnCreate(sender, event)
        local idx = self:getCurAvatarIdx()
        local cell = self.tablePlayer:cellAtIndex(idx-1)
        local weaponID = selectedWeapon
        local userName = self.txtUserName:getText()
        print("*****create Avatar ID:"..idx.."\tname:"..userName)
        CMD_CREATE(idx, userName, weaponID)
    end
    
    self.createButton{pos = {x = 80, y = 15},
        icon = "UI/createCharacter/start.png",
        handle = onBtnCreate,
        parent = nodeWeapon   
    }
end

return UICreatePlayer