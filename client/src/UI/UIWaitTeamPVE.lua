local UIWaitTeamPVE = class("UIWaitTeamPVE", function()
    return require("UI.UIBaseLayer").create()
end)

function UIWaitTeamPVE.create()
    local layer = UIWaitTeamPVE.new()
    return layer
end

function UIWaitTeamPVE:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
    self.schedulerID = nil
    self:setSwallowTouch()
    
    self.nodeMid = cc.Node:create()
    self.nodeMid:setPositionX((self.visibleSize.width - DesignSize.width)/2)
    self:addChild(self.nodeMid)   

    local size = self.visibleSize
    if self.visibleSize.width/self.visibleSize.height < 1.5 then
        self.nodeMid:setScale(0.9)
        self.nodeMid:setPositionX(0)
    end
    
    local back = self.createSprite("UI/pve/hk.png", 
        {x = DesignSize.width/2 , y = DesignSize.height/2}, 
        {self.nodeMid})
    back:setScale(2)   
    
    self.createLabel("匹配排队中...", 26, {x = 480, y = 380}, nil, {self.nodeMid})
    self.createLabel("已等待时间：", 26, {x = 450, y = 320}, nil, {self.nodeMid})
    self.lblTime = self.createLabel("0秒", 26, {x = 530, y = 320}, 
        nil, {self.nodeMid, {x = 0, y = 0.5}})             
    self.lblTime:setColor{r = 250, g = 205, b = 137}
    
    local function onCancelTouched(sender, event)
        self:removeFromParent()
    end
    
    local btn = self.createButton{title = "取 消",
        ignore = false, 
        pos = {x = 480, y = 260},
        icon = "UI/mail/sc.png",
        handle = onCancelTouched,
        parent = self.nodeMid}
    btn:setTitleTTFSizeForState(26, cc.CONTROL_STATE_NORMAL)
    local lbl = btn:getTitleLabelForState(cc.CONTROL_STATE_NORMAL)
    lbl:enableOutline(ColorBlack, 2)
    
    local waitS = 0
    local function tick()
        waitS = waitS + 1
        self.lblTime:setString(waitS.."秒")
    end
    
    self.schedulerID = cc.Director:getInstance():getScheduler():scheduleScriptFunc(tick, 1, false)
    
    local function onNodeEvent(event)
        if "exit" == event then
            cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.schedulerID)
        end
    end
    self:registerScriptHandler(onNodeEvent)    
end

return UIWaitTeamPVE
 