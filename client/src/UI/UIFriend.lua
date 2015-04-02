local UIFriend = class("UIFriend", function()
    return require("UI.UIBaseLayer").create()
end)

function UIFriend.create()
    local layer = UIFriend.new()
    return layer
end

function UIFriend:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
    self.schedulerID = nil
    self.curType = 1
    self.curSelIdx = 0
    self:setSwallowTouch()
    local layer = cc.LayerColor:create({r = 0, g = 0, b = 0, a = 120})
    self:addChild(layer)
    
    self:createUI()
    self.createSprite("UI/sign/dk.png", {x = 0, y = 0}, 
        {self.nodeMid, {x = 0, y = 0}})

    local function onBtnCloseTouched(sender, type)
        local scene = cc.Director:getInstance():getRunningScene()
        scene.hud:closeUI(self.class.__cname)
    end

    self.btnClose = self.createButton{pos = {x = 795, y = 540},
        icon = "UI/common/close.png",
        handle = onBtnCloseTouched,
        parent = self.nodeMid}
    self.btnClose:setLocalZOrder(1)    
    --self:popupMenu()
end

function UIFriend:createUI()
    self.nodeMid = cc.Node:create()
    self.nodeMid:setPositionX((self.visibleSize.width - DesignSize.width)/2)
    self:addChild(self.nodeMid) 

    local size = self.visibleSize
    self.createSprite("UI/sign/dkyy.png", {x = 0, y = 0}, 
        {self.nodeMid, {x = 0, y = 0}})
    if self.visibleSize.width/self.visibleSize.height < 1.5 then
        self.nodeMid:setScale(0.9)
        self.nodeMid:setPositionX(0)
    end  
    
    self.createSprite("UI/sign/yuefen.png", {x = 500, y = 540}, {self.nodeMid})
    self.createLabel("好    友", 26, 
        {x = 500, y = 540}, nil, {self.nodeMid})
        
    local function onBtnTouched(sender, event)
        self.curType = sender:getTag()
        self.tableFriend:reloadData()
    end 
        
    local btn = self.createButton{title = "当前好友",
        pos = {x = 220, y = 460},
        icon = "UI/shop/clk.png",
        handle = onBtnTouched,
        parent = self.nodeMid}
    btn:setPreferredSize({width = 120, height = 45})
    btn:setTag(1)
    
    local btn = self.createButton{title = "黑名单",
        pos = {x = 350, y = 460},
        icon = "UI/shop/clk.png",
        handle = onBtnTouched,
        parent = self.nodeMid}
    btn:setPreferredSize({width = 120, height = 45})
    btn:setTag(2)
    
    local function numOfCells(table)
        return 5
        --[[
        if self.curType == 1 then
            return #MgrFriend.Friend
        elseif self.curType == 2 then
            return #MgrFriend.Black
        end ]]
    end
    
    local function sizeOfCellIdx(table, idx)
        return 98, 541  --left->height, right->width
    end
    
    local function cellOfIdx(table, idx)
        local cell = table:dequeueCell()
        if cell == nil then
            cell = cc.TableViewCell:create()
            cell.back = self.createSprite("UI/friend/friendk.png", 
                {x = 0, y = 10}, {cell, {x = 0, y = 0}})
            
            self.createSprite("UI/friend/fiendxk.png", 
                {x = 50, y = 49}, {cell})
            cell.headIcon = self.createSprite("UI/main/head1.png", 
                {x = 50, y = 49}, {cell})
            cell.headIcon:setScale(0.6)
            
            cell.lblName = self.createLabel("一共七个字是吧", 22, 
                {x = 100, y = 49}, nil, {cell, {x = 0, y = 0.5}})
            cell.lblName:setColor(ColorBlack)
            cell.lblLevel = self.createLabel("7", 22, 
                {x = 300, y = 49}, nil, {cell, {x = 0, y = 0.5}})
            cell.lblLevel:setColor(ColorBlack)
        end
        
        local friendInfo = nil
        if self.curType == 1 then
            friendInfo = MgrFriend.Friend[idx+1]
        elseif self.curType == 2 then
            friendInfo = MgrFriend.Black[idx+1]
        end 
        
        --[[
        if friendInfo then
            local headPath = string.format("UI/main/head%d.png",
                friendInfo.avatarid)
            cell.headIcon:setTexture(headPath)
            cell.lblName:setString(friendInfo.nickname)
            cell.lblLevel:setString(friendInfo.level.."级")
        else
            return nil
        end
        ]]
        return cell
    end
    
    local function onCellTouched(table, tableviewcell)
        self.curSelIdx = tableviewcell:getIdx()+1
        self:popupMenu()
    end
    
    local tableFriend = cc.TableView:create({width = 541, height = 360})
    tableFriend:setDelegate()
    tableFriend:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    tableFriend:setPosition(225, 90)
    tableFriend:registerScriptHandler(numOfCells, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
    tableFriend:registerScriptHandler(sizeOfCellIdx, cc.TABLECELL_SIZE_FOR_INDEX)
    tableFriend:registerScriptHandler(onCellTouched, 
        cc.Handler.TABLECELL_TOUCHED - cc.Handler.SCROLLVIEW_SCROLL)
    tableFriend:registerScriptHandler(cellOfIdx, 
        cc.Handler.TABLECELL_AT_INDEX - cc.Handler.SCROLLVIEW_SCROLL)   --TODO cocos2dx lua bug
    self.nodeMid:addChild(tableFriend)
    tableFriend:reloadData()
    self.tableFriend = tableFriend
    
    self.createSprite("UI/sign/yy.png", 
        {x = 500, y = 110}, {self.nodeMid})
end

function UIFriend:onFriendListUpdate()
    self.tableFriend:reloadData()
end

function UIFriend:popupMenu()
    local back = self.createScale9Sprite("UI/friend/tytip.png", 
        {x = 480, y = 320}, {width = 141, height = 217}, 
        {self.nodeMid, {x = 0.5, y = 0.5}})
    
    local function onBtnTouched(sender, event)
        if self.curSelIdx < 1 then
            return
        end
        
        local friendID = 0
        if self.curType == 1 then
            friendID = MgrFriend.Friend[self.curSelIdx].chaid
        elseif self.curType == 2 then
            friendID = MgrFriend.Black[self.curSelIdx].chaid
        end 
        
        local tag = sender:getTag()
        if tag == 1 then
            CMD_FRIEND_PEEKINFO(friendID)
        elseif tag == 2 then
            --chat
        elseif tag == 3 then
            CMD_FRIEND_REMOVE(friendID)
        elseif tag == 4 then
            CMD_BLACK_ADD(friendID)
        elseif tag == 5 then
            CMD_BLACK_REMOVE(friendID)
        elseif tag == 6 then
            CMD_FRIEND_ADD(friendID)
        end
        back:removeFromParent()
    end
    
    if self.curType == 1 then
        local btn = self.createButton{title = "查看资料",
            pos = {x = 22, y = 20},
            icon = "UI/shop/clk.png",
            handle = onBtnTouched,
            parent = back}
        btn:setTag(1)
                    
        local btn = self.createButton{title = "私聊",
            pos = {x = 22, y = 65},
            icon = "UI/shop/clk.png",
            handle = onBtnTouched,
            parent = back}
        btn:setTag(2)
    
        local btn = self.createButton{title = "删除",
            pos = {x = 22, y = 110},
            icon = "UI/shop/clk.png",
            handle = onBtnTouched,
            parent = back} 
        btn:setTag(3)
            
        local btn = self.createButton{title = "加黑名单",
            pos = {x = 22, y = 155},
            icon = "UI/shop/clk.png",
            handle = onBtnTouched,
            parent = back}
        btn:setTag(4)
    elseif self.curType == 2 then
        --back:setScaleY(0.5)
        back:setPreferredSize({width = 141, height = 150})
        local btn = self.createButton{title = "解除黑名单",
            pos = {x = 22, y = 20},
            icon = "UI/shop/clk.png",
            handle = onBtnTouched,
            parent = back} 
        btn:setTag(5)
            
        local btn = self.createButton{title = "重新添加",
            pos = {x = 22, y = 80},
            icon = "UI/shop/clk.png",
            handle = onBtnTouched,
            parent = back}
        btn:setTag(6)
    end 
    
    local function onTouchBegan(touch, event)
            local location = touch:getLocation()
            local pos = back:getParent():convertToNodeSpace(location)
            local rect = back:getBoundingBox()
            
            if cc.rectContainsPoint(rect, pos) then    
                return true
            end
            
            back:removeFromParent()
            return true
    end

    local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN)
    listener:setSwallowTouches(true)
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, back)
end

return UIFriend