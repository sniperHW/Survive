local UIMessage = require "UI.UIMessage"

local UISkillLayer = class("UISkillLayer", function()
    return require("UI.UIBaseLayer").create()
end)

local allSkill = {
    {1010, 1020, 1030, 1050, 1060},
    {1110, 1120, 1130, 1140, 1150},
    {1210, 1220, 1230, 1240, 1250}
}

local iconSkillType = {
    "UI/skill/0DJ.png",
    "UI/skill/0GB.png",
    "UI/skill/0QX.png",
}

local iconLockSkill = {
    "UI/skill/s1.png",
    "UI/skill/s2.png",
    "UI/skill/s3.png",
}

local curWeapon = 1     --1:sword,2:rod,3:gun

local curSkillID = 1010

function UISkillLayer:create()
    local layer = UISkillLayer.new()
    layer:setSwallowTouch()
    return layer
end

function UISkillLayer:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
    self.schedulerID = nil
    self:createBack()

    local sprite = self.createSprite("UI/common/split.png", {x = 600, y = 318}, {self.nodeMid})
    self.createLabel(Lang.Skill, 24, {x = 600, y = 550}, nil, {self.nodeMid})
    --sprite:setLocalZOrder(-1)
    self.skillCell = {}
    self:createLeft()
    self:createSkillInfo()
    
    local function onNodeEvent(event)
        if "enter" == event then
            --[[if MgrGuideStep == 13 then
                local hud = cc.Director:getInstance():getRunningScene().hud
                hud:closeUI("UIGuide")
                local ui = hud:openUI("UIGuide")

                ui:createWidgetGuide(self.skillCell[1].iconSkill, 
                    "UI/skill/KK.png", true)
            end]]--            

            local weaponid = maincha.equip[2].id
            if weaponid > 5000 and weaponid < 5100 then
                curWeapon = 1
            elseif weaponid > 5100 and weaponid < 5200 then
                curWeapon = 2
            elseif weaponid > 5200 and weaponid < 5300 then
                curWeapon = 3
            end
            
            self:UpdateSkill()
        elseif "exit" == event then
            --[[if MgrGuideStep == 13 then
                local hud = cc.Director:getInstance():getRunningScene().hud
                hud:closeUI("UIGuide")
                --CMD_COMMIT_INTRODUCE_STEP(MgrGuideStep)
                --MgrGuideStep = 12
                local main = hud:getUI("UIMainLayer")  
                main.UpdateGuide()    
            end]]
        end
    end
    self:registerScriptHandler(onNodeEvent)
end

