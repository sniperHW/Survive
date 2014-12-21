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
    self:createRightBottom()
    self:createLeftBottom()
    self:UpdateTeam()
end

function UIFightLayer:createLeftTop()
    local node = cc.Node:create()
    node:setPosition(0, self.visibleSize.height)    
    self:addChild(node)
    
    self.createSprite("UI/fight/frameL.png", {x = 70, y = -70}, {node})
    self.iconHead = self.createSprite("UI/fight/catF.png", {x = 70, y = -70}, {node})
    self.createLabel("LV", 20, {x = 140, y = -40}, nil, {node})
    self.LblLevel = self.createBMLabel("fonts/LV.fnt", maincha.attr.level, {x = 160, y = -40}, {node, {x = 0, y = 0.5}})
    
    self.LblSelfName = self.createLabel(maincha.nickname, nil, { x = 200, y = -40}, nil, {node, {x = 0, y = 0.5}}) 
    self.createSprite("UI/fight/bloodFrame.png", {x = 110, y = -70}, {node, {x = 0, y = 0.5}})

    self.proBlood = cc.ProgressTimer:create(cc.Sprite:create("UI/fight/blood.png")) 
    self.proBlood:setType(cc.PROGRESS_TIMER_TYPE_BAR)
    self.proBlood:setAnchorPoint(0, 0.5)
    self.proBlood:setPosition(119, -70)
    self.proBlood:setMidpoint({x = 0, y = 0.5})
    self.proBlood:setBarChangeRate({x = 1, y = 0})
    node:addChild(self.proBlood)        
         
    local player = MgrPlayer[maincha.id] or {}
    player.attr = {}
    player.attr.life = 30
    player.attr.maxlife = 30
    self.selfHP = self.createBMLabel("fonts/tili.fnt", player.attr.life.."/"..player.attr.maxlife, {x = 240, y = -70}, {node})
    self.createSprite("UI/fight/bloodTop.png", {x = 105, y = -70}, {node, {x = 0, y = 0.5}})
    
    self:UpdateLife() 
    
    --local beginPosX, posY = 115, -100
    --self.iconMP = {}
    --for i = 1, 15 do
        --self.iconMP[i] = self.createSprite("UI/fight/engeryD.png", {x = 115 + i * 15, y = posY}, {node})
    --end
end

function UIFightLayer:createRightTop()
	local nodeRightTop = cc.Node:create()
    nodeRightTop:setPosition(self.visibleSize.width, self.visibleSize.height)    
    self:addChild(nodeRightTop)
    self.teams = {}
    
    local function onBtnBackTouched(sender, event)
        CMD_LEAVE_MAP()
    end
    
    self.createButton({pos = {x = -80, y = -90},
        icon = "UI/fight/back.png",
        handle = onBtnBackTouched,
        parent = nodeRightTop
    })
    

    for i = 1, 4 do
        local back = self.createSprite("UI/fight/frameS.png", 
            {x = -40 - i * 95, y = -70}, {nodeRightTop})
        local headIcon = self.createSprite("UI/main/head6.png", 
            {x = 40, y = 60}, {back})
        headIcon:setScale(0.8)
        local lblName = self.createLabel("一共七个字", 18, 
            {x = 50, y = 15}, nil, {back})
        local lblLevel = self.createLabel("10", 18, 
            {x = 60, y = 40}, nil, {back})
        self.teams[i] = {back = back, headIcon = headIcon, lblName = lblName,
            lblLevel = lblLevel}
    end
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
                local ac = cc.ProgressFromTo:create(
                    math.max(0, ((skillCD.CDTime + skillCD.lastTime) * 0.001 - nowtime)), 100, 0)
                self.skillCD[i]:runAction(ac)
            end
        end
    end
end

