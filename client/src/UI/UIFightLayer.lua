local Pseudo = require "src.pseudoserver.pseudoserver"
local comm = require "common.CommonFun"

local UIFightLayer = class("UIFightLayer", function()
    return require("UI.UIBaseLayer").create()
end)

function UIFightLayer.create()
    local layer = UIFightLayer.new()
    return layer
end

function UIFightLayer:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
    self.schedulerID = nil

    self:createLeftTop()
    self:createRightTop()
    self:CreateJoyStick()
    self:createSkillNode()
    self:createItems()
    self:UpdateTeam()
    self:UpdateSkillNode()
        
    local scene = cc.Director:getInstance():getRunningScene()        
    local function onNodeEvent(event)
        if "enter" == event then
            self:UpdateAnger()
            if MgrFight.FivePVERound == 1 then
                self:onFivePVERound()
            end
            if MgrFight.EnterMapTime ~= 0 then
                self:showRemainTime()
            end        

            local scene = self:getScene()
            if scene:getTag() == 206 then
                self:createCurMap()
            end
        elseif "exit" == event then
            if scene:getTag() == 202 then 
                UsePseudo = false
            end  
            
            local sch = cc.Director:getInstance():getScheduler()          
            if self.schedulerID then
                sch:unscheduleScriptEntry(self.schedulerID)
            end
            if self.schedulerBoomID then
                sch:unscheduleScriptEntry(self.schedulerBoomID)
            end
            
            if self.moveSchID then
                sch:unscheduleScriptEntry(self.moveSchID)
            end
            
            if self.mapIdxTick then
                sch:unscheduleScriptEntry(self.mapIdxTick)
            end
        end
    end
    self:registerScriptHandler(onNodeEvent)
end

function UIFightLayer:createLeftTop()
    local node = cc.Node:create()
    node:setPosition(0, self.visibleSize.height)    
    self:addChild(node)
    self.teams = {}
    
    local headPath = string.format("UI/main/head%d.png",maincha.avatarid)
    self.createSprite("UI/fight/juese.png", {x = 50, y = -50}, {node})
    self.iconHead = self.createSprite(headPath, {x = 50, y = -50}, {node})
    self.iconHead:setScale(0.7)
    self.createSprite("UI/fight/dengjiback.png", {x = 20, y = -15}, {node})
    self.LblLevel = self.createLabel(maincha.attr.level, nil, 
        cc.p(20, -15), nil, {node})
    self.LblLevel:setColor({r = 255, g = 255, b = 0}) 
    
    self.LblSelfName = self.createLabel(maincha.nickname, nil, 
        {x = 105, y = -25}, nil, {node, {x = 0, y = 0.5}}) 
    self.LblSelfName:enableOutline({r = 46, g = 28, b = 93}, 2)
    
    self.createSprite("UI/fight/bloodFrame.png", 
        {x = 100, y = -50}, {node, {x = 0, y = 0.5}})
    local blood = cc.Sprite:create("UI/fight/blood.png")
    self.proBlood = cc.ProgressTimer:create(blood) 
    self.proBlood:setType(cc.PROGRESS_TIMER_TYPE_BAR)
    self.proBlood:setAnchorPoint(0, 0.5)
    self.proBlood:setPosition(99, -50)
    self.proBlood:setMidpoint({x = 0, y = 0.5})
    self.proBlood:setBarChangeRate({x = 1, y = 0})
    node:addChild(self.proBlood)        
    self.proBlood:setPercentage(60)

    local player = MgrPlayer[maincha.id]
    player = player or {attr = {life = 0, maxlife = 0}}
    
    self.selfHP = self.createBMLabel("fonts/tili.fnt", 
        --(player.attr.life or 0).."/"..(player.attr.maxlife or 0), 
        "10/100", {x = 200, y = -50}, {node})
    self.selfHP:setScale(0.8)
