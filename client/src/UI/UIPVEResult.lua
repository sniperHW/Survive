local UIPVEResult = class("UIPVEResult", function()
    return require("UI.UIBaseLayer").create()
end)

function UIPVEResult.create()
    local layer = UIPVEResult.new()
    return layer
end

function UIPVEResult:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
    self.schedulerID = nil
end

function UIPVEResult:Win(awards)
    local size = self.visibleSize    
    local back = self.createScale9Sprite("UI/common/kuang.png", 
        {x = size.width/2-242, y = size.height/2-200}, {width = 484, height = 405}, {self})
            
    --back:setScaleY(2)
    
    local spr = self.createSprite("UI/pve/cg.png", {x = size.width/2+5, y = size.height/2+80}, {self})
    spr:runAction(cc.RepeatForever:create(cc.RotateBy:create(3,360)))
    self.createSprite("UI/pve/sl.png", {x = size.width/2, y = size.height/2+80}, {self})
    --self.createSprite("UI/pve/st.png", {x = size.width/2, y = size.height/2-190}, {self})
    local spr = self.createSprite("UI/pve/kk.png", {x = size.width/2, y = size.height/2-110}, {self})    
    spr:setScaleX(1.7)
    local curMaxLevel = 20 --maincha.attr.spve_today_max
    local copy = TableSingle_Copy_Balance[curMaxLevel]
    
    local awards = awards or {{id = 4001, count = copy.Shell}, 
        {id = 4004, count = copy.Experience},
        {id = 5301, count = 1}
        }
    local beginX = 200
    if #awards > 2 then
        beginX = 280
    end
    for i = 1, #awards do
        local itemInfo = TableItem[awards[i].id]
        local iconPath = "icon/itemIcon/"..itemInfo.Icon..".png"
        local spr = self.createSprite(iconPath, 
            {x = size.width/2-beginX+ 140*i, y = size.height/2-110}, {self})  
        spr:setScale(0.7)
        
        local label = cc.Label:createWithBMFont("fonts/shop.fnt", awards[i].count, 
            cc.TEXT_ALIGNMENT_CENTER, 0, {x = 0, y = 0})
        label:setPosition({x = size.width/2-beginX+ 140*i, y = size.height/2-150})
        self:addChild(label)
    end    
    
    --[[
    copy.Experience
    copy.Shell
    ]]
    self:setSwallowTouch()
end

function UIPVEResult:FailedAward(awards)
    local size = self.visibleSize
    self.createSprite("UI/pve/failed.png", {x = size.width/2, y = size.height/2}, {self})
    --back:setScaleY(2)
    local spr = self.createSprite("UI/pve/sbb.png", {x = size.width/2+5, y = size.height/2+80}, {self})
    spr:runAction(cc.RepeatForever:create(cc.RotateBy:create(6,360)))
    self.createSprite("UI/pve/sb.png", {x = size.width/2, y = size.height/2+80}, {self})
    
    local beginX = 200
    if #awards > 2 then
        beginX = 280
    end
    for i = 1, #awards do
        local itemInfo = TableItem[awards[i].id]
        local iconPath = "icon/itemIcon/"..itemInfo.Icon..".png"
        local spr = self.createSprite(iconPath, 
            {x = size.width/2-beginX+ 140*i, y = size.height/2-110}, {self})  
        spr:setScale(0.7)

        local label = cc.Label:createWithBMFont("fonts/shop.fnt", awards[i].count, 
            cc.TEXT_ALIGNMENT_CENTER, 0, {x = 0, y = 0})
        label:setPosition({x = size.width/2-beginX+ 140*i, y = size.height/2-150})
        self:addChild(label)
    end    
end

function UIPVEResult:Failed()
    local size = self.visibleSize
    self.createSprite("UI/pve/failed.png", {x = size.width/2, y = size.height/2}, {self})
    --back:setScaleY(2)
    local spr = self.createSprite("UI/pve/sbb.png", {x = size.width/2+5, y = size.height/2+80}, {self})
    spr:runAction(cc.RepeatForever:create(cc.RotateBy:create(6,360)))
    self.createSprite("UI/pve/sb.png", {x = size.width/2, y = size.height/2+80}, {self})
    self.createSprite("UI/pve/sbk.png", {x = size.width/2+5, y = size.height/2-90}, {self})
    self.createSprite("UI/pve/st.png", {x = size.width/2, y = size.height/2-190}, {self})
    local text = [[更新装备，提升技能等级都能有效提升战斗力]]
    local lbl = self.createLabel(text, 20, 
        {x = size.width/2, y = size.height/2-90}, cc.TEXT_ALIGNMENT_CENTER, {self},
        {width = 280, height = 0})
    lbl:setColor{r = 106, g = 57, b = 6}
end

return UIPVEResult