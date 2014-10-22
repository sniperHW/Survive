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
end

function UIFightLayer:createLeftTop()
    local node = cc.Node:create()
    node:setPosition(0, self.visibleSize.height)    
    self:addChild(node)
    
    self.createSprite("UI/fight/frameL.png", {x = 70, y = -70}, {node})
    self.iconHead = self.createSprite("UI/fight/catF.png", {x = 70, y = -70}, {node})
    self.createLabel("LV", 20, {x = 140, y = -40}, nil, {node})
    self.LblLevel = self.createBMLabel("fonts/LV.fnt", "56", {x = 160, y = -40}, {node, {x = 0, y = 0.5}})
    
    self.LblSelfName = self.createLabel("sdsdafdsa", nil, { x = 200, y = -40}, nil, {node, {x = 0, y = 0.5}}) 
    self.createSprite("UI/fight/bloodFrame.png", {x = 110, y = -70}, {node, {x = 0, y = 0.5}})

    self.proBlood = cc.ProgressTimer:create(cc.Sprite:create("UI/fight/blood.png")) 
    self.proBlood:setType(cc.PROGRESS_TIMER_TYPE_BAR)
    self.proBlood:setAnchorPoint(0, 0.5)
    self.proBlood:setPosition(119, -70)
    self.proBlood:setMidpoint({x = 0, y = 0.5})
    self.proBlood:setBarChangeRate({x = 1, y = 0})
    self.proBlood:setPercentage(100)
    node:addChild(self.proBlood)        
    
    self.selfMP = self.createBMLabel("fonts/tili.fnt", "56000/65000", {x = 240, y = -70}, {node})
    self.createSprite("UI/fight/bloodTop.png", {x = 105, y = -70}, {node, {x = 0, y = 0.5}})
    
    local beginPosX, posY = 115, -100
    self.iconMP = {}
    for i = 1, 15 do
        self.iconMP[i] = self.createSprite("UI/fight/engeryD.png", {x = 115 + i * 15, y = posY}, {node})
    end
end

function UIFightLayer:createRightTop()
	local nodeRightTop = cc.Node:create()
    nodeRightTop:setPosition(self.visibleSize.width, self.visibleSize.height)    
    self:addChild(nodeRightTop)
    
    local function onBtnBackTouched(sender, event)
        print("exit ")
    end
    
    self.createButton({pos = {x = -80, y = -90},
        icon = "UI/fight/back.png",
        handle = onBtnBackTouched,
        parent = nodeRightTop
    })
    
    for i = 1, 4 do
        self.createSprite("UI/fight/frameS.png", {x = -40 - i * 95, y = -70}, {nodeRightTop})
        local friend = self.createSprite("UI/fight/rabitF.png", {x = -40 - i * 95, y = -60}, {nodeRightTop})
        friend:setScale(0.8)
        self.createLabel("LV564654", 18, {x = -40 - i * 95, y = -110}, nil, {nodeRightTop})
    end
end

function UIFightLayer:UpdateCD()
    local nowtime = os.clock()
    print("-----------Update CD------------------")
    for i = 1, 4 do
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
    self.createSprite("icon/skillIcon/jianqi.png", {x = -68, y = 85}, {nodeRightButtom})

    local function atkEnd()
    end
    local function  onBtnUseSKill(sender, event)
    	for key, value in pairs(self.btnSkill) do
    		if value == sender then
                MgrSkill.UseSkill(MgrSkill.EquipedSkill[key])
                self:UpdateCD()
    		end
    	end
    end

    local btnPos = {{x = -178.5, y = 40.5},
    				{x = -181, y = 121},
    				{x = -125.5, y = 188},
    				{x = -41, y = 199}}

    self.btnSkill = {}
    self.skillCD = {}
    skillPerferSize = {width = 68.4, height = 68.4}
    for i = 1, 4 do
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
        cdEff:setScale(0.57)
        self.skillCD[i] = cdEff
        nodeRightButtom:addChild(cdEff)

	    self.btnSkill[i]:setScale(0.57)
	    self.btnSkill[i]:setZoomOnTouchDown(false)
    end
end

return UIFightLayer