--[[        
    self.createSprite("UI/fight/bloodTop.png", {x = 105, y = -70}, 
        {node, {x = 0, y = 0.5}})
]]
    self:UpdateLife()
    
    local beginPosX, posY = 95, -75
    self.iconMP = {}
    for i = 1, 15 do
        local icon = self.createSprite("UI/fight/engeryD.png", 
            {x = beginPosX + i * 13, y = posY}, {node})
        icon:setScale(0.8)
        self.iconMP[i] = self.createSprite("UI/fight/engry.png", 
            {x = 6, y = 13}, {icon})
    end
    
    for i = 1, 4 do
        local back = self.createSprite("UI/fight/juese.png", 
            {x = 46, y = - 60 - 78 * i}, {node})
        back:setScale(0.75)
        local headIcon = self.createSprite("UI/main/head1.png", 
            {x = 40, y = 40}, {back})
        headIcon:setScale(0.7)
        local lblName = self.createLabel("一共七个字", 18, 
            {x = 40, y = 80}, nil, {back})
        lblName:setColor({r = 204, g = 231, b = 255})
        lblName:enableOutline({r = 1, g = 3, b = 38}, 2)
        
        self.createSprite("UI/fight/dengjiback.png", {x = 10, y = 15}, {back})
        local lblLevel = self.createLabel("10", 18, 
            {x = 5, y = 15}, nil, {back})
            
        local spr = self.createSprite("UI/fight/bloodFrame.png", 
            {x = 0, y = -8}, {back, {x = 0, y = 0.5}})
        spr:setScaleX(0.4)
        spr:setScaleY(0.7)
        local blood = cc.Sprite:create("UI/fight/blood.png")
        local proBlood = cc.ProgressTimer:create(blood) 
        proBlood:setScaleX(0.4)
        proBlood:setScaleY(0.7)
        proBlood:setType(cc.PROGRESS_TIMER_TYPE_BAR)
        proBlood:setAnchorPoint(0, 0.5)
        proBlood:setPosition(0, -8)
        proBlood:setMidpoint({x = 0, y = 0.5})
        proBlood:setBarChangeRate({x = 1, y = 0})
        back:addChild(proBlood)        
        proBlood:setPercentage(80)
            
        self.teams[i] = {back = back, headIcon = headIcon, lblName = lblName,
            lblLevel = lblLevel, blood = proBlood}
    end
    

    local function onSwitchTouched(...)
        MgrSetting.bJoyStickType = not MgrSetting.bJoyStickType
        self:UpdateSkillNode()
        
        if not MgrSetting.bJoyStickType then
            self.btnSwitch:setBackgroundSpriteForState(
                ccui.Scale9Sprite:create("UI/fight/ygaoganmoshi.png"), 
                    cc.CONTROL_STATE_NORMAL)
        else
            self.btnSwitch:setBackgroundSpriteForState(
                ccui.Scale9Sprite:create("UI/fight/dianjimoshi.png"), 
                cc.CONTROL_STATE_NORMAL)
        end
    end
    
    local icon = nil
    
    if not MgrSetting.bJoyStickType then
        icon = "UI/fight/ygaoganmoshi.png"
    else
        icon = "UI/fight/dianjimoshi.png"
    end

    self.btnSwitch = self.createButton{
        ignore = false, 
        pos = {x = 340, y = -55},
        icon = icon,
        handle = onSwitchTouched,
        parent = node}
end

function UIFightLayer:UpdateAnger()
    for i = 1, 15 do
        self.iconMP[i]:setVisible(i <= MgrFight.anger)
    end
end

function UIFightLayer:createCurMap()
    local lbl = self.createLabel("当前地图：A-3", nil, 
        cc.p(self.visibleSize.width/2, self.visibleSize.height-15), nil, {self})
    self.lblMapIdx = lbl
    lbl:enableOutline({r = 0, g = 15, b = 64}, 2)
    
    local player = self:getScene().localPlayer
    
    local function tick()
        local px, py = player:getPosition()

        local cellMapX = math.floor(px/1464)
        local cellMapY = math.floor(py/824)
        local str = string.format("当前地图：%c-%d", cellMapX + 65, 3-cellMapY)
        lbl:setString(str)
    end
    
    local sch = cc.Director:getInstance():getScheduler()
    self.mapIdxTick = sch:scheduleScriptFunc(tick, 1, false)
end

function UIFightLayer:createRightTop()
	local nodeRightTop = cc.Node:create()
    nodeRightTop:setPosition(self.visibleSize.width, self.visibleSize.height)    
    self:addChild(nodeRightTop)
    self.nodeRightTop = nodeRightTop
    
    local function onBtnBackTouched(sender, event)
        local scene = cc.Director:getInstance():getRunningScene()
        
        if scene:getTag() ~= 202 then
            CMD_LEAVE_MAP()
        else
            Pseudo.DestroyMap() 
            scene.hud:closeUI("UIPVEResult")
            scene.hud:openUI("UIPVE")
            scene.localPlayer = nil
            MgrPlayer[maincha.id] = nil
            scene.stars = {}
            scene.map:removeAllChildren()
        end
    end
    
    self.createButton({pos = {x = -80, y = -90},
        icon = "UI/fight/fanhui.png",
        handle = onBtnBackTouched,
        parent = nodeRightTop
    })