function UISkillLayer:createLeft()
    local nodeSkill = cc.Node:create()
    nodeSkill:setPosition(0,0)
    self.nodeMid:addChild(nodeSkill)
    self.nodeSkill = nodeSkill
    
    local sprite = self.createSprite("UI/skill/r.png", {x = 340, y = 318}, {self.nodeMid})
    sprite:setScale(1.1)
    sprite:setLocalZOrder(-1)
    
    local switchBack= cc.Sprite:create()
    switchBack:setLocalZOrder(1)
    switchBack:setVisible(false)
    self.nodeSkill:addChild(switchBack)
    
    local function switchWeapon(sender, event)
        if curWeapon ~= sender:getTag() then
            curWeapon = sender:getTag()
            curSkillID = allSkill[curWeapon][1]
            self:UpdateSkill()
            self:UpdateSkillInfo()
        end
        switchBack:setVisible(false)
    end
    
    local btn = self.createButton{pos = { x = 400, y = 480},
        icon = "UI/skill/switchback.png",
        title = "刀剑系",
        handle = switchWeapon,
        parent = switchBack
    }
    btn:setTag(1)
    
    btn = self.createButton{pos = { x = 400, y = 440},
        icon = "UI/skill/switchback.png",
        title = "棍棒系",
        handle = switchWeapon,
        parent = switchBack
    }
    btn:setTag(2)
    
    btn = self.createButton{pos = {x = 400, y = 400},
        icon = "UI/skill/switchback.png",
        title = "枪械系",
        handle = switchWeapon,
        parent = switchBack
    }
    btn:setTag(3)
    
    local function openSwithch(sender, event)
        local visible = switchBack:isVisible()         
        switchBack:setVisible(not visible)
    end
    
    self.createButton{pos = { x = 510, y = 380},
        icon = "UI/skill/switchWeapon.png",
        handle = openSwithch,
        parent = nodeSkill
    }
    
    local function onSkillTouched(sender, event)
        local index = sender:getTag()
        curSkillID = allSkill[curWeapon][index]
        if curSkillID > 0 then
            for key, value in pairs(self.skillCell) do
                value.iconSel:setVisible(key == index)
            end
            self:UpdateSkillInfo()
        end
        
        if MgrGuideStep == 13 then            
            local hud = cc.Director:getInstance():getRunningScene().hud
            hud:closeUI("UIGuide")
            local ui = hud:openUI("UIGuide")            
            ui:createWidgetGuide(self.btnSkillHandle, "UI/common/k.png", true)
        end
    end
    
    self.iconWeapon = self.createSprite("UI/skill/0DJ.png", {x = 340, y = 318}, {nodeSkill})
    local back0 = "UI/skill/KK.png"
    local back1 = "UI/skill/kk2.png"
    local pos = {{x = 270, y = 460}, {x = 430, y = 460}, 
        {x = 490, y = 330}, {x = 430, y = 180},
        {x = 270, y = 180}, {x = 190, y = 330}}
    local function createSkillIcon(index)
        self.skillCell[index] = {}
        local skillID = allSkill[curWeapon][index]
        local skillInfo = TableSkill[skillID]
        local backPath = nil
        if maincha.skill and maincha.skill[skillID] then
            backPath = back0
        else
            backPath = back1
        end
        
        local back = self.createButton{
            pos = pos[index],
            icon = backPath,
            handle = onSkillTouched,
            ignore = false,
            parent = nodeSkill    
        }
        back:setZoomOnTouchDown(false)
        back:setTag(index)
        self.skillCell[index].btnBack = back
        
        local iconPath = ""
        local level = 0
        if skillInfo then
            iconPath = "icon/skillIcon/"..skillInfo.Icon_Path..".png"            
            self.skillCell[index].lblSkillName = self.createLabel(skillInfo.Skill_Name, 
                18, {x = 70, y = 12}, nil, {back})
            self.skillCell[index].lblSkillName:setLocalZOrder(1)
            if maincha.skill and maincha.skill[skillID] then
                level = maincha.skill[skillID].level
            end
        else
            iconPath = "UI/skill/s1.png"
        end
        
        self.skillCell[index].iconSkill = self.createSprite(iconPath, pos[index], {nodeSkill})
        self.skillCell[index].iconSel = 
            self.createSprite("UI/skill/xz.png", {x = pos[index].x, y = pos[index].y + 10}, {nodeSkill})
        self.skillCell[index].iconSel:setVisible(skillID == curSkillID)
        self.skillCell[index].lblSkillLevel = self.createBMLabel(
            "fonts/jinenglv.fnt", level, {x = pos[index].x + 40, y = pos[index].y - 30}, {nodeSkill})
        
        if index < 6 then
            self.skillCell[index].iconSkill:setScale(0.77)
        end
    end
    
    for i = 1, 6 do
        createSkillIcon(i)
    end
end

