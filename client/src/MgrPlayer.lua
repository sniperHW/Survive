local netCmd = require "src.net.NetCmd"
maincha = maincha or {}
MgrPlayer = MgrPlayer or {}

RegNetHandler(function (packet) 
    maincha.avatarid = packet.avatarid
    maincha.nickname = packet.nickname
    maincha.attr = packet.attr
    maincha.bag = packet.bag
    maincha.skill = packet.skill
    
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
    print("----------enter map:"..maincha.id)
    InitAstar("Scene/fightMap.tmx")
    local scene = require("SceneLoading").create()
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
    local player = require("Avatar").create(packet.avatid)
    print("enter see avatid 1")
    player.id = packet.id
    print("enter see avatid 2")
    player.avatid = packet.avatid
    print("enter see avatid 3")
    player.avattype = packet.avattype
    print("enter see avatid 4")
    player.name = packet.name
    print("enter see avatid 5")
    print("enter see avatid name:"..player.name)
    player.attr = packet.attr
    print("enter see avatid 6")
    player:SetAvatarName(player.name)
    print("enter see avatid 7")
    print(player.attr.life)
    print(player.attr.maxlife)
    --player:SetLife(player.attr.life, player.attr.maxlife)
    print("enter see avatid 8")
    player:setPosition(cc.WalkTo:tile2MapPos({x = packet.x, y = packet.y}))
    print("enter see avatid 9")
    local rotation = player:getRotation3D()    
    --player:setRotation3D({x = rotation.x, y = packet.dir + 125, z = rotation.z})
    player:retain()
    MgrPlayer[packet.id] = player
    print("add player in scene:")
    print(MgrPlayer[packet.id])
    local runningScene = cc.Director:getInstance():getRunningScene()
    print("add player in scene:"..runningScene.class.__cname)
    if runningScene.class.__cname == "SceneCity" then
        runningScene.map:addChild(player)
    end
    
    if packet.id == maincha.id then
        --player:addChild(icon)
    end
end,netCmd.CMD_SC_ENTERSEE)

--离开视野
RegNetHandler(function (packet)
    MgrPlayer[packet.id]:release()
    MgrPlayer[packet.id]:removeFromParent()
    MgrPlayer[packet.id] = nil    
    print("leave see"..packet.id)
end,netCmd.CMD_SC_LEAVESEE)

--属性更新
RegHandler(function (packet)
    --maincha.attr = packet.attr
end,netCmd.CMD_GC_ATTRUPDATE)

RegHandler(function (packet)
    --MgrPlayer[packet.id].attr = packet.attr
end,netCmd.CMD_SC_ATTRUPDATE)