end

function UIFightLayer:UpdateTeam()
    local localPlayer = MgrPlayer[maincha.id]
    if not localPlayer then return end
    local teamIds = {}
    for key, player in pairs(MgrPlayer) do
        if player.id ~= maincha.id and 
            player.teamid == localPlayer.teamid then
            table.insert(teamIds, player.id)
        end 
    end

    for i=1,4 do
        if i <= #teamIds then
            local player = MgrPlayer[teamIds[i]]
            self.teams[i].back:setVisible(true)
            local headPath = string.format("UI/main/head%d.png", player.avatid)
            self.teams[i].headIcon:setTexture(headPath)
            self.teams[i].lblName:setString(player.name)
            self.teams[i].lblLevel:setString(player.attr.level)
            local life = player.attr.life/player.attr.maxlife*100
            self.teams[i].blood:setPercentage(life)
        else
            self.teams[i].back:setVisible(false)
        end
    end
end

function UIFightLayer:UpdateCD()
    local nowtime = os.clock()
    print("-----------Update CD------------------")
    for i = 1, 5 do
        local skillID = MgrSkill.EquipedSkill[i]
        if skillID ~= nil then
            local skillCD = MgrSkill.SkillCD[skillID]
            if skillCD ~= nil then
                local esPer = math.min(100, (100 - (nowtime * 1000- skillCD.lastTime)/skillCD.CDTime * 100))
                local ac = cc.ProgressFromTo:create(
                    math.max(0, ((skillCD.CDTime + skillCD.lastTime) * 0.001 - nowtime)), esPer, 0)
                ac:setTag(100)
                self.skillCD[i]:stopActionByTag(100)
                self.skillCD[i]:runAction(ac)
            end
        end
    end
end

