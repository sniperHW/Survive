local UIHudLayer = class("UIHudLayer",function()
    return cc.Node:create()
end)

function UIHudLayer.create()
    local hud = UIHudLayer.new()    
    return hud
end

function UIHudLayer.getHud()
    return cc.Director:getInstance():getRunningScene().hud
end

function UIHudLayer:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
    self.schedulerID = nil
    self.UIS = {}
    local uimsg = self:openUI("UIMessage")
    uimsg:setLocalZOrder(65535)
    
    local draw = cc.DrawNode:create()
    self:addChild(draw, 10)
    
    --[[
    local function tick()
        draw:clear()
        for id, player in pairs(MgrPlayer) do
            local box = player:GetAvatar3D():getBoundingBox()  
            local selfPos = player:getParent():convertToWorldSpace(cc.p(player:getPosition()))
            local offWidth = box.width/4
            local offHeight = box.height/4

            box = {x = box.x + offWidth, y = box.y + offHeight,
            width = box.width - offWidth*2,
            height = box.height - offHeight*2                
            }
            
            draw:drawPoint(selfPos, 3, cc.c4f(1,1,1,1))
            draw:drawRect(cc.p(box.x,box.y), 
                cc.p(box.x+box.width,box.y+box.height), cc.c4f(1,1,0,1))
        end
    end
    
    local function onNodeEvent(event)
        if "enter" == event then
            self.schedulerID = cc.Director:getInstance():getScheduler():scheduleScriptFunc(tick, 0, false)     
        end

        if "exit" == event then
            cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.schedulerID)
        end
    end
    self:registerScriptHandler(onNodeEvent)
    ]]
end

--[[
function UIHudLayer.createUI(className)
    local hud = cc.Director:getInstance():getRunningScene().hud
    return hud:openUI(className)
end
]]
function UIHudLayer:openUI(className)
    if self.UIS[className] == nil then
        print("UI."..className)
        local ui = require("UI."..className).create()
        self.UIS[className] = ui
        self:addChild(ui)
        return ui
    end
end

function UIHudLayer:closeUI(className)
    if self.UIS[className] ~= nil then
        print("close ui"..className)
        self.UIS[className]:removeFromParent()
        self.UIS[className] = nil
    end
end

function UIHudLayer:getUI(className)
    return self.UIS[className]
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
        --hint:UpdateGuide()
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


