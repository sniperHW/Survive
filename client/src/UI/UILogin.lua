local netCmd = require "src.net.NetCmd"

local UILogin = class("UILogin", function()
    return require("UI.UIBaseLayer").create()
end)

function UILogin.create()
    local layer = UILogin.new()
    return layer
end

local checkTickScheduleID = nil
local function checkTick(detal)
	local wpk = GetWPacket()
    WriteUint32(wpk, 0xABABCBCB)
    SendWPacket(wpk)
end

function UILogin:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
    self.schedulerID = nil

    self.createSprite("UI/login/login_bk.png", 
        {x = self.visibleSize.width/2, y = self.visibleSize.height/2}, {self})
        
    local nodeMid = cc.Node:create()
    self.nodeMid = nodeMid
    nodeMid:setPositionX((self.visibleSize.width - 960)/2)
    self:addChild(self.nodeMid)
    
    local function btnHandle(sender, event)
        print("pre connect")
        --Connect("192.168.0.87", 8010)
        Connect("121.41.37.227", 8010)
        --cc.Director:getInstance():replaceScene(require("SceneLoading.lua").create())
    end
    
    self.createButton{pos = {x = 500, y = 80},
        icon = "UI/login/enterGame.png",
        handle = btnHandle,
        parent = nodeMid
    }
    
    self.createButton{pos = {x = 380, y = 100},
        icon = "UI/login/vistorLogin.png",
        handle = btnHandle,
        parent = nodeMid
    }
    
    self.createButton{pos = {x = 250, y = 105},
        icon = "UI/login/Register.png",
        handle = btnHandle,
        parent = nodeMid
    }

    local function onTextHandle(typestr)
        if typestr == "began" then
        elseif typestr == "changed" then

        elseif typestr == "ended" then
        elseif typestr == "return" then
        end
        --return true
    end
    
    self.txtUserName = ccui.EditBox:create({width = 300, height = 60},
        "UI/login/txtInput.png")
        --self.createScale9Sprite("UI/login/txtInput.png", nil, {widht = 255, height = 55}, {}))
    self.txtUserName:setPosition(380, 295)
    self.txtUserName:setAnchorPoint(0, 0.5)
    self.txtUserName:registerScriptEditBoxHandler(onTextHandle)
    nodeMid:addChild(self.txtUserName)
    
    self.txtPass = ccui.EditBox:create({width = 300, height = 60},
        "UI/login/txtInput.png")
        --self.createScale9Sprite("UI/login/txtInput.png", nil, {widht = 255, height = 55}, {}))
    self.txtPass:setPosition(380, 210)
    self.txtPass:setAnchorPoint(0, 0.5)
    self.txtPass:setInputFlag(cc.EDITBOX_INPUT_FLAG_PASSWORD)
    self.txtPass:registerScriptEditBoxHandler(onTextHandle)
    nodeMid:addChild(self.txtPass)

    RegHandler(function (rpk)     
        print("CMD_CC_CONNECT_SUCCESS")    
        local userName = self.txtUserName:getText()
        local pass = self.txtPass:getText()
        CMD_LOGIN(userName, pass, 1)
        checkTickScheduleID = cc.Director:getInstance():getScheduler():scheduleScriptFunc(checkTick, 5, false)
    end, netCmd.CMD_CC_CONNECT_SUCCESS)

    --beginButton:registerControlEventHandler(btnHandle, cc.CONTROL_EVENTTYPE_TOUCH_UP_INSIDE)
end
    
RegHandler(function (rpk) 
    print("CMD_CC_CONNECT_FAILED")
end, netCmd.CMD_CC_CONNECT_FAILED)
    
RegHandler(function (rpk) 
    print("CMD_CC_DISCONNECTED")
    cc.Director:getInstance():getScheduler():unscheduleScriptEntry(checkTickScheduleID)
    checkTickScheduleID = nil
end, netCmd.CMD_CC_DISCONNECTED)
    
return UILogin