function UIFightLayer:createSkillNode()
    MgrSkill.SkillCD = {}
    MgrSkill.EquipedSkill = {}
    if not MgrFight.weapon then
        return
    end
    
    local nodeRightButtom = cc.Node:create()
    nodeRightButtom:setPosition(self.visibleSize.width, 0)
    self:addChild(nodeRightButtom)
    self.nodeRightButtom = nodeRightButtom

    --self.createSprite("UI/fight/iconSkill.png", {x = -110, y = 119}, {nodeRightButtom})    
    --self.createSprite("icon/skillIcon/jianqi.png", {x = -68, y = 85}, {nodeRightButtom})

    local function useSkill(skillID)
        local skillInfo = TableSkill[skillID]

        local localPlayer = MgrPlayer[maincha.id]
        local selfPosX, selfPosY = localPlayer:getPosition()
        local selfPos = {x = selfPosX, y = selfPosY}
        local dir, targets = nil, nil
        if skillInfo.Attack_Types == 2 then
            dir, targets = comm.getDirSkillTargets(skillID)
        elseif skillInfo.Attack_Types == 1 then
            targets = comm.getAOESkillTargets(skillID)
        end

        local success = MgrSkill.UseSkill(skillID, selfPos, dir, targets)
        if success and skillID % 10 == 0 then
            self:UpdateCD()            
            if skillID == 1020 or skillID == 1010 or
               skillID == 1060 or skillID == 1110 or 
               skillID == 1130 then
                local scene = cc.Director:getInstance():getRunningScene()
                local mapPosX, mapPoxY = scene.map:getPosition()
                local effPosX = 0
                local effPosY = 0
                
                if math.abs(mapPosX) > 20 then
                    effPosX = 20
                else
                    mapPosX = -20
                end 
                
                local ac1 = cc.MoveBy:create(0.05,{x = effPosX, y = effPosY})
                local ac2 = cc.MoveBy:create(0.05,{x = -effPosX, y = -effPosY})
                local ac3 = cc.MoveBy:create(0.05,{x = effPosX, y = effPosY})
                local ac4 = cc.MoveBy:create(0.05,{x = -effPosX, y = -effPosY})
                
                local function onEnd()
                    scene.moveAction = scene.moveAction - 1
                end
                
                scene.moveAction = scene.moveAction + 1
                local delay = 0.5
                if skillID == 1020 then
                    delay = 1
                elseif skillID == 1110 then
                    delay = 1.5
                end
                local ac = cc.Sequence:create(cc.DelayTime:create(delay), ac1, ac2, ac3, ac4, cc.CallFunc:create(onEnd))
                scene.map:runAction(ac)
            end
        end
    end
    
    local lastBaseSkillIdx = 0
    local function onBtnUseSKill(sender, event)
    	if sender == self.btnBaseSkill then
    	   if MgrSkill.CanUseSkill(MgrSkill.BaseSkill[1]) then
        	   if lastBaseSkillIdx == #MgrSkill.BaseSkill then
        	       lastBaseSkillIdx = 1
               else
                    lastBaseSkillIdx = lastBaseSkillIdx + 1
        	   end
        	   local skillID = MgrSkill.BaseSkill[lastBaseSkillIdx] 
        	   useSkill(skillID)
           end
    	   return 
    	end
    	
    	for key, value in pairs(self.btnSkill) do
    		if value == sender then
                local skillID = MgrSkill.EquipedSkill[key]
                useSkill(skillID)
   		   end
    	end
    	
    end

    local btnPos = {{x = -60, y = 60},
    				{x = -150, y = 60},
    				{x = -60, y = 150},
    				{x = -150, y = 150},
    				{x = -60, y = 240}}

    self.btnSkill = {}
    self.skillCD = {}
    self.iconMask = {}
    local skillPerferSize = {width = 68.4, height = 68.4} 

    local weaponid = MgrFight.weapon.id
    local curTime = os.clock() * 1000
    local equipedSkill = {}
    if weaponid > 5000 and weaponid < 5100 then
        equipedSkill  = {1010, 1020, 1030, 1050, 1060}
        MgrSkill.BaseSkill = {11, 12, 13}
        MgrSkill.SkillCD[11] = {lastTime = curTime, CDTime = 0}
    elseif weaponid > 5100 and weaponid < 5200 then
        equipedSkill = {1110, 1120, 1130, 1140, 1150}
        MgrSkill.BaseSkill = {1511, 1512}
        MgrSkill.SkillCD[1511] = {lastTime = curTime, CDTime = 0}
    elseif weaponid > 5200 and weaponid < 5300 then
        equipedSkill = {1210, 1220, 1230, 1240, 1250}
        MgrSkill.BaseSkill = {21}
        MgrSkill.SkillCD[20] = {lastTime = curTime, CDTime = 0}
    end
    
    local iconBaseSkill = {
        "UI/skill/0DJ.png",
        "UI/skill/0GB.png",
        "UI/skill/0QX.png",
    }
    
    if MgrSkill.BaseSkill[1] == 11 then
        iconBaseSkill = "UI/skill/0DJ.png"
    elseif MgrSkill.BaseSkill[1] == 1511 then
        iconBaseSkill = "UI/skill/0GB.png"
    elseif MgrSkill.BaseSkill[1] == 21 then
        iconBaseSkill = "UI/skill/0QX.png"
    end
    
    self.btnBaseSkill = self.createButton{pos = cc.p(-80, 80),
        icon = "UI/fight/putonggongji.png",
        handle = onBtnUseSKill,
        ignore = false,
        parent = nodeRightButtom    
    }
    self.btnBaseSkill:setBackgroundSpriteForState(
                ccui.Scale9Sprite:create("UI/fight/putonggongji2.png"), 
                cc.CONTROL_STATE_HIGH_LIGHTED)
    self.btnBaseSkill:setZoomOnTouchDown(false)
    
    for i = 1, #equipedSkill do
        if maincha.skill[equipedSkill[i]] then
            table.insert(MgrSkill.EquipedSkill, equipedSkill[i]) 
            local cd = {}
            cd.lastTime = curTime
            cd.CDTime = 0
            MgrSkill.SkillCD[equipedSkill[i]] = cd
        end
    end
    
    for i = 1, #MgrSkill.EquipedSkill do
        if MgrSkill.EquipedSkill[i] then
            local skillInfo = TableSkill[MgrSkill.EquipedSkill[i]]
            local path = "icon/skillIcon/"..skillInfo.Icon_Path..".png"
            self.btnSkill[i] = self.createButton{pos = btnPos[i],
                icon = path,
                handle = onBtnUseSKill,
    	        ignore = false,
    	        parent = nodeRightButtom    
    	    	}
    	    	
            self.iconMask[i] = self.createSprite("UI/fight/jineng.png", 
            btnPos[i], {nodeRightButtom})
    
            local iconCD = cc.Sprite:create("yuan.png")
            iconCD:setOpacity(200)
            local cdEff = cc.ProgressTimer:create(iconCD)
            cdEff:setType(cc.PROGRESS_TIMER_TYPE_RADIAL)
            cdEff:setMidpoint({x = 0.5, y = 0.5})
            cdEff:setPosition(btnPos[i])
            cdEff:setPercentage(0)
            
            self.skillCD[i] = cdEff
            nodeRightButtom:addChild(cdEff)
            self.btnSkill[i]:setScale(0.6)
            cdEff:setScale(0.6)
    	    self.btnSkill[i]:setZoomOnTouchDown(false)
        end
    end
    self:UpdateSkillNode()
