local netCmd = require "src.net.NetCmd"

local UIDayMission = class("UIDayMission", function()
    return require("UI.UIBaseLayer").create()
end)

local TaskState = {}

function UIDayMission.create()
    CMD_EVERYDAYTASK()
    local layer = UIDayMission.new()
    return layer
end

function UIDayMission:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
    self.schedulerID = nil
    self:setSwallowTouch()
    local layer = cc.LayerColor:create({r = 0, g = 0, b = 0, a = 120})
    self:addChild(layer)
    self:createUI()
    self.createSprite("UI/sign/dk.png", {x = 0, y = 0}, 
        {self.nodeMid, {x = 0, y = 0}})
        
    local function onBtnCloseTouched(sender, type)
        cc.Director:getInstance():getRunningScene().hud:closeUI(self.class.__cname)
    end

    self.btnClose = self.createButton{pos = {x = 795, y = 540},
        icon = "UI/common/close.png",
        handle = onBtnCloseTouched,
        parent = self.nodeMid}
    self.btnClose:setLocalZOrder(1)    
end

function UIDayMission:createUI()
    self.nodeMid = cc.Node:create()
    self.nodeMid:setPositionX((self.visibleSize.width - DesignSize.width)/2)
    self:addChild(self.nodeMid)   

    local size = self.visibleSize
    self.createSprite("UI/sign/dkyy.png", {x = 0, y = 0}, {self.nodeMid, {x = 0, y = 0}})
    if self.visibleSize.width/self.visibleSize.height < 1.5 then
        self.nodeMid:setScale(0.9)
        self.nodeMid:setPositionX(0)
    end

    self.createSprite("UI/sign/yuefen.png", {x = 500, y = 540}, {self.nodeMid})
    self.createLabel("每日任务", 26, 
        {x = 500, y = 540}, nil, {self.nodeMid})

    --local tableTask = TableDay_Task

    local function onGetAwardTouched(sender, event)
        CMD_EVERYDAYTASK_GETAWARD(sender:getTag())        
    end

    local function numOfCells(table)
        return #TaskState
    end

    local function sizeOfCellIdx(table, idx)
        return 140, 585  --left->height, right->width
    end

    local function cellOfIdx(table, idx)
        local cell = table:dequeueCell()
        
        if cell == nil then
            cell = cc.TableViewCell:create()

            cell.back = self.createSprite("UI/task/k.png", 
                {x = 0, y = 10}, {cell, {x = 0, y = 0}})
            
            local back = self.createSprite("UI/bag/iconB.png", 
                {x = 56, y = 60}, {cell.back})
            back:setScale(1.2)
            
            cell.itemIcon = self.createSprite("icon/taskIcon/5renpve.png", 
                {x = 56, y = 60}, {cell.back})   
            cell.itemIcon:setScale(0.6)   
            
            self.createSprite("UI/task/dk.png", 
                {x = 110, y = 78}, {cell.back, {x = 0, y = 0.5}})   
                
            cell.lblName = self.createLabel(" ", 22, 
                {x = 120, y = 78}, nil, {cell.back, {x = 0, y = 0.5}})

            cell.lblDes = self.createLabel(" ", 20, 
                {x = 120, y = 45}, nil, {cell.back, {x = 0, y = 0.5}})
            cell.lblDes:setColor(ColorBlack)
            
            local lbl = self.createLabel("奖励：", 20, 
                {x = 120, y = 20}, nil, {cell.back, {x = 0, y = 0.5}})
            lbl:setColor{r = 106, g = 57, b = 6}
            
            cell.lblCount =  self.createLabel("0/5", 20, 
                {x = 520, y = 78}, nil, {cell.back, {x = 0, y = 0.5}})
            cell.lblCount:setColor{r = 106, g = 57, b = 6}
            
            cell.btnGet = self.createButton{title = "领 取",
                ignore = false, 
                pos = {x = 520, y = 60},
                icon = "UI/pve/kstz.png",
                handle = onGetAwardTouched,
                parent = cell.back}
            cell.btnGet:setPreferredSize({width = 100, height = 40})
            lbl = cell.btnGet:getTitleLabelForState(cc.CONTROL_STATE_NORMAL)
            lbl:enableOutline(ColorBlack, 2)

            local iconAward1 = cc.Sprite:create()
            iconAward1:setPosition(200,20)
            iconAward1:setScale(0.75)
            local lblAwardNum1 = self.createLabel("x1000000", 20, 
                {x = 225, y = 20}, nil, {cell.back, {x = 0, y = 0.5}})
            lblAwardNum1:setColor{r = 106, g = 57, b = 6}
            
            cell.back:addChild(iconAward1)

            local iconAward2 = cc.Sprite:create()
            iconAward2:setPosition(340,20)
            iconAward2:setScale(0.75)
            cell.back:addChild(iconAward2)
            local lblAwardNum2 = self.createLabel("x1000000", 20, 
                {x = 365, y = 20}, nil, {cell.back, {x = 0, y = 0.5}})
            lblAwardNum2:setColor{r = 106, g = 57, b = 6}
            
            cell.iconAward = {iconAward1, iconAward2}
            cell.lblAwardNum = {lblAwardNum1, lblAwardNum2}
            --[[
            local begin, last = string.find(str,":")
            local needItemID = tonumber(string.sub(str, 1, begin - 1))
            local needItemNum = tonumber(string.sub(str, begin + 1, string.len(str)))
            ]]
        end
        
        local curTaskState = TaskState[idx+1]
        local taskInfo = TableDay_Task[curTaskState.id]
        cell.btnGet:setTag(curTaskState.id)

        local awardItems = taskInfo.Award 
        local begin, last = string.find(awardItems,",")
        local str1 = string.sub(awardItems, 1, begin - 1)
        local str2 = string.sub(awardItems, last+1, #awardItems)
        local strs = {str1, str2}
        for i = 1, #strs do
            begin, last = string.find(strs[i],":")
            local itemID = tonumber(string.sub(strs[i], 1, begin - 1))
            local itemNum = tonumber(string.sub(strs[i], begin + 1, string.len(strs[i])))
            local itemInfo = TableItem[itemID]
            local iconPath = "icon/SmallIcon/"..itemInfo.Small_Icon..".png"
            cell.iconAward[i]:setTexture(iconPath)
            cell.lblAwardNum[i]:setString("x"..itemNum)
        end
        
        if curTaskState.count >= taskInfo.Number then
            cell.back:setTexture("UI/task/k2.png")
            cell.btnGet:setVisible(true)
            cell.lblCount:setVisible(false)
        else
            cell.btnGet:setVisible(false)
            cell.lblCount:setVisible(true)
            cell.lblCount:setString(curTaskState.count.."/"..taskInfo.Number)
            cell.back:setTexture("UI/task/k.png")
        end

        cell.itemIcon:setTexture("icon/taskIcon/"..taskInfo.Icon..".png")
        cell.lblName:setString(taskInfo.Task_Name)
        cell.lblDes:setString(taskInfo.Description)

        return cell
    end

    local tableTask = cc.TableView:create({width = 585, height = 420})
    tableTask:setDelegate()
    tableTask:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    tableTask:setPosition(225, 90)
    tableTask:registerScriptHandler(numOfCells, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
    tableTask:registerScriptHandler(sizeOfCellIdx, cc.TABLECELL_SIZE_FOR_INDEX)
    tableTask:registerScriptHandler(cellOfIdx, 
        cc.Handler.TABLECELL_AT_INDEX - cc.Handler.SCROLLVIEW_SCROLL)   --TODO cocos2dx lua bug
    self.nodeMid:addChild(tableTask)
    self.tableTask = tableTask
    --tableTask:reloadData()
end

function UIDayMission:UpdateMission()
    self.tableTask:reloadData()
end

RegNetHandler(function (packet) 
    TaskState = {}
    for i = 1, #packet.tasks do
        if packet.tasks[i].awarded == 0 then
            local task = {}
            task.id = i
            task.count = packet.tasks[i].count
            
            local taskInfo = TableDay_Task[i]
            if task.count >= taskInfo.Number then
                table.insert(TaskState, 1, task)
            else
                table.insert(TaskState, task)
            end            
        end
    end
    
    local hud = cc.Director:getInstance():getRunningScene().hud
    local mission = hud:getUI("UIDayMission")
    if mission then
        mission:UpdateMission()
    end
end, netCmd.CMD_GC_EVERYDAYTASK)

RegNetHandler(function (packet) 
    for i = 1, #TaskState do
        if TaskState[i].id == packet.id then
            table.remove(TaskState, i)
            break
        end
    end
    
    local hud = cc.Director:getInstance():getRunningScene().hud
    local mission = hud:getUI("UIDayMission")
    if mission then
        mission:UpdateMission()
    end
end,netCmd.CMD_GC_EVERTDAYTASK_AWARD)

return UIDayMission