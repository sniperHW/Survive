local UIHudLayer = class("UIHudLayer",function()
    return cc.Node:create()
end)

function UIHudLayer.create()
    local hud = UIHudLayer.new()
    
    return hud
end

function UIHudLayer:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
    self.schedulerID = nil
    local uimsg = self:openUI("UIMessage")
    uimsg:setLocalZOrder(65535)
end

function UIHudLayer:openUI(className)
    if self[className] == nil then
        print("UI."..className)
        local ui = require("UI."..className).create()
        self[className] = ui
        self:addChild(ui)
        return ui
    end
end

function UIHudLayer:closeUI(className)
    if self[className] ~= nil then
        print("close ui"..className)
        self[className]:removeFromParent()
        self[className] = nil
    end
end

function UIHudLayer:getUI(className)
    return self[className]
end

function UIHudLayer:showHint(type, bagIdx, pos)   
--[[
    local item = 0
    maincha.bag = {}
    maincha.bag[1] = {id = 5503}]]
--[[     if type == 1 then
        item = maincha.bag[bagIdx]
    else
        item = maincha.equip[bagIdx] 
    end]]
    --local pos = {x = 200, y = 400}
    
    
    if true then
        local hint = self:openUI("UIHintLayer")
        hint:setPosition(pos)
        local width, height = hint:showHint(type, bagIdx)
        --hint:showHint(EnumHintType.bag, 1)
        --[[hint.item = item 
        local itemid = item.id
        
        local width, height = hint:createItemInfo(itemid)
        if pos.y > height then
            hint:setPositionY(pos.y)
        else
            hint:setPositionY(pos.y + height)
        end
        ]]
        local visibleSize = self.visibleSize
        
        hint:setPositionX(visibleSize.width/2 - 200)
        hint:setPositionY(visibleSize.height/2 + height/2)
        --[[
        if visibleSize.width - width > pos.x then
            hint:setPositionX(pos.x)
        else
            hint:setPositionX(pos.x - width + 80)
        end
        
        if pos.y > height then
            hint:setPositionY(pos.y)
        else
            hint:setPositionY(pos.y + height)
        end
        ]]
    end
end

return UIHudLayer