function UISkillLayer:UpdateSkill()
    local function updateSkillIcon(index)
        local skillID = allSkill[curWeapon][index]
        local skillInfo = TableSkill[skillID]
        
        local iconPath = ""
        if skillInfo then            
            self.skillCell[index].lblSkillName:setString(skillInfo.Skill_Name)
            local back0 = "UI/skill/KK.png"
            local back1 = "UI/skill/kk2.png"
            local level = 0
            local backpath = back0
            if maincha.skill and maincha.skill[skillID] then
                level = maincha.skill[skillID].level
                backpath = back0
                iconPath = "icon/skillIcon/"..skillInfo.Icon_Path..".png"
                self.skillCell[index].lblSkillLevel:setString(level)
                self.skillCell[index].lblSkillLevel:setVisible(true)
            else
                iconPath = "icon/skillIcon/"..skillInfo.Icon_Path.."d.png"
                backpath = back1                
                self.skillCell[index].lblSkillLevel:setVisible(false)
            end
            self.skillCell[index].btnBack:setBackgroundSpriteForState(
                ccui.Scale9Sprite:create(backpath), cc.CONTROL_STATE_NORMAL)
        else
            iconPath = iconLockSkill[curWeapon]
            self.skillCell[index].lblSkillLevel:setVisible(false)
        end
        self.skillCell[index].iconSkill:setTexture(iconPath)
        self.skillCell[index].iconSel:setVisible(curSkillID == skillID)
    end

    for i = 1, 6 do
        updateSkillIcon(i)
    end
    self.iconWeapon:setTexture(iconSkillType[curWeapon])
end

function UISkillLayer:createSkillInfo()
    local nodeSkillInfo = cc.Node:create()
    nodeSkillInfo:setPosition(0,0)
    self.nodeMid:addChild(nodeSkillInfo)
    self.nodeSkillInfo = nodeSkillInfo
    
    local sprite = self.createSprite("UI/character/kkkkkk.png", {x = 730, y = 318}, {self.nodeMid})
    sprite:setOpacity(180)
    sprite:setScaleX(0.7)
    sprite:setScaleY(1.1)
    sprite:setLocalZOrder(-1)

    self.createSprite("UI/skill/K2.png", {x = 740, y = 480}, {nodeSkillInfo})
    self.lblCurSkillName = self.createLabel("skill name", 
                20, {x = 740, y = 480}, nil, {nodeSkillInfo})
    self.lblCurSkillName:setTextColor({r = 0, g = 0, b = 0})

    self.lblCurSkillEff = self.createLabel("skill eff", nil, {x = 740, y = 450}, nil,
        {nodeSkillInfo, {x = 0.5, y = 1}}, {width = 200, height = 0})
    self.lblSkillDes = self.createLabel("---", nil, 
        { x = 740, y = 420}, nil, {nodeSkillInfo, {x = 0.5, y = 1}},
        {width = 200, height = 0})
    self.lblSkillUpEff = self.createLabel("随技能等级提升伤害效果", nil, {x = 770, y = 340}, nil,
        {nodeSkillInfo, {x = 0.5, y = 1}}, {width = 280, height = 0})
        
    self.lblUnlockCondition = self.createLabel("解锁条件：前一个技能解锁", 18, 
        {x = 770, y = 280}, nil,
        {nodeSkillInfo, {x = 0.5, y = 1}}, {width = 280, height = 0})
    
    self.lblSkillDes:setTextColor({r = 255, g = 255, b = 255})
    
    self.lblNeedName = self.createLabel("所需贝壳:", 18, 
        { x = 650, y = 240}, nil, {nodeSkillInfo, {x = 0, y = 0.5}})
    self.lblNeedValue = self.createLabel("100000", 18, 
        { x = 830, y = 240}, nil, {nodeSkillInfo, {x = 1, y = 0.5}})
    self.lblHaveName = self.createLabel("现有贝壳:", 18, 
        { x = 650, y = 210}, nil, {nodeSkillInfo, {x = 0, y = 0.5}})
    self.lblHaveValue = self.createLabel("00100000", 18, 
        { x = 830, y = 210}, nil, {nodeSkillInfo, {x = 1, y = 0.5}})
        
    local function upgradeTouched()        
        if maincha.skill and maincha.skill[curSkillID] then
            local skillLevel = maincha.skill[curSkillID].level
            local needMoney = Tableskill_Upgrade[skillLevel].Money
            if maincha.attr.level == skillLevel then
                UIMessage.showMessage(Lang.LevelLimit) 
                return
            end
            if needMoney > maincha.attr.shell then
               UIMessage.showMessage(Lang.ShellNotEnough) 
                return
            end 
            CMD_UPGRADESKILL(curSkillID)
            --[[if MgrGuideStep == 13 then            
                local hud = cc.Director:getInstance():getRunningScene().hud
                hud:closeUI("UIGuide")
                local ui = hud:openUI("UIGuide")            
                ui:createWidgetGuide(self.skillCell[2].iconSkill, 
                    "UI/skill/KK.png", true)
            end]]--
        else
            for key, value in pairs(allSkill[curWeapon]) do
                if value == curSkillID then
                    local lastIdx = key - 1
                    if key == 1 or 
                        (maincha.skill and 
                            maincha.skill[allSkill[curWeapon][lastIdx]]) then
                        local needSoul = TableSkill[curSkillID].Soul or 0
                        if needSoul > maincha.attr.soul then
                            UIMessage.showMessage(Lang.SoulNotEnough) 
                        else
                            CMD_UNLOCKSKILL(curSkillID)
                            --[[local hud = cc.Director:getInstance():getRunningScene().hud
                            hud:closeUI("UIGuide")
                            local ui = hud:openUI("UIGuide")   
                            ui:createWidgetGuide(self.btnClose, 
                                "UI/common/close.png", false)]]
                        end
                    else
                        UIMessage.showMessage(Lang.LastSkillLocked) 
                    end
                    return
                end
            end
        end
    end
        
    self.btnSkillHandle  = self.createButton{title = "升级技能",
        pos = {x = 740, y = 150},
        icon = "UI/common/k.png",
        handle = upgradeTouched,
        ignore = false,
        parent = nodeSkillInfo    
    }
    self:UpdateSkillInfo()
