local Pseudo = require "src.pseudoserver.pseudoserver"
local netCmd = require "src.net.NetCmd"
local UIMessage = require "UI.UIMessage"

local UIPVE = class("UIPVE", function()
    return require("UI.UIBaseLayer").create()
end)

--[[
local maxlevel = 19
local curMaxLevel = 39
local lastGetAward = 1
]]

function UIPVE:create()
    local layer = UIPVE.new()
    return layer
end

function UIPVE:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
    self.schedulerID = nil
    self:setSwallowTouch()  
    self:cteateLeft() 
    self:createRight()
    
    local function onNodeEvent(event)
        if "enter" == event then
        elseif "exit" == event and self.schedulerID then
            cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.schedulerID)
        end
    end
    self:registerScriptHandler(onNodeEvent)
end

function UIPVE:cteateLeft()
    local spr = self.createSprite("UI/pve/dt.png", {x = 188, y = 320}, {self})
    spr:setLocalZOrder(1)
    
    local function onBtnBackTouched(sender, event)                
        Pseudo.DestroyMap() 
        local scene = require("SceneLoading").create(205)
        cc.Director:getInstance():replaceScene(scene)
    end
    
    self.createButton({pos = {x = self.visibleSize.width-80, y = self.visibleSize.height-90},
        icon = "UI/fight/back.png",
        handle = onBtnBackTouched,
        parent = spr
    })
    
    local quick = cc.Node:create()
    spr:addChild(quick)    
    self.quick = quick
    quick:setVisible(false)
    self.createSprite("UI/pve/syucisu.png", {x = 160, y = 500}, {quick})
    self.lblRemainTimes = self.createBMLabel("fonts/pve.fnt", 11, 
        {x = 245, y = 500}, {quick, {x = 0, y = 0.5}})
        
    self.createSprite("UI/pve/hk.png", {x = 170, y = 400}, {quick}) 
    
    self.createBMLabel("fonts/pve.fnt", "第1关", 
        {x = 80, y = 400}, {quick, {x = 0, y = 0.5}})
    
    local function onBeginTouched(sender, event)
    
    end    
    
    self.createButton{
        title = "开始闯关",
        ignore = false,
        icon = "UI/pve/kstz.png",
        pos = {x = 220, y = 400},
        handle = onBeginTouched,
        parent = quick
    }       
    
    local fastNode = cc.Node:create()
    self.fastNode = fastNode
    quick:addChild(fastNode)
    
    self.createSprite("UI/pve/hk.png", {x = 170, y = 280}, {fastNode})
    self.createSprite("UI/pve/hk.png", {x = 170, y = 160}, {fastNode})   
    
    self.createSprite("UI/main/bk.png", {x = 100, y = 300}, {fastNode})
    self.lblNeedShell1 = self.createBMLabel("fonts/pve.fnt", "123456", 
        {x = 130, y = 300}, {fastNode, {x = 0, y = 0.5}})
    self.lblQuickLevel1 = self.createBMLabel("fonts/pve.fnt", "第1关", 
        {x = 80, y = 260}, {fastNode, {x = 0, y = 0.5}})
    self.createButton{
        title = "快速闯关",
        ignore = false,
        icon = "UI/pve/kstz.png",
        pos = {x = 220, y = 260},
        handle = onBeginTouched,
        parent = fastNode
    }    

    self.createSprite("UI/main/zz.png", {x = 100, y = 180}, {fastNode})
    self.lblNeedPearl2 = self.createBMLabel("fonts/pve.fnt", "123456", 
        {x = 130, y = 180}, {fastNode, {x = 0, y = 0.5}})
    self.lblQuickLevel2 = self.createBMLabel("fonts/pve.fnt", "第1关", 
        {x = 80, y = 140}, {fastNode, {x = 0, y = 0.5}})
    self.createButton{
        title = "极速闯关",
        ignore = false,
        icon = "UI/pve/kstz.png",
        pos = {x = 220, y = 140},
        handle = onBeginTouched,
        parent = fastNode
    }    
    
    local curInfo = cc.Node:create()
    self.curInfo = curInfo
    spr:addChild(curInfo)
    
    self.createSprite("UI/pve/dixguan.png", {x = 170, y = 500}, {curInfo})
    self.lblCurLevel = self.createBMLabel("fonts/pve.fnt", 1, 
        {x = 180, y = 495}, {curInfo})
        
    self.createLabel("当前累计奖励：", 22, {x = 150, y = 430}, nil, {curInfo})
    self.createSprite("UI/pve/hk.png", {x = 170, y = 350}, {curInfo})
    
    self.createSprite("UI/main/exp.png", {x = 100, y = 370}, {curInfo})
    self.createLabel("经验:", 20, {x = 150, y = 370}, nil, {curInfo})
    self.lblCurGetExp = self.createLabel("123456", 20, {x = 180, y = 370}, 
        nil, {curInfo, {x = 0, y = 0.5}})
    self.createSprite("UI/main/bk.png", {x = 100, y = 330}, {curInfo})
    self.createLabel("贝壳:", 20, {x = 150, y = 330}, nil, {curInfo})
    self.lblCurGetShell = self.createLabel("123456", 20, {x = 180, y = 330}, 
        nil, {curInfo, {x = 0, y = 0.5}})
        
    self.lblFailedCount = self.createLabel("已经有42个人在本关跪了", 20, 
        {x = 60, y = 260}, nil, {curInfo, {x = 0, y = 0}})
        
    local function getLeave(...)
        --[[
        local maxlevel = maincha.attr.spve_history_max
        local curMaxLevel = maincha.attr.spve_today_max
        local lastGetAward = maincha.attr.spve_last_award

        self.lblCurLevel:setString(curMaxLevel+1) 
        local getExp = 0
        local getShell = 0

        for i = lastGetAward + 1, curMaxLevel do
            local copy = TableSingle_Copy_Balance[i]
            getExp = getExp + copy.Experience
            getShell = getShell + copy.Shell
        end    
        
        addItem(4001, getShell)
        addItem(4004, getExp)
        ]]
        CMD_PVE_GETAWARD()
        Pseudo.DestroyMap() 
        local scene = require("SceneLoading").create(205)
        cc.Director:getInstance():replaceScene(scene)
    end
        
    local btn = self.createButton{title = "拿奖走人",
        icon = "UI/common/k.png",
        ignore= false,
        pos = {x = 170, y = 180},
        handle = getLeave,
        parent = curInfo
    }
    btn:setTitleTTFSizeForState(26, cc.CONTROL_STATE_NORMAL)
    self.createLabel("剩余士气值：", 18, {x = 160, y = 130}, nil, {curInfo})
    self.createLabel("20", 18, {x = 210, y = 130}, nil, {curInfo, {x = 0, y = 0.5}})
    
    local function onSwitchTouched(...)
    --[[
        if self.quick:isVisible() then
            self.quick:setVisible(false)
            self.curInfo:setVisible(true)
        else
            self.quick:setVisible(true)
            self.curInfo:setVisible(false)
        end        
        ]]
    end

    self.createButton{
        ignore = false, 
        pos = {x = 40, y = 600},
        icon = "UI/pve/fz.png",
        handle = onSwitchTouched,
        parent = spr}