end

function UIFightLayer:UpdateSkillNode()
    local btnPos = nil
        
    if MgrSetting.bJoyStickType then
        self.nodeJoyStick:setVisible(true)
        if self.btnBaseSkill then
            self.btnBaseSkill:setVisible(true)
        end
        btnPos = {{x = -50, y = 200},
            {x = -140, y = 190},
            {x = -200, y = 130},
            {x = -220, y = 45},
            {x = -310, y = 45}}
    else
        btnPos = {{x = -60, y = 60},
            {x = -150, y = 60},
            {x = -60, y = 150},
            {x = -150, y = 150},
            {x = -60, y = 240}}
        self.nodeJoyStick:setVisible(false)
        if self.btnBaseSkill then
            self.btnBaseSkill:setVisible(false)
        end
    end
    
            
    if not MgrFight.weapon then
        return
    end
    
    for i = 1, #MgrSkill.EquipedSkill do
        self.btnSkill[i]:setPosition(btnPos[i])
        self.skillCD[i]:setPosition(btnPos[i])
        self.iconMask[i]:setPosition(btnPos[i])
    end
end

function UIFightLayer:RecreateSkill()
    if self.nodeRightButtom then
        self.nodeRightButtom:removeFromParent()
    end
    self:createSkillNode()
end

function UIFightLayer:createGuideSkill()
    self.nodeRightButtom:setVisible(true)
    local hud = cc.Director:getInstance():getRunningScene().hud
    self.nodeRightButtom:setVisible(true)
    hud:closeUI("UIGuide")
    local ui = hud:openUI("UIGuide")

    ui:createWidgetGuide(self.btnSkill[1], "UI/fight/fightquan.png", true)
end

function UIFightLayer:createGuideUseItem()
    local hud = cc.Director:getInstance():getRunningScene().hud
    hud:closeUI("UIGuide")
    self.nodeLeftBottom:setVisible(true)
    local ui = hud:openUI("UIGuide")
    
    ui:createWidgetGuide(self.useItem[1].icon, "UI/fight/daoju.png", true, 
        "受伤了,请点击使用道具", 
        {x = self.visibleSize.width - 120, y = 220})
end

function UIFightLayer:createGuideJoyStick()
    --[[if self.guideJoyStick then
        return
    end
    self.guideJoyStick = true
    self.btnSwitch:setVisible(true)
    local hud = cc.Director:getInstance():getRunningScene().hud
    hud:closeUI("UIGuide")
    local ui = hud:openUI("UIGuide")

    ui:createWidgetGuide(self.btnSwitch, "UI/fight/ygaoganmoshi.png", true)]]--
end

function UIFightLayer:createGuideRocker()
    --[[if self.guideRocker then
        return
    end
    self.guideRocker = true
    
    self.nodeJoyStick:setVisible(true)
    local hud = cc.Director:getInstance():getRunningScene().hud
    hud:closeUI("UIGuide")
    local ui = hud:openUI("UIGuide")

    ui:createClipNode(self.plate, "操控摇杆行走", {x = 150, y = 300})]]--
end

function UIFightLayer:createGuideBaseSkill()
    --[[if self.guideBaseSkill then
        return
    end
    self.guideBaseSkill = true

    self.nodeRightButtom:setVisible(true)
    local hud = cc.Director:getInstance():getRunningScene().hud
    hud:closeUI("UIGuide")
    local ui = hud:openUI("UIGuide")
    
    local posX, posY = self.btnBaseSkill:getPosition()
    local pos = self.btnBaseSkill:getParent():convertToWorldSpace({x = posX, y = posY})
    ui:createWidgetGuide(self.btnBaseSkill, "UI/fight/putonggongji.png", true, 
        "点击按钮击杀怪物", pos)]]--
