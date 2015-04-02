local netCmd = require "src.net.NetCmd"
maincha = maincha or {}
MgrPlayer = MgrPlayer or {}
MgrSign = MgrSign or {} 
MgrSetting = MgrSetting or 
    {bPlayMusic = true, bPlayEffect = true, bJoyStickType = false}
MgrControl = MgrControl or 
    {bTouchJoyStick = false}
MgrGuideStep = 0
MgrAchieve = nil
MgrFriend = {Friend = {}, Black = {}}
MgrMail = MgrMail or {}
MgrChat = MgrChat or {World = {}, Private = {}, Target = nil}


function addItem(itemid, num)
    local gm = ""
    if itemid == 4002 then
        local count = maincha.attr.pearl + num
        gm = "*setattr pearl ".. count
    elseif itemid == 4001 then
        local count = maincha.attr.shell + num
        gm = "*setattr shell ".. count
    elseif itemid == 4004 then
        local count = num
        gm = "*setattr exp ".. count
    elseif itemid == 4003 then
        local count = maincha.attr.soul + num
        gm = "*setattr soul ".. count
    else
        gm = "*newres "..itemid .." "..num
    end
    --CMD_CHAT(gm)
end

local function compareItem(item1, item2)
    local itemInfo1 = TableItem[item1.id]
    local itemInfo2 = TableItem[item2.id]

    if (itemInfo1.Item_Type < itemInfo2.Item_Type) then
        return true
    elseif itemInfo1.Item_Type > itemInfo2.Item_Type then
        return false
    else
        return itemInfo1.Ordering_Code < itemInfo2.Ordering_Code
    end
end

RegNetHandler(function (packet)
    CMD_ENTERMAP(packet.maptype)
end, netCmd.CMD_GC_ENTERPSMAP)

