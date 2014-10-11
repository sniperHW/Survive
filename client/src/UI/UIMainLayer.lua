local UIMainLayer = class("UIMainLayer", function()
    return require("UI.UIBaseLayer").create()
end)

function UIMainLayer.create()
    local layer = UIMainLayer.new()
    return layer
end

function UIMainLayer:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    
    local texture = cc.Director:getInstance():getTextureCache():addImage("Main.png")
    local back = cc.Sprite:createWithTexture(texture)
    back:setAnchorPoint(0, 0)
    self:addChild(back)

    local function onTouchBegan(sender, event)
        local wpk = GetWPacket()
        WriteUint16(wpk, CMD_CG_ENTERMAP)
        SendWPacket(wpk)
        return true
    end

    local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
    
    self:createLeftTop()
    self:createRightTop()
    self:createRightButtom()
end

local function onHeadTouched(sender, type)
    local runScene = cc.Director:getInstance():getRunningScene()
    local hud = runScene.hud
    --hud:closeUI("UILogin")
    hud:openUI("UICharacter")
end

local function onShopTouched(sender, type)
    print("TODO on onShopTouched")
end

local function onGiftTouched(sender, type)
    print("TODO on gift")
end

local function onActivityTouched(sender, type)
    print("TODO onActivityTouched")
end

local function onFirstPayTouched(sender, type)
    print("TODO onFirstPayTouched")
end

local function onOnlineTouched(sender, type)
    print("TODO onOnlineTouched")
end

local function onBagTouched(sender, type)
	print("TODO onBagTouched")
end

local function onEquipTouched(sender, type)
    print("TODO onEquipTouched")
end

local function onSkillTouched(sender, type)
    print("TODO onSkillTouched")
end

local function onLifeTouched(sender, type)
    print("TODO onLifeTouched")
end

local function onFriendTouched(sender, type)
    print("TODO onFriendTouched")
end

local function onSystemTouched(sender, type)
    print("TODO onSystemTouched")
end

function UIMainLayer:createLeftTop()    
	local node = cc.Node:create()
    node:setPosition(0, self.visibleSize.height)	
	self:addChild(node)
    
    local iconSize = cc.Director:getInstance():getTextureCache():addImage("headicon/headicon_1.png"):getContentSize()
    local btncreate = { pos = {x = 0, y = -iconSize.height}, 
                        icon = "headicon/headicon_1.png",
                        parent = node,
                        handle = onHeadTouched}
    self.btnHead = self.createButton(btncreate)
	
	local playerName = cc.Label:create()
	playerName:setString(maincha.nickname)
	playerName:setAnchorPoint(0.5, 1)
	playerName:setSystemFontSize(20)
    playerName:setPosition(iconSize.width / 2, -iconSize.height - 10)
    node:addChild(playerName)	
    self.lblPlayerName = playerName 
    
    self.createSprite("UI/main/fight.png", {x = 120, y = -80}, {node})
    self.lblFight = self.createBMLabel("fonts/yellow.fnt", 
                                        "123", 
                                        {x = 180, y = -65},
                                        {node, {x = 0, y = 1}})
                                        
    local vipIcon = self.createSprite("UI/common/vip_icon.png", {x = 0, y = 0}, {node, {x = 0, y = 1}})
      
    self.lblVipLvl = self.createBMLabel("fonts/yellow.fnt", 
                                       "6", 
                                       {x = vipIcon:getContentSize().width, y = 0},
                                       {node, {x = 0, y = 1}})
    
    self.createSprite("UI/common/power_icon.png", 
                        {x = self.btnHead:getContentSize().width, y = 0},
                      {node, {x = 0, y = 1}})
                      
    self.lblPP = self.createBMLabel("fonts/yellow.fnt", 
                                    "100/200",
                                    {x = 150, y = -5},
                                    {node, {x = 0, y = 1}})
    
    self.createSprite("UI/common/money.png", 
                        {x = 260, y = 0},
                        {node, {x = 0, y = 1}})

    self.lblMoney = self.createBMLabel("fonts/yellow.fnt", 
                                        "1000000",
                                        {x = 300, y = -5},
                                        {node, {x = 0, y = 1}})
        
    self.createSprite("UI/common/gold.png", 
                        {x = 430, y = 0},
                        {node, {x = 0, y = 1}})
        
    self.lblGold = self.createBMLabel("fonts/yellow.fnt", 
                                        "10000",
                                        {x = 480, y = -5},
                                        {node, {x = 0, y = 1}})