end

function UIFightLayer:UpdateLife()
    local player = MgrPlayer[maincha.id]
    if player and player.attr then
        self.proBlood:setPercentage((player.attr.life/player.attr.maxlife)*100)
        self.selfHP:setString(player.attr.life.."/"..player.attr.maxlife)
    end
end

local MgrUseItemCD = {}

function UIFightLayer:createItems()
    local nodeItems = cc.Node:create()
    self:addChild(nodeItems)
    self.nodeLeftBottom = nodeItems
    --nodeItems:setVisible(false)
    self.useItem = {}
    --[[
    self.createSprite("UI/fight/hk.png", {x = 0, y = 0}, 
        {nodeItems, {x = 0, y = 0}})
    ]]
    local function onUseItemTouched(sender, event)
        local bagPos = sender:getTag()
        local item = MgrFight.battleitems[bagPos]
        if item and item.count > 0 then
            local skillID = TableItem[item.id].Skill_Using
            local skillInfo = TableSkill[skillID]
            
            local curtime = os.clock() * 1000
            if curtime < MgrUseItemCD[item.id] then
                return                        
            end
            
            MgrUseItemCD[item.id] = curtime + skillInfo.Skill_CD
            local ac = cc.ProgressFromTo:create(
                math.max(0, skillInfo.Skill_CD/1000), 100, 0)
            
            self.useItem[bagPos-4].cdEff:runAction(ac)            
            
            if skillInfo then                    
                item.count = item.count - 1     
                self.useItem[bagPos-4].lblNum:setString(item.count)          
                if skillInfo.Attack_Types == 3 then --target self
                    CMD_USESKILL(skillID, maincha.id) 
                elseif skillInfo.Attack_Types == 1 then
                    local targets = comm.getAOESkillTargets(skillID)
                    local localPlayer = MgrPlayer[maincha.id]
                    local selfPosX, selfPosY = localPlayer:getPosition()
                    CMD_USESKILL_POINT(skillID, selfPosX, selfPosY, targets)
                end
            end
        end 
    end
    
    for i = 1, 6 do
        local btnIconPath = "UI/fight/daoju.png"
        --[[
        if i <= 3 then
            btnIconPath = "UI/fight/djk.png"
        else
            btnIconPath = "UI/fight/vip.png"
        end
        ]]
        
        local btnPosX = self.visibleSize.width - 50 - math.floor((i-1)/3) * 80
        local pos = {x = btnPosX, y = ((i-1)%3) * 80 + 300}
        local btn = self.createButton{pos = pos,
            icon = btnIconPath,
            handle = onUseItemTouched,
            ignore = false,
            parent = nodeItems
            }
        btn:setTag(i+4)
        btn:setZoomOnTouchDown(false)
        local itemIcon = self.createSprite("icon/itemIcon/beixin.png", 
            pos, {nodeItems})   
        itemIcon:setScale(0.45)  
        local lblNum = self.createBMLabel(
            "fonts/exp.fnt", 0, cc.pSub(pos,cc.p(0, 20)), {nodeItems})
            
        local iconCD = cc.Sprite:create("heikuang.png")
        iconCD:setOpacity(180)
        local cdEff = cc.ProgressTimer:create(iconCD)
        cdEff:setType(cc.PROGRESS_TIMER_TYPE_RADIAL)
        cdEff:setMidpoint({x = 0.5, y = 0.5})
        cdEff:setPosition(pos)
        cdEff:setPercentage(0)

        nodeItems:addChild(cdEff)
        cdEff:setScale(0.45)            

        self.useItem[i] = {btnBack = btn, icon = itemIcon, 
            lblNum = lblNum, cdEff = cdEff}
    end  
    self:UpdateLeftBottom()
end