function UIFightLayer:createRightBottom()
    local nodeRightButtom = cc.Node:create()
    nodeRightButtom:setPosition(self.visibleSize.width, 0)
    self:addChild(nodeRightButtom)

    self.createSprite("UI/fight/iconSkill.png", {x = -110, y = 119}, {nodeRightButtom})    
    --self.createSprite("icon/skillIcon/jianqi.png", {x = -68, y = 85}, {nodeRightButtom})

    local function  onBtnUseSKill(sender, event)
    	for key, value in pairs(self.btnSkill) do
    		if value == sender then
    		    local comm = require("common.CommonFun")
                local skillID = MgrSkill.EquipedSkill[key]
                local skillInfo = TableSkill[skillID]
                
                if skillID == 1060 then
                    local localPlayer = MgrPlayer[maincha.id]
                    local selfPosX, selfPosY = localPlayer:getPosition()
                    local targets = {}
                    for id, value in pairs(MgrPlayer) do
                        if value and value.teamid ~= localPlayer.teamid 
                            and value.attr.life > 0 then
                            local tarPosX, tarPosY = value:getPosition()
                            local dis = cc.pGetDistance(cc.p(selfPosX, selfPosY), cc.p(tarPosX, tarPosY))
                            print("distanse:"..dis)
                            if dis < 500 then
                                table.insert(targets, value.id)
                            end                            
                        end
                    end
                    
                    local targetIdx = {math.random(1, #targets), 
                        math.random(1, #targets), 
                        math.random(1, #targets)}
                    
                    --CMD_USESKILL_POINT(skillID, 0, 0, 
                    --    {targets[targetIdx[1]], targets[targetIdx[2]], targets[targetIdx[3]]})
                    local attackIdx = 1
                    local function attack()
                        if #targetIdx > 0 then
                            local idx = targets[targetIdx[1]]
                            table.remove(targetIdx, 1)
                            local player = MgrPlayer[idx]
                            if player then
                                local selfPosX, selfPosY = localPlayer:getPosition()
                                local tarPosX, tarPosY = player:getPosition()
                                local norP = cc.pNormalize(cc.p(tarPosX-selfPosX, tarPosY-selfPosY))
                                local tarP = cc.p(tarPosX - norP.x*50, tarPosY - norP.y*50)
                                local moveAC = cc.MoveTo:create(0.1, tarP)
                                local angle = math.deg(math.atan2(norP.y,norP.x))
                                localPlayer:GetAvatar3D():setRotation3D{x = 0, y = angle+90, z = 0}
                                local acIdx = "Attack"..attackIdx
                                attackIdx = attackIdx + 1
                                local function moveEnd()
                                    localPlayer:GetAvatar3D():stopAllActions()
                                    localPlayer:GetAvatar3D():runAction(cc.Sequence:create(localPlayer.actions[EnumActions[acIdx]],
                                    cc.CallFunc:create(attack))) 
                                end
                                localPlayer:runAction(cc.Sequence:create(moveAC,
                                    cc.CallFunc:create(moveEnd)))
                            end
                        else
                            localPlayer:Idle()
                            localPlayer.playSkillAction = 0
                        end
                    end
            
                    if #targets > 0 then
                        MgrFight.StateFighting = false
                        localPlayer.playSkillAction = 1060
                        attack()
                    end
                                            
                    return
                end
                
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
                if success then
                    self:UpdateCD()
                end
    		end
    	end
    end

    local btnPos = {{x = -178.5, y = 40.5},
    				{x = -181, y = 121},
    				{x = -125.5, y = 188},
    				{x = -41, y = 199},
    				{x = -68, y = 85}}

    self.btnSkill = {}
    self.skillCD = {}
    local skillPerferSize = {width = 68.4, height = 68.4} 
    for i = 1, 5 do
        if MgrSkill.EquipedSkill[i] then
        	self.btnSkill[i] = self.createButton{pos = btnPos[i],
    	        icon = "icon/skillIcon/"..TableSkill[MgrSkill.EquipedSkill[i]].Icon_Path..".png",
    	        handle = onBtnUseSKill,
    	        ignore = false,
    	        parent = nodeRightButtom    
    	    	}
    
            local iconCD = cc.Sprite:create("yuan.png")
            iconCD:setOpacity(100)
            local cdEff = cc.ProgressTimer:create(iconCD)
            cdEff:setType(cc.PROGRESS_TIMER_TYPE_RADIAL)
            cdEff:setMidpoint({x = 0.5, y = 0.5})
            cdEff:setPosition(btnPos[i])
            cdEff:setPercentage(0)
            
            self.skillCD[i] = cdEff
            nodeRightButtom:addChild(cdEff)
            if i < 5 then
    	       self.btnSkill[i]:setScale(0.57)
               cdEff:setScale(0.57)
            end
    	    self.btnSkill[i]:setZoomOnTouchDown(false)
        end
    end
end

function UIFightLayer:UpdateLife()
    local player = MgrPlayer[maincha.id]
    self.proBlood:setPercentage((player.attr.life/player.attr.maxlife)*100)
    self.selfHP:setString(player.attr.life.."/"..player.attr.maxlife)
end

function UIFightLayer:createLeftBottom()
    local nodeLeftBottom = cc.Node:create()
    self:addChild(nodeLeftBottom)
    self.useItem = {}
    self.createSprite("UI/fight/hk.png", {x = 0, y = 0}, {nodeLeftBottom, {x = 0, y = 0}})
    
    for i = 1, 6 do
        local btn = self.createButton{pos = {x = 105 * i - 40, y = 55},
            icon = "UI/fight/djk.png",
            handle = nil,
            ignore = false,
            parent = nodeLeftBottom
            }
        btn:setZoomOnTouchDown(false)
        local itemIcon = self.createSprite("icon/itemIcon/beixin.png", 
            {x = 105 * i - 40, y = 55}, {nodeLeftBottom})   
        itemIcon:setScale(0.7)  
        local lblNum = self.createBMLabel(
            "fonts/exp.fnt", 0, {x = 105 * i - 10, y = 30}, {nodeLeftBottom})
        self.useItem[i] = {btnBack = btn, icon = itemIcon, lblNum = lblNum}
    end  
    self:UpdateLeftBottom()
end

function UIFightLayer:UpdateLeftBottom()
    for i = 1, 6 do
        local item = maincha.equip[i+4]
        if item then
            local itemid = item.id
            self.useItem[i].icon:setVisible(true)
            self.useItem[i].lblNum:setVisible(true)
            self.useItem[i].lblNum:setString(item.count)
            local itemInfo = TableItem[itemid]
            local iconPath = "icon/itemIcon/"..itemInfo.Icon..".png"
            self.useItem[i].icon:setTexture(iconPath)
        else
            self.useItem[i].icon:setVisible(false)
            self.useItem[i].lblNum:setVisible(false)
        end          
    end
end

return UIFightLayer