end

function UIPVE:createRight()
    local map = cc.Sprite:create()
    map:setPositionX(350)
    --map:setLocalZOrder(-1)
    self.map = map
    self:addChild(map)
    
    local cache = cc.Director:getInstance():getTextureCache()
    local text = cache:addImage("UI/pve/mapp.png")
    text:setAntiAliasTexParameters()

    local spr = cc.Sprite:createWithTexture(text)
    spr:setAnchorPoint(cc.p(0, 0))
    spr:setPosition(0, 0)
    spr:setScale(1.36)
    map:addChild(spr)
    local spr = cc.Sprite:createWithTexture(text)
    spr:setAnchorPoint(cc.p(0, 0))
    spr:setPosition(1000, 0)
    spr:setScale(1.36)
    map:addChild(spr)
    local spr = cc.Sprite:createWithTexture(text)
    spr:setAnchorPoint(cc.p(0, 0))
    spr:setPosition(2000, 0)
    spr:setScale(1.36)
    map:addChild(spr)
--[[
    local spr = self.createSprite("UI/pve/mapp.png", {x = 0, y = 0}, {map, {x = 0, y = 0}})
    spr:setScale(1.36)
    spr = self.createSprite("UI/pve/mapp.png", {x = 1000, y = 0}, {map, {x = 0, y = 0}})
    spr:setScale(1.36)
    spr = self.createSprite("UI/pve/mapp.png", {x = 2000, y = 0}, {map, {x = 0, y = 0}})
    spr:setScale(1.36)
]]
    local curState = 0    
    
    local touchBeginPoint = nil
    local bMoved = false
    local beginPos = nil
    
    local function onTouchBegan(touch, event)
        local location = touch:getLocation()
        touchBeginPoint = {x = location.x, y = location.y}
        beginPos = {x = location.x, y = location.y}
        
        return true
    end

    local function onTouchMoved(touch, event)
        local location = touch:getLocation()
        local cx, cy = map:getPosition()
        local posX = cx + location.x - touchBeginPoint.x
        touchBeginPoint = {x = location.x, y = location.y}
        posX = math.max(math.min(350, posX), self.visibleSize.width - 3000)
        map:setPositionX(posX)
        
        if not bMoved and 
            cc.pGetDistance(beginPos, {x = location.x, y = location.y}) > 20 then
            bMoved = true
        end        
    end

    local pos = require "UI.PVEPos"
    local pos1, pos2 = pos[1], pos[2]
    self.allSPoint = {}
    self.allLPoint = {}
    
    local function createPoint()
        --[[
        for _, v in pairs(self.allSPoint) do
            v:removeFromParent()
        end
        self.allPoint = {}
        ]]
        for idx, pos in pairs(pos1) do
            local point = self.createSprite("UI/pve/dd.png", {x = pos1[idx][1], y = pos1[idx][2]}, {map})
            point:setVisible(false)
            point:setTag(pos1[idx][3])
            table.insert(self.allSPoint, point)
        end

        for idx = 1, #pos2 do
            local point = self.createSprite("UI/pve/dian.png", {x = pos2[idx][1], y = pos2[idx][2]}, {map})
            point:setTag(idx)
            point:setVisible(false)
            table.insert(self.allLPoint, point)
        end         
        --[[
        local f = io.open("PVE_POS.txt", "w")
        f:write("pos1 = {\n")
        for i = 1, #pos1 do
        f:write("{"..pos1[i][1]..","..pos1[i][2]..","..pos1[i][3].."}\n")
        end
        f:write("}\n")
        f:write("pos2 = {\n")
        for i = 1, #pos2 do
            f:write("{"..pos2[i][1]..","..pos2[i][2].."}\n")
        end
        f:write("}\n")
        f:close()
        ]]
    end
    
    local function onTouchEnded(touch, event)        
        if not bMoved then                    
            local curMaxLevel = maincha.attr.spve_today_max
            local point = self.allLPoint[math.min(curMaxLevel+1, 60)]
            local box = point:getBoundingBox()
            local nodePos = point:getParent():convertToNodeSpace(beginPos)
            if not cc.rectContainsPoint(box, nodePos) then
                for level, spr in pairs(self.allLPoint) do
                    if level ~= curMaxLevel+1 and spr:isVisible() then
                        local pBox = spr:getBoundingBox()
                        local pos = spr:getParent():convertToNodeSpace(beginPos)
                        if cc.rectContainsPoint(pBox, pos) then
                            UIMessage.showMessage(Lang.TouchPoint)
                            break
                        end
                    end
                end          
            else
                local curMaxLevel = maincha.attr.spve_today_max
                Pseudo.BegPlay(curMaxLevel + 1)
                cc.Director:getInstance():getRunningScene().hud:closeUI(self.class.__cname)
            end
        end
        bMoved = false
    end

    local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
    listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
    listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, map)
    
    createPoint()
    
    self.iconSpr = self.createSprite("UI/pve/jt.png", {x = 100, y = 100}, {map})
    local ac1 = cc.MoveBy:create(0.3, {x = 0, y = 10})
    local ac2 = cc.MoveBy:create(0.2, {x = 0, y = -10})
    self.iconSpr:runAction(cc.RepeatForever:create(cc.Sequence:create(ac1, ac2)))
    self.iconSpr:setVisible(false)
    self:updateUI()
    
    --[[
    for idx, pos in pairs(pos1) do
        self.createSprite("UI/pve/dd.png", {x = pos1[idx][1], y = pos1[idx][2]}, {map})
    end
    
   for idx, pos in pairs(pos2) do
    self.createSprite("UI/pve/dian.png", {x = pos2[idx][1], y = pos2[idx][2]}, {map})
    end
    ]]
    
    --[[
    local function onClearTouched(...)
        if curState == 1 then
            local pos = pos1[#pos1]
            if pos[3] == #pos2 then
    table.remove(pos2, #pos2)
            else
                table.remove(pos1, #pos1)
            end

    elseif curState == 2 then
    table.remove(pos2, #pos2)
    curState = 1
    end
    UpdatePos()
    end 

    local btn = self.createButton{title = "clear",
        ignore = false, 
        pos = {x = 130, y = 60},
        icon = "UI/pve/kstz.png",
        handle = onClearTouched,
        parent = self.curInfo}
        
    local function onP1Touched(...)
        curState = 1 
    end    
    btn = self.createButton{
        ignore = false, 
        pos = {x = 200, y = 60},
        icon = "UI/pve/dd.png",
        handle = onP1Touched,
        parent = self.curInfo}
        
    local function onP2Touched(...)
        curState = 2 
    end        
    btn = self.createButton{
        ignore = false, 
        pos = {x = 240, y = 60},
        icon = "UI/pve/dian.png",
        handle = onP2Touched,
        parent = self.curInfo}
        ]]
end

function UIPVE:updateQuick()
    local maxlevel = maincha.attr.spve_history_max
    local curMaxLevel = maincha.attr.spve_today_max
    local lastGetAward = maincha.attr.spve_last_award
    
    if maxlevel >= 20 then
        self.fastNode:setVisible(maxlevel >= 20)
        local level1 = math.ceil(maxlevel/2)+5
    	local copy1 = TableSingle_Copy_Balance[level1]
    	self.lblNeedShell1:setString(copy1.Expend_Shell)
    	self.lblQuickLevel1:setString(string.format("第%d关",level1))
    	
    	local level2 = maxlevel - 3
        local copy1 = TableSingle_Copy_Balance[level2]
        self.lblNeedPearl2:setString(copy1.Expend_Pearl)
        self.lblQuickLevel2:setString(string.format("第%d关",level2))    
    end
end

function UIPVE:updateAward()
    local maxlevel = maincha.attr.spve_history_max
    local curMaxLevel = maincha.attr.spve_today_max
    local lastGetAward = maincha.attr.spve_last_award

    self.lblCurLevel:setString(curMaxLevel+1) 
    local getExp = 0
    local getShell = 0
    
    for i = lastGetAward + 1, curMaxLevel do
        local copy = TableSingle_Copy_Balance[i]
        getExp = getExp + copy.Experience
        getShell = getShell + copy.Shell
    end    
    self.lblCurGetExp:setString(getExp)
    self.lblCurGetShell:setString(getShell)
end

function UIPVE:updateUI()
    local maxlevel = maincha.attr.spve_history_max
    local curMaxLevel = maincha.attr.spve_today_max
    local lastGetAward = maincha.attr.spve_last_award

    if curMaxLevel == 0 then
        self.quick:setVisible(true)
        self.curInfo:setVisible(false)
        self.fastNode:setVisible(maxlevel >= 20)
    else
        self.quick:setVisible(false)
        self.curInfo:setVisible(true)
    end
    
    local allPoint = {}
    for i = 1, curMaxLevel + 1 do
        for _, p in pairs(self.allSPoint) do
            if i == curMaxLevel + 1 and p:getTag() == curMaxLevel + 1 
                and not p:isVisible() then                
                table.insert(allPoint, p)
            elseif p:getTag() <= curMaxLevel and not p:isVisible() then
                p:setVisible(true)
            end
        end

        for _, p in pairs(self.allLPoint) do
            if i == curMaxLevel + 1 and p:getTag() == curMaxLevel + 1 and not p:isVisible() then
                table.insert(allPoint, p)
            elseif p:getTag() <= curMaxLevel and not p:isVisible() then
                p:setVisible(true)
            end
        end
    end
    
    local function tick()
        if #allPoint > 0 then
            print(#allPoint)
            allPoint[1]:setVisible(true)
            local posX, posY = allPoint[1]:getPosition()
            self.iconSpr:setPosition(posX, posY + 50)
            table.remove(allPoint, 1)
        else
            self.iconSpr:setVisible(true)
            cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.schedulerID)
            self.schedulerID = nil
        end        
    end
        
    if #allPoint > 0 then  
        local nodePosx, nodePosy = allPoint[#allPoint]:getPosition()
        local offX = 700 - nodePosx

        self.map:setPositionX(math.max(math.min(350, offX), self.visibleSize.width - 3000))        
        self.schedulerID = cc.Director:getInstance():getScheduler():scheduleScriptFunc(tick, 0.25, false)
    end
    
    self:updateQuick()
    self:updateAward()
end

return UIPVE