function UIFightLayer:UpdateLeftBottom()
    local curtime = os.clock() * 1000
    for i = 1, 6 do
        local item = nil
        if MgrFight.battleitems then
            item = MgrFight.battleitems[i+4]
        end
        if item and item.id ~= 0 and item.count > 0 then
            local itemid = item.id
            self.useItem[i].icon:setVisible(true)
            self.useItem[i].lblNum:setVisible(true)
            self.useItem[i].cdEff:setVisible(true)
            self.useItem[i].lblNum:setString(item.count)
            local itemInfo = TableItem[itemid]
            local iconPath = "icon/itemIcon/"..itemInfo.Icon..".png"
            self.useItem[i].icon:setTexture(iconPath)
            MgrUseItemCD[itemid] = MgrUseItemCD[itemid] or curtime 
        else
            self.useItem[i].icon:setVisible(false)
            self.useItem[i].lblNum:setVisible(false)
            self.useItem[i].cdEff:setVisible(false)
        end          
    end
end

function UIFightLayer:CreateJoyStick()
    local nodeJoyStick = cc.Node:create()
    self:addChild(nodeJoyStick)
    self.nodeJoyStick = nodeJoyStick

    local plate = self.createSprite("rocker/plate.png",  
        {x = 150, y = 150}, {nodeJoyStick})
    local stick = self.createSprite("rocker/stick.png",
        {x = 150, y = 150}, {nodeJoyStick})
    self.plate = plate
    local beginPos = cc.p(0, 0)
    local stickDirVec = {x = 0, y = 0}
    local stickDir = 0
    local totalDetal = 0
    local function moveTick(detal)
        local scene = self:getScene()
        if not scene or not scene.localPlayer or not nodeJoyStick:isVisible() then
            return
        end
        
        local player = scene.localPlayer
        if player.playSkillAction ~= 0 or player.attr.life <= 0 then
            return
        end        
        
        local posX, posY = player:getPosition()
        local offPos = cc.pMul(stickDirVec, detal * 27 * 8)
        local tarPos = cc.pAdd(cc.p(posX, posY), offPos)
        
        local tilePos = cc.WalkTo:map2TilePos(tarPos)
        local bCollision = CheckCollision(tilePos.x, tilePos.y)
        if (bCollision == 0) then
            player:setPosition(tarPos)    
            if not player.buffState[3001] then
                local avatar = player:GetAvatar3D()
                local playerDir = avatar:getRotation3D()
                local dir = {x = playerDir.x, y = stickDir+90, z = playerDir.z}
                avatar:setRotation3D(dir)
            end
            
            totalDetal = totalDetal + detal
            if totalDetal > 0.25 then
                CMD_MOV(tilePos)
                totalDetal = 0
            end    
        end    
    end
    
    local scheduler = cc.Director:getInstance():getScheduler()
    local function onTouchBegan(touch, event)
        local location = touch:getLocation()
        local player = self:getScene().localPlayer
        if cc.pGetLength(location) < 320 
            and player.attr.life > 0 
            and self.nodeJoyStick:isVisible() then --320 * 320
            plate:setPosition(location)
            stick:setPosition(location)
            beginPos = location
            
            player:Walk()
            self.moveSchID = scheduler:scheduleScriptFunc(moveTick, 0, false)
            MgrControl.bTouchJoyStick = true            
            return true
        end 
        return false
    end

    local function onTouchMoved(touch, event)
        local location = touch:getLocation()
        local dirVec = cc.pSub(location, beginPos)
        local dir = math.deg(cc.pToAngleSelf(dirVec))
        if dir < 0 then
            dir = dir + 360
        end
                
        local pos = location
        local norDir = cc.pNormalize(dirVec)
        stickDir = dir
        stickDirVec = norDir
        if cc.pGetDistance(beginPos, location) > 100 then    
            pos = cc.pAdd(beginPos, cc.p(norDir.x * 100, norDir.y * 100))
        end
        stick:setPosition(pos)
    end
    
    local function onTouchEnded(touch, event)
        local pos = cc.p(150, 150)
        plate:setPosition(pos)
        stick:setPosition(pos)
        scheduler:unscheduleScriptEntry(self.moveSchID)
        self.moveSchID = nil
        MgrControl.bTouchJoyStick = false
        local player = self:getScene().localPlayer
        player:Idle()
    end

    local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
    listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
    listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
    listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_CANCELLED )    
    local dispatcher = self:getEventDispatcher()
    dispatcher:addEventListenerWithSceneGraphPriority(listener, nodeJoyStick)
end 

