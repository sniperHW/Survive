local UISetting = class("UISetting", function()
    return require("UI.UIBaseLayer").create()
end)

function UISetting.create()
    local layer = UISetting.new()
    return layer
end

function UISetting:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
    self.schedulerID = nil
    self:setSwallowTouch()
    local layer = cc.LayerColor:create({r = 0, g = 0, b = 0, a = 120})
    self:addChild(layer)
    self:createUI()
    local function onBtnCloseTouched(sender, type)
        cc.Director:getInstance():getRunningScene().hud:closeUI(self.class.__cname)
    end

    self.btnClose = self.createButton{pos = {x = 700, y = 420},
        icon = "UI/common/close.png",
        handle = onBtnCloseTouched,
        parent = self.nodeMid}
end

function UISetting:createUI()
    self.nodeMid = cc.Node:create()
    self.nodeMid:setPositionX((self.visibleSize.width - DesignSize.width)/2)
    self:addChild(self.nodeMid)
    
    self.createSprite("UI/sign/tipBack.png", {x = 480, y = 320}, {self.nodeMid})
    self.createSprite("UI/sign/yuefen.png", {x = 480, y = 440}, {self.nodeMid})
    self.createLabel("设 置", 22, 
        {x = 480, y = 440}, nil, {self.nodeMid})

    local function updateMusic()
        if MgrSetting.bPlayMusic then
            self.lblMusicState:setString("开")            
        else
            self.lblMusicState:setString("关")
        end
        self.iconMusicState:setVisible(MgrSetting.bPlayMusic)
    end
    
    local function onMusicTouched(sender, event)
        MgrSetting.bPlayMusic = not MgrSetting.bPlayMusic
        cc.UserDefault:getInstance():setBoolForKey("bPlayMusic", MgrSetting.bPlayMusic)
        updateMusic()
        if MgrSetting.bPlayMusic then
            cc.SimpleAudioEngine:getInstance():playMusic(MgrSetting.curMusic, true)
        else
            cc.SimpleAudioEngine:getInstance():stopMusic()
        end
    end
    
    self.createLabel("背景音乐：", 22, 
        {x = 320, y = 350}, nil, {self.nodeMid})  

    self.lblMusicState = self.createLabel("开", 22, 
        {x = 380, y = 350}, nil, {self.nodeMid})  
        
    self.createButton{
        ignore = false,
        pos = {x = 420, y = 350},
        icon = "UI/setting/kk.png",
        handle = onMusicTouched,
        parent = self.nodeMid}
    self.iconMusicState = self.createSprite("UI/setting/g.png", 
        {x = 425, y = 360}, {self.nodeMid})
    updateMusic()

    local function updateEffect()
         if MgrSetting.bPlayEffect then
            self.lblEffectState:setString("开")            
        else
            self.lblEffectState:setString("关")
            cc.SimpleAudioEngine:getInstance():stopEffect()
        end
        self.iconEffectState:setVisible(MgrSetting.bPlayEffect)
    end

    local function onEffectTouched(sender, event)
        MgrSetting.bPlayEffect = not MgrSetting.bPlayEffect
        cc.UserDefault:getInstance():setBoolForKey("bPlayEffect", MgrSetting.bPlayEffect) 
        updateEffect()
    end
        
    self.createLabel("游戏音效：", 22, 
        {x = 550, y = 350}, nil, {self.nodeMid}) 
    self.lblEffectState = self.createLabel("开", 22, 
        {x = 610, y = 350}, nil, {self.nodeMid}) 
    self.createButton{
        ignore = false,
        pos = {x = 650, y = 350},
        icon = "UI/setting/kk.png",
        handle = onEffectTouched,
        parent = self.nodeMid}
    self.iconEffectState = self.createSprite("UI/setting/g.png", 
        {x = 655, y = 360}, {self.nodeMid})
    updateEffect()
    
    self.btnClose = self.createButton{title = "论 坛",
        pos = {x = 240, y = 200},
        icon = "UI/common/k.png",
        handle = nil,
        parent = self.nodeMid}
    self.btnClose:setPreferredSize({width = 120, height = 45})
    
    self.btnClose = self.createButton{title = "公 告",
        pos = {x = 420, y = 200},
        icon = "UI/common/k.png",
        handle = nil,
        parent = self.nodeMid}
    self.btnClose:setPreferredSize({width = 120, height = 45})
    
    self.btnClose = self.createButton{title = "退出登录",
        pos = {x = 600, y = 200},
        icon = "UI/common/k.png",
        handle = nil,
        parent = self.nodeMid}
    self.btnClose:setPreferredSize({width = 120, height = 45})
end

return UISetting