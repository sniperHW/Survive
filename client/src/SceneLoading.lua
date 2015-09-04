--region SceneLoading.lua
--Author : youfu
--Date   : 2014/8/13
--此文件由[BabeLua]插件自动生成

local SceneLoading = class("SceneLoading",function()
    return cc.Scene:create()
end)

local targetMapID = nil
function SceneLoading.create(mapID)
    targetMapID = mapID
    local scene = SceneLoading.new()
    scene.mapID = mapID

    return scene
end

function SceneLoading:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
    self.schedulerID = nil
    
    local textureDog = cc.Director:getInstance():getTextureCache():addImage("UI/loading/ditu.png")
    local spriteDog = cc.Sprite:createWithTexture(textureDog)
    --spriteDog:setAnchorPoint({x = 0, y = 0})
    spriteDog:setScaleX(self.visibleSize.width/960)
    spriteDog:setPosition(self.visibleSize.width/2, 320)
    self:addChild(spriteDog)
    local spriteBarBack = cc.Sprite:create("UI/loading/k.png")
    --spriteBarBack:setAnchorPoint(0, 0.5)
    spriteBarBack:setPosition(self.visibleSize.width/2, 50)
    self:addChild(spriteBarBack)
    
    local barSprite = cc.Sprite:create("UI/loading/k2.png")
    self.loadingProgress = cc.ProgressTimer:create(barSprite)
    self.loadingProgress:setType(cc.PROGRESS_TIMER_TYPE_BAR)
    --self.loadingProgress:setScaleX(8)
    --self.loadingProgress:setAnchorPoint(0, 0.5)
    self.loadingProgress:setPosition(self.visibleSize.width/2, 50)
    self.loadingProgress:setMidpoint({x = 0, y = 0.5})
    self.loadingProgress:setBarChangeRate({x = 1, y = 0})
    self.loadingProgress:setPercentage(0)    
    self:addChild(self.loadingProgress)
    
    local loadImages = {}
         
    local mapInfo = TableMap[targetMapID]
    if mapInfo.Source_Path == "PVP" then
        local path = nil
        for i = 1, 8 do
            path = "Scene/"..mapInfo.Source_Path..i..".png"
            table.insert(MgrLoadedMap, path)
            table.insert(loadImages, path)
        end
    else
        local path = "Scene/"..mapInfo.Source_Path..".png"
        table.insert(MgrLoadedMap, path)
        table.insert(loadImages, path)        
    end
    
    local totalCount = #loadImages
    local function onLoad()
        if #loadImages > 0 then
            print(#loadImages)
            local image = loadImages[1]
            table.remove(loadImages, 1)
            local percentage = (totalCount - #loadImages)/totalCount * 100
            self.loadingProgress:setPercentage(percentage)
            local cache = cc.Director:getInstance():getTextureCache()
            cache:addImageAsync(image, onLoad) 
        else
            if MgrPlayer[maincha.id] 
                or self.mapID == 205
                or self.mapID == 202 then
                
                local scene = nil 
                if self.mapID == 205 then
                    scene = require("SceneGarden").create(0)
                else
                    scene = require("SceneCity").create(targetMapID)
                end
                cc.Director:getInstance():replaceScene(scene)
            else
                self:runAction(cc.Sequence:create(cc.DelayTime:create(1), 
                    cc.CallFunc:create(onLoad)))
            end
        end
    end

    local function loadingOver()        
        local scene = nil 
        if self.mapID == 205 then
            scene = require("SceneGarden").create(0)
        else
            scene = require("SceneCity").create(self.mapID)
        end
        cc.Director:getInstance():replaceScene(scene)
    end
    
    local duration = 0
    local function tick(detal)
        duration = duration + detal
        self.loadingProgress:setPercentage(duration/5 * 100)  
    end
    --[[
    self.schedulerID = cc.Director:getInstance():getScheduler():scheduleScriptFunc(tick, 0, false)
    self:runAction(cc.Sequence:create(
        {cc.DelayTime:create(0.5), 
        cc.CallFunc:create(loadingOver, {}), 
        nil}))
    ]]
    local function onNodeEvent(event)
        if "enter" == event then
            local cache = cc.Director:getInstance():getTextureCache()
            for _, path in pairs(MgrLoadedMap) do
                cache:removeTextureForKey(path)
            end
            MgrLoadedMap = {}
            --cache:removeUnusedTextures()
            --MgrPlayer = {}
            onLoad()
        elseif "exit" == event and self.schedulerID then
            cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.schedulerID)
            --self:unregisterScriptHandler()
        end
    end
    self:registerScriptHandler(onNodeEvent)
end

return SceneLoading
--endregion
