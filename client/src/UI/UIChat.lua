local UIChat = class("UIChat", function()
    return require("UI.UIBaseLayer").create()
end)

function UIChat.create()
    local layer = UIChat.new()
    return layer
end

function UIChat:ctor()
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
    
    local function onNodeEvent(event)
        if "enter" == event then
            self.tableChat:reloadData()
            self:updateTarget()
            self.tableChat:setContentOffset({x = 0, y = 0})
        elseif "exit" == event then
            MgrChat.Target = nil
        end
    end
    self:registerScriptHandler(onNodeEvent)
end

function UIChat:createUI()
    self.nodeMid = cc.Node:create()
    self.nodeMid:setPositionX((self.visibleSize.width - DesignSize.width)/2)
    self:addChild(self.nodeMid) 

    local size = self.visibleSize
    self.createSprite("UI/friend/liaotiank.png", {x = 175, y = 55}, 
        {self.nodeMid, {x = 0, y = 0}})
    if self.visibleSize.width/self.visibleSize.height < 1.5 then
        self.nodeMid:setScale(0.9)
        self.nodeMid:setPositionX(0)
    end  
    
    --[[
    self.createSprite("UI/sign/yuefen.png", {x = 500, y = 540}, {self.nodeMid})
    self.createLabel("聊  天", 26, 
        {x = 500, y = 540}, nil, {self.nodeMid})
    ]]        
    
    local function onBtnTouched(sender, event)
        self.curType = sender:getTag()
        if self.curType == 1 then
            MgrChat.Target = nil
        end
        self.tableChat:reloadData()
    end 
        
    local btn = self.createButton{title = "世界",
        pos = {x = 260, y = 530},
        icon = "UI/shop/clk.png",
        handle = onBtnTouched,
        parent = self.nodeMid}
    btn:setPreferredSize({width = 120, height = 45})
    btn:setTag(1)
    
    local btn = self.createButton{title = "私聊",
        pos = {x = 400, y = 530},
        icon = "UI/shop/clk.png",
        handle = onBtnTouched,
        parent = self.nodeMid}
    btn:setPreferredSize({width = 120, height = 45})
    btn:setTag(2)
    
    local function numOfCells(table)
        if self.curType == 1 then
            return #MgrChat.World
        elseif self.curType == 2 then
            local count = 0
            for _, value in pairs(MgrChat.Private) do
                if value.sender == MgrChat.Target then
                    count = count + 1
                end 
            end
            return count
        end
    end
    
    local function sizeOfCellIdx(table, idx)
        return 60, 400  --left->height, right->width
    end
    
    local function cellOfIdx(table, idx)
        local cell = table:dequeueCell()
        if cell == nil then
            cell = cc.TableViewCell:create()
            --[[
            cell.back = self.createSprite("UI/friend/friendk.png", 
                {x = 0, y = 10}, {cell, {x = 0, y = 0}})
            ]]
            cell.lblContent = self.createLabel("一共七个字是吧sdl;afds;afdks;alfdsa'f;dlsa;", 22, 
                {x = 10, y = 40}, nil, {cell, {x = 0, y = 0.5}})
            --cell.lblName:setColor(ColorBlack)
        end
        
        local chatInfo = nil
        if self.curType == 1 then
            chatInfo = MgrChat.World[idx+1]
        elseif self.curType == 2 then
            local tempInfo = {}
            for i = 1,  i <= #MgrChat.Private do
                if MgrChat.Private[i].sender == MgrChat.Target then
                    table.insert(tempInfo, MgrChat.Private[i])
                end 
            end
            chatInfo = tempInfo[idx+1]
        end 
        
        if chatInfo ~= nil then
            cell.lblContent:setString(chatInfo.sender..":"..chatInfo.content)
        else
            cell.lblContent:setString("")
        end
        return cell
    end
    
    local function onCellTouched(table, tableviewcell)
        self.curSelIdx = tableviewcell:getIdx()+1
        self:popupMenu()
    end
    
    local tableChat = cc.TableView:create({width = 541, height = 350})
    tableChat:setDelegate()
    tableChat:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    tableChat:setPosition(225, 160)
    tableChat:registerScriptHandler(numOfCells, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
    tableChat:registerScriptHandler(sizeOfCellIdx, cc.TABLECELL_SIZE_FOR_INDEX)
    tableChat:registerScriptHandler(onCellTouched, 
        cc.Handler.TABLECELL_TOUCHED - cc.Handler.SCROLLVIEW_SCROLL)
    tableChat:registerScriptHandler(cellOfIdx, 
        cc.Handler.TABLECELL_AT_INDEX - cc.Handler.SCROLLVIEW_SCROLL)   --TODO cocos2dx lua bug
    self.nodeMid:addChild(tableChat)
    --tableChat:reloadData()
    self.tableChat = tableChat
    
    self.lblTarget = self.createLabel("世界：", 26, 
        {x = 270, y = 120}, nil, {self.nodeMid})
        
    local function onTextHandle(typestr)
        if typestr == "began" then
        elseif typestr == "changed" then

        elseif typestr == "ended" then

        elseif typestr == "return" then

        end
        --return true
    end

    self.txtInput = ccui.EditBox:create({width = 400, height = 60},
        "UI/login/txtInput.png")
    --self.createScale9Sprite("UI/login/txtInput.png", nil, {widht = 255, height = 55}, {}))
    self.txtInput:setPosition(300, 125)
    self.txtInput:setAnchorPoint(0, 0.5)
    self.txtInput:setMaxLength(20)
    --self.txtInput:registerScriptEditBoxHandler(onTextHandle)
    self.nodeMid:addChild(self.txtInput)
    
    local function onSendTouched(sender, event)
        local str = self.txtInput:getText()
        if string.len(str) > 0 then
            CMD_CHAT(MgrChat.Target, str)
        else
        end
        self.txtInput:setText("")
    end    

    self.createButton{
        title = "发 送",
        ignore = false,
        icon = "UI/pve/kstz.png",
        pos = {x = 740, y = 125},
        handle = onSendTouched,
        parent = self.nodeMid
    }       
end

function UIChat:updateTarget()
    if MgrChat.Target and string.len(MgrChat.Target) > 0 then
        self.lblTarget:setString(MgrChat.Target..":")
    else
        self.lblTarget:setString("世界：")
    end
end

function UIChat:onUpdateChat()
    self.tableChat:reloadData()
    local off = self.tableChat:getContentOffset()
    self.tableChat:setContentOffset({x = 0, y = 0})
end

return UIChat