function UIFightLayer:onFivePVERound()
    local size = self.visibleSize
    local pos = cc.p(size.width/2, size.height/2+100)

    local layer = cc.LayerColor:create({r = 0, g = 0, b = 0, a = 100})
    layer:setLocalZOrder(65535)
    self:getScene():addChild(layer)    
    
    --[[
    local spr = cc.Sprite:create("UI/pve/dijiguan.png") 
    spr:setPosition(size.width/2 - 231, size.height/2+100)
    spr:runAction(cc.MoveBy:create(2, {x = 231, y = 0}))
    spr:setPosition(pos)
    local clipNode = cc.ClippingNode:create(spr)
    layer:addChild(clipNode)
    ]]
    self.createSprite("UI/pve/dijiguan.png",
        pos, {layer})        
    
    local lbl = self.createBMLabel("fonts/dijiguan.fnt", 
        "第"..MgrFight.FivePVERound.."关", pos, {layer})
    --MgrFight.FivePVERound, pos, {scene})
    --spr:setLocalZOrder(65535)
    layer:runAction(cc.Sequence:create(cc.DelayTime:create(2), 
        cc.RemoveSelf:create()))
end

function UIFightLayer:showRemainTime()
    local size = self.visibleSize
    local pos = cc.p(size.width/2, size.height/2+100)
    local remainTime = math.floor(os.clock() - MgrFight.EnterMapTime)
    if remainTime <= 10 then
        MgrFight.CanUseSkill = false
        local spr = self.createSprite("UI/pve/daojishi.png", 
            pos, {self:getScene()})
        local lbl = self.createBMLabel("fonts/daojishi.fnt", 
            10 - remainTime, pos, {self:getScene()})
        spr:setLocalZOrder(65534)
        lbl:setLocalZOrder(65535)
        
        --[[
        local function onTouchBegan(touch, event)
            return true
        end

        local listener = cc.EventListenerTouchOneByOne:create()
        listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN)
        listener:setSwallowTouches(true)
        local eventDispatcher = self:getEventDispatcher()
        eventDispatcher:addEventListenerWithSceneGraphPriority(listener, lbl)
        ]]
        local function tick()
            remainTime = math.floor(os.clock() - MgrFight.EnterMapTime)
            if remainTime >= 10 then
                local sch = cc.Director:getInstance():getScheduler()
                sch:unscheduleScriptEntry(self.schedulerID)
                self.schedulerID = nil
                lbl:removeFromParent()
                spr:removeFromParent()
                MgrFight.CanUseSkill = true
            else
                lbl:setString(10 - remainTime)
            end
        end
        
        local sch = cc.Director:getInstance():getScheduler()
        self.schedulerID = sch:scheduleScriptFunc(tick, 1, false)
    end
end

function UIFightLayer:onBagUpdate()
    self:UpdateLeftBottom()
end

function UIFightLayer:onMapBoom(mapIdx, boomTime)
    local scene = self:getScene()
    local map = scene.map
    local player = scene.localPlayer 
    local posX, posY = player:getPosition()
    local idxX = math.ceil(posX/1440)
    local idxY = 3 - math.ceil(posY/960)
    local selfMapIdx = idxY * 4 + idxX
    if mapIdx == selfMapIdx then
        local remainTime = 
            (boomTime-BeginTime.servertime) - (os.clock()-BeginTime.localtime)
        remainTime = math.floor(remainTime)
        
        if remainTime < 1 then
            local ac1 = cc.ScaleTo:create(0.06,1.3)
            local ac2 = cc.ScaleTo:create(0.06,1.0)
            local shake = cc.Sequence:create(ac1, ac2)
            scene.map:runAction(cc.Repeat:create(shake, 2))
        end
        
        if remainTime > 1 then
            local size = self.visibleSize
            local pos = cc.p(size.width/2, size.height/2+100)
            local spr = self.createSprite("UI/pve/daojishi.png", pos, {scene})
            local lbl = self.createBMLabel("fonts/daojishi.fnt", 
                remainTime, pos, {self:getScene()})
            spr:setLocalZOrder(65534)
            lbl:setLocalZOrder(65535)
            
            local function tick()
                remainTime = math.floor(remainTime - 1)
                if remainTime <= 0 then
                    local sch = cc.Director:getInstance():getScheduler()
                    sch:unscheduleScriptEntry(self.schedulerBoomID)
                    self.schedulerBoomID = nil
                    lbl:removeFromParent()
                    spr:removeFromParent()
                else
                    lbl:setString(remainTime)
                end
            end

            local sch = cc.Director:getInstance():getScheduler()
            self.schedulerBoomID = sch:scheduleScriptFunc(tick, 1, false)            
        end
    end
end 

return UIFightLayer