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
    hud:openUI("UIChooseMap")
end, CMD_GC_BEGINPLY)

RegNetHandler(function (packet) 

    end,CMD_GC_CREATE)

RegNetHandler(function (packet)     
    maincha.id = packet.selfid
    maincha.attr = packet.attr
    maincha.id = packet.selfid
    InitAstar("Scene/fightMap.tmx")
    local scene = require("SceneLoading").create()
    cc.Director:getInstance():replaceScene(scene)
end,CMD_SC_ENTERMAP)

--移动失败
RegNetHandler(function (packet)
    print("move failed")
end,CMD_SC_MOV_FAILED)

--移动成功
RegNetHandler(function (packet)
    local avatar = MgrPlayer[packet.id]
    local cx, cy = avatar:getPosition()
    if cx < 0 or cy < 0 then
        print("error position id = "..id.." posx,"..cx.." poxy,"..cy)
    end
    avatar:WalkTo({x = packet.x, y = packet.y})
end,CMD_SC_MOV)

--进入视野
RegNetHandler(function (packet)
    local player = require("Avatar").create(packet.avatid)
    player.id = packet.id
    player.avatid = packet.avatid
    player.avattype = packet.avattype
    player.name = packet.name
    player.attr = packet.attr
    player:SetAvatarName(player.name)
    player:SetLife(player.attr.life, 100)
    player:setPosition(cc.WalkTo:tile2MapPos({x = packet.x, y = packet.y}))
    local rotation = player:getRotation3D()    
    --player:setRotation3D({x = rotation.x, y = packet.dir + 125, z = rotation.z})
    player:retain()
    MgrPlayer[packet.id] = player
    local runningScene = cc.Director:getInstance():getRunningScene()
    if runningScene.class.__cname == "SceneCity" then
        runningScene.map:addChild(player)
    end
    
    print("enter see"..player.name) 
    print(player.id)
    if packet.id == maincha.id then
        --player:addChild(icon)
    end
end,CMD_SC_ENTERSEE)

--离开视野
RegNetHandler(function (packet)
    MgrPlayer[packet.id]:removeFromParent()
    MgrPlayer[packet.id] = nil    
    print("leave see"..packet.id)
end,CMD_SC_LEAVESEE)

--属性更新
RegHandler(function (packet)
    maincha.attr = packet.attr
end,CMD_GC_ATTRUPDATE)

RegHandler(function (packet)
    MgrPlayer[packet.id].attr = packet.attr
end,CMD_SC_ATTRUPDATE)
