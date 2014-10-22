--region SceneLoading.lua
--Author : youfu
--Date   : 2014/8/13
--此文件由[BabeLua]插件自动生成

local SceneLoading = class("SceneLoading",function()
    return cc.Scene:create()
end)

function SceneLoading.create()
    local scene = SceneLoading.new()
    
    local textureDog = cc.Director:getInstance():getTextureCache():addImage("loading_logo.png")
    local spriteDog = cc.Sprite:createWithTexture(textureDog)
    spriteDog:setAnchorPoint({x = 0, y = 0})
    scene:addChild(spriteDog)
    
    local barSprite = cc.Sprite:create("background.png")
    scene.loadingProgress = cc.ProgressTimer:create(barSprite)
    scene.loadingProgress:setType(cc.PROGRESS_TIMER_TYPE_BAR)
    scene.loadingProgress:setScaleX(8)
    scene.loadingProgress:setAnchorPoint(0, 0.5)
    scene.loadingProgress:setPosition(100, 50)
    scene.loadingProgress:setMidpoint({x = 0, y = 0.5})
    scene.loadingProgress:setBarChangeRate({x = 1, y = 0})
    scene.loadingProgress:setPercentage(80)    
    scene:addChild(scene.loadingProgress)
    return scene
end

function SceneLoading:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
    self.schedulerID = nil
    local function loadingOver()        
        cc.Director:getInstance():replaceScene(require("SceneCity").create())
    end
    
    local duration = 0
    local function tick(detal)
        duration = duration + detal
        self.loadingProgress:setPercentage(duration/5 * 100)  
    end
    
    self.schedulerID = cc.Director:getInstance():getScheduler():scheduleScriptFunc(tick, 0, false)
    self:runAction(cc.Sequence:create(
        {cc.DelayTime:create(1), 
        cc.CallFunc:create(loadingOver, {}), 
        nil}))
    
    local function onExit()
        cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.schedulerID)    
    end
    
    --self:setOnExitCallback(onExit)
    
    local function onNodeEvent(event)
        if "exit" == event then
            cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.schedulerID)
            --self:unregisterScriptHandler()
        end
    end
    self:registerScriptHandler(onNodeEvent)
end

return SceneLoading
--endregion
