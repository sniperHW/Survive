local netCmd = require "src.net.NetCmd"
maincha = maincha or {}
MgrPlayer = MgrPlayer or {}
MgrSign = MgrSign or {} 
MgrSetting = MgrSetting or {bPlayMusic = true, bPlayEffect = true}

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
    table.sort(maincha.bag, compareItem)

    local hud = cc.Director:getInstance():getRunningScene().hud
    local bag = hud:getUI("UIBag")
    if bag then
        bag:UpdateBag()
        bag:UpdateEquip()
    end

    local equip = hud:getUI("UIEquip")
    if equip then
        equip:UpdateEquip()
        equip:UpdateUpgrade()
        equip:UpdateInlay()
        equip:UpdateStar()
    end
end, netCmd.CMD_GC_BAGUPDATE)

RegNetHandler(function (packet) 
    print("begin play")
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
    local hud = cc.Director:getInstance():getRunningScene().hud
    hud:closeUI("UILogin")
    hud:openUI("UIMainLayer")    
    
    BeginTime = {localtime = os.clock(), servertime = packet.server_timestamp} 
    if maincha.attr.fishing_start + maincha.attr.gather_start +
        maincha.attr.sit_start > 0 then        
        local scene = require("SceneLoading").create(205)
        cc.Director:getInstance():replaceScene(scene)
    end
    
    MgrSign = packet.everydaysign
end, netCmd.CMD_GC_BEGINPLY)

RegNetHandler(function (packet) 
    local hud = cc.Director:getInstance():getRunningScene().hud
    hud:closeUI("UILogin")
    hud:openUI("UICreatePlayer")
    end,netCmd.CMD_GC_CREATE)

RegNetHandler(function (packet)     
    maincha.attr = packet.attr
    maincha.id = packet.selfid
    print("----------enter map:"..maincha.id)
    
    local scene = require("SceneLoading").create(packet.maptype)
    local mapInfo = TableMap[packet.maptype]
    InitAstar("Scene/"..mapInfo.Colision)
    cc.Director:getInstance():replaceScene(scene)
end,netCmd.CMD_SC_ENTERMAP)

--移动失败
RegNetHandler(function (packet)
    print("move failed")
end,netCmd.CMD_SC_MOV_FAILED)

--移动成功
RegNetHandler(function (packet)
    local avatar = MgrPlayer[packet.id]
    local cx, cy = avatar:getPosition()
    if cx < 0 or cy < 0 then
        print("error position id = "..id.." posx,"..cx.." poxy,"..cy)
    end
    avatar:WalkTo({x = packet.x, y = packet.y})
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
    local rotation = player:getRotation3D()    
    player:retain()
    MgrPlayer[packet.id] = player
    local runningScene = cc.Director:getInstance():getRunningScene()
    if runningScene.class.__cname == "SceneCity" then
        runningScene.map:addChild(player)
        player:release()
        if packet.id == maincha.id then
            runningScene.localPlayer = player
        end
    end
    
    if packet.id == maincha.id then
        local weaponid = packet.weapon.id
        if weaponid > 5000 and weaponid < 5100 then
            MgrSkill.EquipedSkill = {1010, 1020, 1030, 1050, 1060}
            MgrSkill.BaseSkill = {11, 12, 13}
        elseif weaponid > 5100 and weaponid < 5200 then
            MgrSkill.EquipedSkill = {1110, 1120, 1130, 1140, 1150}
            MgrSkill.BaseSkill = {1511, 1512}
        end
    end
    
    if player.attr.life <= 0 then
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

    local hud = cc.Director:getInstance():getRunningScene().hud
    local character = hud:getUI("UICharacter")
    if character then
        character:UpdateAttr()
        character:UpdatePoint()
    end
    
    local main = hud:getUI("UIMainLayer")
    if main then
        main:UpdateInfo()
    end
    
end,netCmd.CMD_GC_ATTRUPDATE)

RegNetHandler(function (packet)
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
    local running = cc.Director:getInstance():getRunningScene()
    local scene = require("SceneLogin").create()
    cc.Director:getInstance():replaceScene(scene)
    scene.hud:closeUI("UILogin")
    scene.hud:openUI("UIMainLayer")
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