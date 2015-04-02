local UIMessage = require "UI.UIMessage"
local comm = require("common.CommonFun")

local UIMail = class("UIMail", function()
    return require("UI.UIBaseLayer").create()
end)

function UIMail:create()
    local layer = UIMail.new()
    return layer
end

function UIMail:ctor()
    CMD_GETMAILLIST()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
    self.schedulerID = nil
    self.curType = 1

    self:createBack()
    self:setSwallowTouch()  
    self:createLeft()
    self:createRight()
end

function UIMail:createLeft()
    local backL = self.createSprite("UI/character/kkkkkk.png", 
        {x= 240, y = 315}, {self.nodeMid})
    backL:setScaleX(0.9)
    backL:setScaleY(1.1)
    backL:setFlippedX(true)
    backL:setOpacity(200)
    backL:setLocalZOrder(-1)
    
    local function onGetCodeTouched(sender, event)
        
    end
    
    self.createButton{pos = { x = 180, y = 510},
        icon = "UI/mail/dh.png",
        handle = onGetCodeTouched,
        parent = self.nodeMid}
    
    local function numOfCells(table)
        return #MgrMail
    end
    
    local function sizeOfCellIdx(table, idx)
        return 70, 300  --left->height, right->width
    end

    local function cellOfIdx(table, idx)
        local cell = table:dequeueCell()
        
        if cell == nil then
            cell = cc.TableViewCell:create()
            cell.backD = self.createSprite("UI/mail/k1.png", 
                {x = 140, y = 40}, {cell})
                
            cell.backS = self.createSprite("UI/mail/k2.png", 
                {x = 140, y = 40}, {cell})

            cell.lblName = self.createLabel("小苹果------", 22, 
                {x = 50, y = 40}, nil, {cell, {x = 0, y = 0.5}})
            cell.lblName:setColor({r = 0, g = 0, b = 0})
            cell.iconReaded = self.createSprite("UI/mail/d.png", 
                {x = 35, y = 50}, {cell})  
            cell.iconReaded:setScale(0.6)
        end
        
        local bSel = self.curIdx == idx
        cell.backD:setVisible(not bSel)
        cell.backS:setVisible(bSel)
        
        local mailInfo = MgrMail[idx+1] 
        cell.lblName:setString(mailInfo.title)
        
        cell.iconReaded:setVisible(not mailInfo.readed)
        return cell
    end
    
    local function onCellTouched(tableview, tableviewcell)
        local touchPoint = tableviewcell:getTouchedPoint()
        local cellIdx = tableviewcell:getIdx()
        
        self.curIdx = cellIdx
        local mailInfo = MgrMail[cellIdx+1]
        self.mailContent:setString(mailInfo.content) 
        CMD_MAILMARKREAD(mailInfo.idx)
        mailInfo.readed = true
        
        --[[
        if not mailInfo.attachments then
            CMD_MAILDELETE(mailInfo.idx)
        end
        ]]
        
        table.remove(MgrMail, cellIdx+1)
        self.curIdx = -1
        
        tableview:reloadData()
    end
    
    local tableMailList = cc.TableView:create({width = 260, height = 350})
    tableMailList:setDelegate()
    tableMailList:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    tableMailList:setPosition(115, 150)
    tableMailList:registerScriptHandler(numOfCells, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
    tableMailList:registerScriptHandler(sizeOfCellIdx, cc.TABLECELL_SIZE_FOR_INDEX)
    tableMailList:registerScriptHandler(onCellTouched, 
        cc.Handler.TABLECELL_TOUCHED - cc.Handler.SCROLLVIEW_SCROLL)
    tableMailList:registerScriptHandler(cellOfIdx, 
        cc.Handler.TABLECELL_AT_INDEX - cc.Handler.SCROLLVIEW_SCROLL)   --TODO cocos2dx lua bug
    self.nodeMid:addChild(tableMailList)
    self.tableMailList = tableMailList
    self.tableMailList:reloadData()
end

function UIMail:createRight()
    local back = self.createSprite("UI/bag/dw2.png", 
        {x = 637, y = 318}, {self.nodeMid})
    back:setScaleX(1.3)
    back:setLocalZOrder(-1)
    self.createSprite("UI/common/split.png", 
        {x = 400, y = 318}, {self.nodeMid})
    self.createLabel("邮 件", 24, 
        {x = 400, y = 550}, nil, {self.nodeMid})
        
    local s = [["除了工具和源代码外，虚幻引擎4还提供了完整的生态系统。 您可以在论坛中交流，把内容添加到wiki，参与AnswerHub问答，并通过GitHub加入合作的开发项目。 您可以在虚幻商城中购买内容，也可以自己创建内容并在商城中销售。

为帮助您入门，虚幻引擎包含了大量的视频教程和文档，以及可用于引擎的游戏模板、示例和内容。

虚幻引擎现已免费

在2014年早些时候，我们采取了革命性的举措，以每月19美元的订购价格让每个人都可以使用虚幻引擎4。 我们把所有源代码放到了网上，让每个注册的人都可以使用。 我们扳动了开关然后默默祈祷。

去年对每个在Epic Games的员工来说都非常忙碌。 我们的社区人数暴增。 我们完成的创意工作的质量和多样性令人惊讶。 当我们邀请大家提交今年在GDC展出的项目时，我们不得不从100个最佳作品中挑选出8个以供展出。

虚幻引擎目前的状态很好，我们认为如果去除价格这个门槛，更多的人就能完成他们的创意目标并塑造我们所热爱的媒体的未来。 所以我们去除了这最后一道门槛，最终让虚幻引擎免费。

感谢社区

对去年陪伴我们的各位朋"]]
    local lbl = self.createLabel("", 18, 
        {x = 450, y = 480}, nil, {self.nodeMid, {x = 0, y = 1}}, {width = 350, height = 300})
    self.mailContent = lbl
    lbl:setColor(ColorBlack)
end

function UIMail:UpdateMailList()
    self.tableMailList:reloadData()
end

return UIMail