end

function UISkillLayer:UpdateSkillInfo()
    local skillInfo = TableSkill[curSkillID]
    if not skillInfo then return end
    self.lblCurSkillEff:setString("效果："..skillInfo.Effect_Describe)    
    self.lblCurSkillName:setString(skillInfo.Skill_Name)
    self.lblSkillDes:setString(skillInfo.Ability_Describe)
    local posY = self.lblSkillDes:getPositionY() - self.lblSkillDes:getContentSize().height - 10
    self.lblSkillUpEff:setPositionY(posY)
    if maincha.skill and maincha.skill[curSkillID] then
        local level = maincha.skill[curSkillID].level
        self.lblSkillUpEff:setVisible(true)
        local addEffValue = TableSkill_Addition[level][tostring(curSkillID)]
        local addEffstr = string.format(skillInfo.Skill_Addition, addEffValue)
        self.lblSkillUpEff:setString(addEffstr)
        self.lblUnlockCondition:setVisible(false)    
        self.btnSkillHandle:setTitleForState("升级技能", cc.CONTROL_STATE_NORMAL)
        self.lblNeedName:setString("所需贝币")
        self.lblHaveName:setString("现有贝币")
        local needMoney = Tableskill_Upgrade[level].Money
        self.lblNeedValue:setString(needMoney)
        self.lblHaveValue:setString(maincha.attr.shell)
        if needMoney > maincha.attr.shell then
            self.lblNeedValue:setColor({r = 255, g = 0, b = 0})
        else
            self.lblNeedValue:setColor({r = 255, g = 255, b = 255})
        end
    else
        self.lblSkillUpEff:setVisible(false)
        self.lblUnlockCondition:setVisible(true)
        self.btnSkillHandle:setTitleForState("技能解锁", cc.CONTROL_STATE_NORMAL)
        self.lblNeedName:setString("所需精元")
        self.lblHaveName:setString("现有精元")
        local needSoul = TableSkill[curSkillID].Soul or 0
        self.lblNeedValue:setString(needSoul)
        self.lblHaveValue:setString(maincha.attr.soul)
        if needSoul > maincha.attr.soul then
            self.lblNeedValue:setColor({r = 255, g = 0, b = 0})
        else
            self.lblNeedValue:setColor({r = 255, g = 255, b = 255})
        end
    end
end

return UISkillLayer