RegNetHandler(function (packet)
    local bNeedSort = false
    for i = 1, #packet.bag do
        if packet.bag[i].bagpos <= 10 then
            if packet.bag[i].id == 0 then
                maincha.equip[packet.bag[i].bagpos] = nil
            else
                maincha.equip[packet.bag[i].bagpos] = packet.bag[i]
            end
        else
            for j = 1, #maincha.bag do
                if maincha.bag[j].bagpos == packet.bag[i].bagpos then
                    if packet.bag[i].id == 0 then
                        for k = j, #maincha.bag - 1 do
                            maincha.bag[k] = maincha.bag[k + 1]
                        end
                        maincha.bag[#maincha.bag] = nil
                    else
                        maincha.bag[j] = packet.bag[i]
                    end       
                    break             
                end
                if j == #maincha.bag then    --add
                    maincha.bag[j+1] = packet.bag[i]
                    bNeedSort = true 
                end
            end
        end
    end
    if bNeedSort then
        table.sort(maincha.bag, compareItem)
    end
    
    local hud = cc.Director:getInstance():getRunningScene().hud
    local equip = hud:getUI("UIEquip")
    if equip then
        equip:UpdateEquip()
        equip:UpdateUpgrade()
        equip:UpdateInlay()
        equip:UpdateStar()
    end
    
    for key, ui in pairs(hud.UIS) do
        if ui.onBagUpdate then
            ui:onBagUpdate()
        end
    end
end, netCmd.CMD_GC_BAGUPDATE)

RegNetHandler(function (packet)
    local bNeedSort = false
    for i = 1, #packet do
        local item = packet[i]
        if item.bagpos <= 10 then
            if item.id == 0 or item.count == 0 then
                MgrFight.battleitems[item.bagpos] = nil
            else
                MgrFight.battleitems[item.bagpos] = item
            end
        end
    end
    
    if bNeedSort then
        table.sort(maincha.bag, compareItem)
    end
    
    local hud = cc.Director:getInstance():getRunningScene().hud
    for key, ui in pairs(hud.UIS) do
        if ui.onBagUpdate then
            ui:onBagUpdate()
        end
    end
end, netCmd.CMD_SC_BAGUPDATE)

RegNetHandler(function (packet) 
    print("begin play")
    maincha.uniqueid = packet.uniqueid
    maincha.avatarid = packet.avatarid
    maincha.nickname = packet.nickname
    maincha.attr = packet.attr
    maincha.bag = {}
    maincha.equip = {}
    
    for i = 1, #packet.bag do
        if packet.bag[i].bagpos <= 10 then
            maincha.equip[packet.bag[i].bagpos] = packet.bag[i]
        else
            local idx = #maincha.bag + 1
            maincha.bag[idx] = packet.bag[i]
        end        
    end
    table.sort( maincha.bag, compareItem)

    maincha.skill = packet.skill     
    
    BeginTime = {localtime = os.clock(), servertime = packet.server_timestamp} 
    if maincha.attr.fishing_start + maincha.attr.gather_start +
        maincha.attr.sit_start > 0 then        
        local scene = require("SceneLoading").create(205)
        cc.Director:getInstance():replaceScene(scene)
    end
    
    MgrSign = packet.everydaysign    
    
    local hud = cc.Director:getInstance():getRunningScene().hud
    hud:closeUI("UILogin")
    hud:openUI("UIMainLayer")   
end, netCmd.CMD_GC_BEGINPLY)

RegNetHandler(function (packet) 
    local hud = cc.Director:getInstance():getRunningScene().hud
    hud:closeUI("UILogin")
    hud:openUI("UICreatePlayer")
end,netCmd.CMD_GC_CREATE)

RegNetHandler(function (packet)     
    maincha.attr = packet.attr
    maincha.id = packet.selfid
    MgrFight.battleitems = packet.battleitems 
    MgrFight.weapon = maincha.equip[2]
    if MgrFight.battleitems then
        local hud = cc.Director:getInstance():getRunningScene().hud
        for key, ui in pairs(hud.UIS) do
            if ui.onBagUpdate then
                ui:onBagUpdate()
            end
        end
    end
    print("----------enter map:"..maincha.id)
    
    local mapInfo = TableMap[packet.maptype]
    InitAstar("Scene/"..mapInfo.Colision)

    if packet.maptype ~= 202 then
        local scene = require("SceneLoading").create(packet.maptype)
        cc.Director:getInstance():replaceScene(scene)
    end    
    
    if packet.tick_remain > 0 and packet.tick_remain <= 10000 then
        MgrFight.EnterMapTime = os.clock() - (10 - packet.tick_remain/1000)
    else
        MgrFight.EnterMapTime = 0
    end
    MgrFight.FivePVERound = 0
end,netCmd.CMD_SC_ENTERMAP)

RegNetHandler(function (packet)
    local player = MgrPlayer[packet.id]
    if packet.id == maincha.id then
        MgrFight.weapon = packet.weapon        
        local hud = cc.Director:getInstance():getRunningScene().hud
        local ui = hud:getUI("UIFightLayer")
        if ui then
            ui:RecreateSkill()
        end
    end
    player:SetWeapon(packet.weapon)    
end,netCmd.CMD_SC_UPDATEWEAPON)

--移动失败
RegNetHandler(function (packet)
    print("move failed")
end,netCmd.CMD_SC_MOV_FAILED)

--移动成功
RegNetHandler(function (packet)
    local avatar = MgrPlayer[packet.id]
    local cx, cy = avatar:getPosition()
    
    --[[
    if packet.id ~= maincha.id then
        
    end
    ]]
    if packet.id == maincha.id then
        if not MgrSetting.bJoyStickType then
            avatar:WalkTo({x = packet.x, y = packet.y}, packet.speed)
            local localPlayer = MgrPlayer[maincha.id]
            localPlayer.moveTo = nil
        end
    else
        avatar:WalkTo({x = packet.x, y = packet.y}, packet.speed)
    end
    
end,netCmd.CMD_SC_MOV)

--进入视野
RegNetHandler(function (packet)
    print("enter see avatid:"..packet.avatid)
    local player = require("Avatar").create(packet.avatid, packet.weapon)
    if not player then
        print("************create avat failed:"..packet.avatid)
    end
    player.fashion = packet.fashion
    player.id = packet.id
    player.avatid = packet.avatid
    player.avattype = packet.avattype
    player.name = packet.name
    player.attr = packet.attr
    player:SetAvatarName(player.name)
    player.teamid = packet.teamid
    player:SetLife(player.attr.life, player.attr.maxlife)
    player:setPosition(cc.WalkTo:tile2MapPos({x = packet.x, y = packet.y}))
    local avatar3D = player:GetAvatar3D()
    if avatar3D then
        local rotation3D = avatar3D:getRotation3D()    
        player:GetAvatar3D():setRotation3D{x = rotation3D.x, y = packet.dir+90, z = rotation3D.z}
    end
    player:retain()
    MgrPlayer[packet.id] = player
    local runningScene = cc.Director:getInstance():getRunningScene()
    if runningScene.class.__cname == "SceneCity" or 
        runningScene.class.__cname == "SceneGuidePVE" then
        runningScene.map:addChild(player)
        player:release()
        if packet.id == maincha.id then
            runningScene.localPlayer = player
        end
    end
    
    if packet.id == maincha.id then    
        MgrFight.weapon = packet.weapon
        local hud = cc.Director:getInstance():getRunningScene().hud
        local ui = hud:getUI("UIFightLayer")
        if ui then
            ui:UpdateLife()     
            ui:RecreateSkill()
        end
    
    --[[
        local weaponid = packet.weapon.id
        if weaponid > 5000 and weaponid < 5100 then
            MgrSkill.EquipedSkill = {1010, 1020, 1030, 1050, 1060}
            MgrSkill.BaseSkill = {11, 12, 13}
        elseif weaponid > 5100 and weaponid < 5200 then
            MgrSkill.EquipedSkill = {1110, 1120, 1130, 1140, 1150}
            MgrSkill.BaseSkill = {1511, 1512}
            
        end
        ]]
    end
    
    if player.attr.life and player.attr.life <= 0 then
        player:Death()
    end

    local hud = cc.Director:getInstance():getRunningScene().hud
    local fight = hud:getUI("UIFightLayer")
    if fight then        
        fight:UpdateTeam()
    end
end,netCmd.CMD_SC_ENTERSEE)

--离开视野
RegNetHandler(function (packet)
    print("leave see:"..packet.id)
    if packet.id ~= maincha.id then        
        print("release avatar:"..packet.id)
        MgrPlayer[packet.id]:removeFromParent()
        print("release avatar over:"..packet.id)
        MgrPlayer[packet.id] = nil    
        --player:removeFromParent()
        --[[
        if MgrFight.lockTarget and 
            packet.id == MgrFight.lockTarget.id then
            MgrFight.lockTarget = nil
        end]]

        local hud = cc.Director:getInstance():getRunningScene().hud
        local fight = hud:getUI("UIFightLayer")
        if fight then        
            fight:UpdateTeam()
        end
    end    
end,netCmd.CMD_SC_LEAVESEE)

--属性更新
RegNetHandler(function (packet)
    for key, value in pairs(packet.attr) do
        maincha.attr[key] = value
    end

    local scene = cc.Director:getInstance():getRunningScene()
    local hud = scene.hud
    local character = hud:getUI("UICharacter")
    if character then
        character:UpdateAttr()
        character:UpdatePoint()
    end
    
    local main = hud:getUI("UIMainLayer")
    if main then
        main:UpdateInfo()
    end
    
    if scene.class.__cname == "SceneGarden" then
        scene:UpdateInfo()
    end
end,netCmd.CMD_GC_ATTRUPDATE)

RegNetHandler(function (packet)
    --print("update maincha attr")
    local player = MgrPlayer[packet.id]
    for key, value in pairs(packet.attr) do
        player.attr[key] = value
    end
    player:SetLife(player.attr.life, player.attr.maxlife)
    if player.attr.life <= 0 then
        player:Death()
    end 
    if packet.id == maincha.id then
        local hud = cc.Director:getInstance():getRunningScene().hud
        local ui = hud:getUI("UIFightLayer")
        if ui then
            ui:UpdateLife()     
        end
    end
    --.attr = packet.attr
end,netCmd.CMD_SC_ATTRUPDATE)

local Pseudo = require "src.pseudoserver.pseudoserver"
RegNetHandler(function (packet)
    local scene = require("SceneLogin").create()
    cc.Director:getInstance():replaceScene(scene)
    scene:setOpenUI("UIMainLayer")
    MgrPlayer = {}
	Pseudo.DestroyMap()
end, netCmd.CMD_GC_BACK2MAIN)

RegNetHandler(function (packet)
    maincha.skill[packet.skillid].level = packet.lev
    local hud = cc.Director:getInstance():getRunningScene().hud
    local skill = hud:getUI("UISkillLayer")
    if skill then
        skill:UpdateSkillInfo()
        skill:UpdateSkill()
    end
end, netCmd.CMD_GC_SKILLUPDATE)

RegNetHandler(function (packet)
    if not maincha.skill then
        maincha.skill = {}
    end
    local skill = {}
    skill.id = packet.skillid
    skill.level = packet.lev
    maincha.skill[skill.id] = skill

    local hud = cc.Director:getInstance():getRunningScene().hud
    local skill = hud:getUI("UISkillLayer")
    if skill then
        skill:UpdateSkillInfo()
        skill:UpdateSkill()
    end
end, netCmd.CMD_GC_ADDSKILL)

RegNetHandler(function (packet) 
    MgrSign = packet
    local hud = cc.Director:getInstance():getRunningScene().hud
    local sign = hud:getUI("UISign")
    if sign then
        sign:UpdateSign()
    end
end,netCmd.CMD_GC_EVERYDAYSIGN)

RegNetHandler(function (packet) 
    MgrAchieve = packet

    local hud = cc.Director:getInstance():getRunningScene().hud
    for key, ui in pairs(hud.UIS) do
        if ui.onUpdateAchieve then
            ui:onUpdateAchieve()
        end
    end
end, netCmd.CMD_GC_ACHIEVE)

RegNetHandler(function (packet) 
    MgrFriend = {Friend = {}, Black = {}}
    for i=1, #packet do
        if packet[i].black then
            table.insert(MgrFriend.Black, packet[i])
        else
            table.insert(MgrFriend.Friend, packet[i])
        end
    end
    
    local hud = cc.Director:getInstance():getRunningScene().hud
    for key, ui in pairs(hud.UIS) do
        if ui.onFriendListUpdate then
            ui:onFriendListUpdate()
        end
    end
end, netCmd.CMD_GC_FRIEND_LIST)

RegNetHandler(function (packet) 

end, netCmd.CMD_GC_FRIEND_INFO)

RegNetHandler(function (packet)
    local avatar = MgrPlayer[packet.id]
    local mapPos = cc.WalkTo:tile2MapPos({x = packet.x, y = packet.y})
    if avatar then
        avatar:setPosition(mapPos)
    end
end, netCmd.CMD_SC_TRANSFERMOVE)

RegNetHandler(function (packet)
    local hud = require("UI.UIHudLayer").getHud()
    
    if string.len(packet.errmsg) > 0 then
        local UIMessage = require "UI.UIMessage"
        UIMessage.showMessage(packet.errmsg) 
    else
        local ui = hud:openUI("UIChooseItem")
        ui:createUI(packet.ticketRemain)
    end
end, netCmd.CMD_GC_SURVIVE_APPLY)

RegNetHandler(function (packet)
    if packet.success then
        local UIPopupGetItem = require "UI.UIPopupGetItem"
        UIPopupGetItem.showItems({packet.item})
    else
        print("error:choose failed")
    end
end, netCmd.CMD_GC_SURVIVE_CONFIRM)

RegNetHandler(function (packet)
    if packet.winner then
        local UIMessage = require "UI.UIMessage"
        UIMessage.showMessage("获胜者："..packet.winner) 
    end
end, netCmd.CMD_SC_SURVIVE_WIN)

RegNetHandler(function (packet)
    local hud = cc.Director:getInstance():getRunningScene().hud
    for key, ui in pairs(hud.UIS) do
        if ui.onMapBoom then
            ui:onMapBoom(packet.index, packet.timeremain)
        end
    end
end, netCmd.CMD_SC_BOOM)

RegNetHandler(function (packet)
    MgrMail = packet
    
    local hud = cc.Director:getInstance():getRunningScene().hud
    local mail = hud:getUI("UIMail")
    if mail then
        mail:UpdateMailList()
    end
end, netCmd.CMD_GC_MAILLIST)

RegNetHandler(function (packet)
    if packet.broadcast then
        table.insert(MgrChat.World, {sender = packet.sender, content = packet.str})
            if #MgrChat.World > 10 then
                table.remove(MgrChat.World, 1)
            end
    else
        table.insert(MgrChat.Private, {sender = packet.sender, content = packet.str})
        if #MgrChat.Private > 10 then
            table.remove(MgrChat.Private, 1)
        end
    end    

    local hud = cc.Director:getInstance():getRunningScene().hud
    for key, ui in pairs(hud.UIS) do
        if ui.onUpdateChat then
            ui:onUpdateChat()
        end
    end
end, netCmd.CMD_GC_CHAT)