end

function UIMainLayer:createRightTop()
    local node = cc.Node:create()
    node:setPosition(self.visibleSize.width, self.visibleSize.height)    
    self:addChild(node)
    
    local iconSize = cc.Director:getInstance():getTextureCache():addImage("UI/main/shop.png"):getContentSize()
    local interval = iconSize.width - 10
    local startX = -iconSize.width
    local posY = -iconSize.height

    self.btnShop = self.createButton{ pos = {x = startX, y = posY}, 
                                        icon = "UI/main/shop.png",
                                        parent = node,
                                        handle = onShopTouched}
    startX = startX - interval
    self.btnGift = self.createButton{ pos = {x = startX, y = posY}, 
                                        icon = "UI/main/gift.png",
                                        parent = node,
                                        handle = onGiftTouched}
    startX = startX - interval
    
    self.btnActivity = self.createButton{ pos = {x = startX, y = posY}, 
                                        icon = "UI/main/activity.png",
                                        parent = node,
                                        handle = onActivityTouched}
    startX = startX - interval
    
    self.btnFirstPay = self.createButton{ pos = {x = startX, y = posY}, 
                                        icon = "UI/main/firstPayGift.png",
                                        parent = node,
                                        handle = onFirstPayTouched}
    startX = startX - interval
    
    self.btnOnline = self.createButton{ pos = {x = startX, y = posY}, 
                                        icon = "UI/main/online.png",
                                        parent = node,
                                        handle = onOnlineTouched}
end

function UIMainLayer:createRightButtom()
    local node = cc.Node:create()
    node:setPosition(self.visibleSize.width, 0)    
    self:addChild(node)
    
    local nodeH = cc.Node:create()
    node:addChild(nodeH)
    
    local iconSize = cc.Director:getInstance():getTextureCache():addImage("UI/main/bag.png"):getContentSize()
    local interval = iconSize.width - 10
    local startX = -iconSize.width
    local posY = 10

    self.btnBag = self.createButton{ pos = {x = startX, y = posY}, 
                                        icon = "UI/main/bag.png",
                                        parent = nodeH,
                                        handle = onBagTouched}
    startX = startX - interval
    self.btnEquip = self.createButton{ pos = {x = startX, y = posY}, 
                                        icon = "UI/main/equip.png",
                                        parent = nodeH,
                                        handle = onEquipTouched}
    startX = startX - interval

    self.btnSkill = self.createButton{ pos = {x = startX, y = posY}, 
                                        icon = "UI/main/skill.png",
                                        parent = nodeH,
                                        handle = onSkillTouched}
    startX = startX - interval

    self.btnLife = self.createButton{ pos = {x = startX, y = posY}, 
                                        icon = "UI/main/life.png",
                                        parent = nodeH,
                                        handle = onLifeTouched}
    startX = startX - interval

    self.btnFreind = self.createButton{ pos = {x = startX, y = posY}, 
                                        icon = "UI/main/friend.png",
                                        parent = nodeH,
                                        handle = onFriendTouched}
    startX = startX - interval

    self.btnSystem = self.createButton{ pos = {x = startX, y = posY}, 
                                        icon = "UI/main/system.png",
                                        parent = nodeH,
                                        handle = onSystemTouched}
end

return UIMainLayer