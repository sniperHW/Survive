local Name2idx = require "src.net.name2idx"
local netCmd = require "src.net.NetCmd"
local Pseudo = require "src.pseudoserver.pseudoserver"

local NetHandler = NetHandler or {}
function RegNetHandler(handle, cmd)
    NetHandler[cmd] = handle
end

local PseudoNetHandler = {}

local function SuperReg(func,cmd)
	RegHandler(func,cmd)
	PseudoNetHandler[cmd] = func
end

local function ReadAttr(rpk)
	local attr = {}
	local size = ReadUint8(rpk)
	--print(size)
	for i=1,size do
		local k = ReadUint8(rpk)
		local attrname = Name2idx.name(k)
		if attrname then
			attr[attrname] = ReadUint32(rpk)
			--print(attrname,attr[attrname])
		end
	end	
	return attr
end

local function ReadItem(rpk,bagpos)
	local item = {}
	item.id = ReadUint16(rpk)
	item.count = ReadUint16(rpk)
	item.bagpos = bagpos
	local attrsize = ReadUint8(rpk)
	if attrsize > 0 then
		item.attr = {}
		for j=1,attrsize do
			local idx = ReadUint8(rpk)
			item.attr[idx] = ReadUint32(rpk)
		end
	end
	return item
end

SuperReg(function (rpk)
	local packet = {}
	packet.bag = {}
	--背包位置
	local size = ReadUint8(rpk)
	for i=1,size do
		local idx = ReadUint8(rpk)
		--[[local item = {}
		item.id = ReadUint16(rpk)
		item.count = ReadUint16(rpk)
		item.bagpos = idx
		local attrsize = ReadUint8(rpk)
		if attrsize > 0 then
			item.attr = {}
			for j=1,attrsize do
				local idx = ReadUint8(rpk)
				item.attr[idx] = ReadUint32(rpk)
			end
		end]]--
		packet.bag[i] = ReadItem(rpk,idx)		
	end	
	NetHandler[netCmd.CMD_GC_BAGUPDATE](packet)
end,netCmd.CMD_GC_BAGUPDATE)

SuperReg(function (rpk)
	local packet = {}
	packet.uniqueid = ReadUint32(rpk)
	packet.avatarid = ReadUint16(rpk)
	packet.nickname = ReadString(rpk)
	--角色基本属性
	packet.attr = ReadAttr(rpk)
	--背包
	packet.bag = {}
	packet.bag.bagsize = ReadUint8(rpk)
	--背包位置
	local size = ReadUint8(rpk)
	for i=1,size do
		local bagpos = ReadUint8(rpk)
		--[[local item = {}
		item.id = ReadUint16(rpk)
		item.count = ReadUint16(rpk)
		item.bagpos = bagpos
		local attrsize = ReadUint8(rpk)
		if attrsize > 0 then
			item.attr = {}
			for j=1,attrsize do
				local idx = ReadUint8(rpk)
				item.attr[idx] = ReadUint32(rpk)
			end
		end]]--
		packet.bag[i] = ReadItem(rpk,bagpos)
	end	
	--技能
	packet.skill = {}
	size = ReadUint16(rpk)
	for i=1,size do
		local skill = {}
		skill.id = ReadUint16(rpk)
		skill.level = ReadUint8(rpk)
		packet.skill[skill.id] = skill
	end
	packet.everydaysign = {}
    	packet.everydaysign.daycount = ReadUint8(rpk)
    	packet.everydaysign.count = ReadUint8(rpk)
    	packet.everydaysign.signAble = ReadUint8(rpk)

	packet.server_timestamp = ReadUint32(rpk)	
	NetHandler[netCmd.CMD_GC_BEGINPLY](packet)
end,netCmd.CMD_GC_BEGINPLY)

SuperReg(function (rpk)
	local packet = {}
	packet.atkerid = ReadUint32(rpk)
	packet.skillid = ReadUint16(rpk)
	packet.success = ReadUint8(rpk)
	if packet.success == 1 then
		packet.point = {}
		packet.point.x = ReadUint16(rpk)
		packet.point.y = ReadUint16(rpk)
	elseif packet.success == 2 then
		packet.dir = ReadUint16(rpk)
	end
	NetHandler[netCmd.CMD_SC_NOTIATK](packet)
end,netCmd.CMD_SC_NOTIATK)

SuperReg(function (rpk)
	local packet = {}
	packet.atktime = ReadInt32(rpk)	
	packet.atkerid = ReadUint32(rpk)
	packet.suffererid = ReadUint32(rpk)
	packet.hpchange = ReadInt32(rpk)
	local tmp = ReadUint8(rpk)
	if tmp == 1 then
		packet.miss = true
	elseif tmp == 2 then
		packet.crit = true
	end
	packet.atktime = ReadInt32(rpk)
    NetHandler[netCmd.CMD_SC_NOTIATKSUFFER](packet)
end,netCmd.CMD_SC_NOTIATKSUFFER)

SuperReg(function (rpk)
	local packet = {}
	packet.atktime = ReadInt32(rpk)	
	packet.atker = ReadUint32(rpk)
	packet.skillid = ReadUint16(rpk)	
	packet.atkerpos = {}
	packet.atkerpos.x = ReadUint16(rpk)
	packet.atkerpos.y = ReadUint16(rpk)	
	packet.suffers = {}
	local size = ReadUint8(rpk)
	for i = 1,size do
		local suffer = {}
	        	suffer.id = ReadUint32(rpk)
	        	suffer.hpchange = ReadInt32(rpk)
	    	local tmp = ReadUint8(rpk)
	    	if tmp == 1 then
	    		packet.miss = true
	    	elseif tmp == 2 then
	    		packet.crit = true
	    	end	        	
		local pos = {}
		pos.x = ReadUint16(rpk)
		pos.y = ReadUint16(rpk)
	        	suffer.pos = pos
		packet.suffers[i] = suffer
	end
    	NetHandler[netCmd.CMD_SC_NOTIATKSUFFER2](packet)
end,netCmd.CMD_SC_NOTIATKSUFFER2)

SuperReg(function (rpk)
	--print("CMD_SC_NOTISUFFER")
	local packet = {}
	packet.atktime = ReadInt32(rpk)
	packet.atker = ReadUint32(rpk)	
	packet.skillid = ReadUint16(rpk)	
	packet.suffererid = ReadUint32(rpk)
	packet.hpchange = ReadInt32(rpk)
 	local tmp = ReadUint8(rpk)
	if tmp == 1 then
		packet.miss = true
	elseif tmp == 2 then
		packet.crit = true
	end   	
	packet.bRepel = ReadUint8(rpk)
	if packet.bRepel == 1 then
		packet.point = {}
		packet.point.x = ReadUint16(rpk)
		packet.point.y = ReadUint16(rpk)
	end
	--print("CMD_SC_NOTISUFFER2")
	NetHandler[netCmd.CMD_SC_NOTISUFFER](packet)
end,netCmd.CMD_SC_NOTISUFFER)

--通知创建角色
SuperReg(function (rpk)
    local packet = {}
    
    NetHandler[netCmd.CMD_GC_CREATE](packet)
end,netCmd.CMD_GC_CREATE)

SuperReg(function (rpk)
	--print("CMD_SC_ENTERMAP begin")
	local packet = {}
	packet.maptype = ReadUint16(rpk)	
	--属性
	packet.attr = ReadAttr(rpk)
	packet.battleitems = {}
	local size = ReadUint8(rpk)
	for i=1,size do
		local pos = ReadUint8(rpk)
		local item = {}
		item.id = ReadUint16(rpk)
		item.count = ReadUint16(rpk)
		--print(pos,item.id,item.count)
		packet.battleitems[pos] = item
	end
	packet.tick_remain = ReadUint32(rpk)		
	packet.selfid = ReadUint32(rpk)		
	--print("CMD_SC_ENTERMAP end")
	--print("CMD_SC_ENTERMAP",packet)
	
    NetHandler[netCmd.CMD_SC_ENTERMAP](packet)
end,netCmd.CMD_SC_ENTERMAP)

--移动失败
SuperReg(function (rpk)
    local packet = {}
    
    NetHandler[netCmd.CMD_SC_MOV_FAILED](packet)
end,netCmd.CMD_SC_MOV_FAILED)

SuperReg(function (rpk)
    local packet = {}
    packet.op = ReadUint8(rpk)
    NetHandler[netCmd.CMD_GC_NOTIOPSUCCESS](packet)
end,netCmd.CMD_GC_NOTIOPSUCCESS)

--移动成功
SuperReg(function (rpk)
	local packet = {}
	packet.id = ReadUint32(rpk)
	packet.speed = ReadUint16(rpk)	
	packet.x = ReadUint16(rpk)
	packet.y = ReadUint16(rpk)
    NetHandler[netCmd.CMD_SC_MOV](packet)
end,netCmd.CMD_SC_MOV)

SuperReg(function (rpk)
	local packet = {}
	packet.dir = ReadUint16(rpk)
    NetHandler[netCmd.CMD_SC_DIR](packet)
end,netCmd.CMD_SC_DIR)

--进入视野
SuperReg(function (rpk)
	--print("packet----------enter see hahah")
	local packet = {}
	packet.id = ReadUint32(rpk)
	packet.avattype = ReadUint8(rpk)
	packet.avatid = ReadUint16(rpk)
	packet.name = ReadString(rpk)
	packet.teamid = ReadUint16(rpk)
	packet.x = ReadUint16(rpk)
	packet.y = ReadUint16(rpk)
	packet.dir = ReadUint16(rpk)

	--属性
	packet.attr = ReadAttr(rpk)
	packet.fashion = ReadUint16(rpk)
	local weapon = {}
	weapon.id = ReadUint16(rpk)
	if weapon.id > 0 then
		weapon.count = ReadUint16(rpk)
		local attrsize = ReadUint8(rpk)
		if attrsize > 0 then
			weapon.attr = {}
			for j=1,attrsize do
				local idx = ReadUint8(rpk)
				weapon.attr[idx] = ReadUint32(rpk)
			end
		end
		packet.weapon = weapon
	end
	--print("packet----------enter see:"..packet.id)

    NetHandler[netCmd.CMD_SC_ENTERSEE](packet)	
end,netCmd.CMD_SC_ENTERSEE)

--离开视野
SuperReg(function (rpk)
	local packet = {}
	packet.id = ReadUint32(rpk)
	
    NetHandler[netCmd.CMD_SC_LEAVESEE](packet)
end,netCmd.CMD_SC_LEAVESEE)


--属性更新
SuperReg(function (rpk)
    local packet = {}
	packet.attr = ReadAttr(rpk)
    NetHandler[netCmd.CMD_GC_ATTRUPDATE](packet) 
end,netCmd.CMD_GC_ATTRUPDATE)

SuperReg(function (rpk)
    local packet = {}
	packet.id = ReadUint32(rpk)
	packet.attr = ReadAttr(rpk)	
    NetHandler[netCmd.CMD_SC_ATTRUPDATE](packet) 
end,netCmd.CMD_SC_ATTRUPDATE)

SuperReg(function (rpk)
	local packet = {}
	packet.id = ReadUint32(rpk)
	packet.buffid = ReadUint16(rpk)	
	NetHandler[netCmd.CMD_SC_BUFFBEGIN](packet)

end,netCmd.CMD_SC_BUFFBEGIN)

SuperReg(function (rpk)
	local packet = {}
	packet.id = ReadUint32(rpk)
	packet.buffid = ReadUint16(rpk)	
	NetHandler[netCmd.CMD_SC_BUFFEND](packet)
end,netCmd.CMD_SC_BUFFEND)

SuperReg(function (rpk)
	local packet = {}
	NetHandler[netCmd.CMD_GC_BACK2MAIN](packet)
	--UsePseudo = false
end, netCmd.CMD_GC_BACK2MAIN)

SuperReg(function (rpk)
	local packet = {}
	packet.maptype = ReadUint16(rpk)
	--UsePseudo = true
	NetHandler[netCmd.CMD_GC_ENTERPSMAP](packet)
end, netCmd.CMD_GC_ENTERPSMAP)

SuperReg(function (rpk)
    local packet = {}
    packet.start_time = ReadUint32(rpk)
    if packet.start_time then
    	packet.action = ReadUint8(rpk)
    end
    NetHandler[netCmd.CMD_GC_HOMEACTION_RET](packet)
end,netCmd.CMD_GC_HOMEACTION_RET)

SuperReg(function (rpk)
    local packet = {}
    packet.action = ReadUint8(rpk)
    packet.reward = ReadUint32(rpk)
    packet.reward_item = {0,0}
    packet.reward_item[1] = ReadUint16(rpk)
    packet.reward_item[2] = ReadUint32(rpk)
    NetHandler[netCmd.CMD_GC_HOMEBALANCE_RET](packet)
end,netCmd.CMD_GC_HOMEBALANCE_RET)

SuperReg(function (rpk)
    local packet = {}
    packet.skillid = ReadUint16(rpk)
    packet.lev = ReadUint8(rpk)
    NetHandler[netCmd.CMD_GC_SKILLUPDATE](packet)
end,netCmd.CMD_GC_SKILLUPDATE)	

SuperReg(function (rpk)
    local packet = {}
    packet.skillid = ReadUint16(rpk)
    packet.lev = ReadUint8(rpk)
    NetHandler[netCmd.CMD_GC_ADDSKILL](packet)
end,netCmd.CMD_GC_ADDSKILL)

SuperReg(function (rpk)
    local packet = {}
    packet.daycount = ReadUint8(rpk)
    packet.count = ReadUint8(rpk)
    packet.signAble = ReadUint8(rpk)
    --packet.skillid = ReadUint16(rpk)
    --packet.lev = ReadUint8(rpk)
    NetHandler[netCmd.CMD_GC_EVERYDAYSIGN](packet)
end,netCmd.CMD_GC_EVERYDAYSIGN)	

SuperReg(function (rpk)
    local packet = {}
    
    local count = 	ReadUint8(rpk)
    packet.tasks = {}
    for i=1,count do
    	packet.tasks[i] = {}
    	packet.tasks[i].count = ReadUint8(rpk)
    	packet.tasks[i].awarded =  ReadUint8(rpk)
    end
    NetHandler[netCmd.CMD_GC_EVERYDAYTASK](packet)
end,netCmd.CMD_GC_EVERYDAYTASK)	

SuperReg(function (rpk)
    local packet = {}
    packet.id = ReadUint8(rpk)
    NetHandler[netCmd.CMD_GC_EVERTDAYTASK_AWARD](packet)
end,netCmd.CMD_GC_EVERTDAYTASK_AWARD)	

SuperReg(function (rpk) 
    Pseudo.DestroyMap()	
    local scene = cc.Director:getInstance():getRunningScene()
    local hud = scene.hud
    local round = ReadUint16(rpk)
    local win = ReadString(rpk)

    if scene.class.__cname == "SceneGuidePVE" then
        local function clearMaincha() 
            scene.localPlayer = nil
            MgrPlayer[maincha.id]:removeFromParent()
            MgrPlayer[maincha.id] = nil  
        end            
            
		if win == "win" then
            local wpk = GetWPacket()
            WriteUint16(wpk,netCmd.CMD_CG_COMMIT_SPVE)
            WriteUint16(wpk, round)
            SendWPacket(wpk)
			if round == 1001 then
                Pseudo.BegPlay(1002)
                clearMaincha()
                scene.hud:closeUI("UINPCTalk")
                local ui = scene.hud:openUI("UINPCTalk")
                local function onEnd()
                    local fight = hud:getUI("UIFightLayer")
                    fight.nodeRightButtom:setVisible(true)                    
                    fight:createGuideSkill()
                end
                ui:ShowTalk(6, onEnd)
            elseif round == 1002 then
                local function onEnd()
                    local fight = hud:getUI("UIFightLayer")               
                    fight:createGuideJoyStick()
                end
                local ui = hud:openUI("UINPCTalk")
                ui:ShowTalk(7, onEnd)     
                Pseudo.BegPlay(1004)
                clearMaincha()
			elseif round == 1004 or round == 1003 then
			    CMD_COMMIT_INTRODUCE_STEP(MgrGuideStep)
                local ui = hud:openUI("UIPVEResult")
                local copy = TableSingle_Copy_Balance[round]
            	local awards = {{id = 4001, count = copy.Shell},
            		{id = 4004, count = copy.Experience}
            		}
            	if round == 1004 then
                    table.insert(awards, {id = 5301, count = 1})
            	end
                ui:Win(awards)
                local scheduleID = nil
                local function openPVE()
                    local scene = require("SceneLogin").create()
				    cc.Director:getInstance():replaceScene(scene)
				    scene:setOpenUI("UIMainLayer")
				    MgrPlayer = {}
                    local scheduler = cc.Director:getInstance():getScheduler()
                    scheduler:unscheduleScriptEntry(scheduleID)
                end
                local scheduler = cc.Director:getInstance():getScheduler()
                scheduleID = scheduler:scheduleScriptFunc(openPVE, 3, false)
			end
		else
            Pseudo.BegPlay(round)
		end		    
        return
    end    

    local ui = hud:openUI("UIPVEResult")
    if win == "win" then
    	local wpk = GetWPacket()
   	 	WriteUint16(wpk,netCmd.CMD_CG_COMMIT_SPVE)
    	WriteUint16(wpk, round)
    	SendWPacket(wpk)
    	maincha.attr.spve_today_max = round
    	scene.localPlayer = nil
    	MgrPlayer[maincha.id]:removeFromParent()
    	MgrPlayer[maincha.id] = nil            
        local copy = TableSingle_Copy_Balance[round]
        local awards = {{id = 4001, count = copy.Shell},
            {id = 4004, count = copy.Experience}
        }
        ui:Win(awards)
    else
        ui:Failed()
    end    
    
    local scheduleID = nil
    local function openPVE()
        --[[if MgrGuideStep == 19 then
            local scene = require("SceneLogin").create()
            cc.Director:getInstance():replaceScene(scene)
            scene:setOpenUI("UIMainLayer")
            MgrPlayer = {}
        else]]
            hud:closeUI("UIPVEResult")
            hud:openUI("UIPVE")
        --end
        local scheduler = cc.Director:getInstance():getScheduler()
        scheduler:unscheduleScriptEntry(scheduleID)
    end
    local scheduler = cc.Director:getInstance():getScheduler()
    scheduleID = scheduler:scheduleScriptFunc(openPVE, 3, false)
    
    --if MgrGuideStep == 19 then
     --   CMD_COMMIT_INTRODUCE_STEP(MgrGuideStep)
    --end
    
    for idx = 1, #scene.stars do
        scene.stars[idx]:removeFromParent()
    end
    scene.stars = {}
end, netCmd.CMD_CC_SPVE_RESULT)

SuperReg(function (rpk)
    local packet = {}
    local size = ReadUint16(rpk)
    for i = 1,size do
    	local achi = {}
    	achi.id = ReadUint16(rpk)
    	achi.achieved = ReadUint8(rpk) == 1
    	achi.awarded = ReadUint8(rpk) == 1
    	packet[achi.id] = achi
    end
    NetHandler[netCmd.CMD_GC_ACHIEVE](packet)
end,netCmd.CMD_GC_ACHIEVE)

SuperReg(function (rpk)
    local packet = {}
    packet.round = ReadUint16(rpk)
    NetHandler[netCmd.CMD_SC_NOTI_5PVE_ROUND](packet)
end,netCmd.CMD_SC_NOTI_5PVE_ROUND)

SuperReg(function (rpk)
    local packet = {}
    packet.round = ReadUint16(rpk)
    NetHandler[netCmd.CMD_SC_5PVE_RESULT](packet)
end,netCmd.CMD_SC_5PVE_RESULT)

SuperReg(function (rpk)
    local packet = {}
    local tmp = ReadUint8(rpk)
    if tmp == 1 then
    	packet.win = true
    else
    	packet.lose = true
    end
    NetHandler[netCmd.CMD_SC_5PVP_RESULT](packet)
end,netCmd.CMD_SC_5PVP_RESULT)

SuperReg(function (rpk)
   local packet = {}
   local size = ReadUint16(rpk)
   for i=1,size do
   	local v = {}
   	v.chaid = ReadUint32(rpk)
   	v.nickname = ReadString(rpk)
   	v.avatarid = ReadUint16(rpk)
   	v.level = ReadUint8(rpk)
   	v.black = ReadUint8(rpk) == 1
   	v.online = ReadUint8(rpk) == 1
   	table.insert(packet,v)
   end
   NetHandler[netCmd.CMD_GC_FRIEND_LIST](packet)
end,netCmd.CMD_GC_FRIEND_LIST)

SuperReg(function (rpk)
   local packet = {}
   packet.chaid = ReadUint32(rpk)
   packet.nickname = ReadString(rpk)
   packet.avatarid = ReadUint16(rpk)
   packet.attr = ReadAttr(rpk)
   packet.bag = {}
   --背包位置
   for i=1,4 do
       local idx = ReadUint8(rpk)
       --[[local item = {}
       item.id = ReadUint16(rpk)
       item.count = ReadUint16(rpk)
       item.bagpos = idx
       local attrsize = ReadUint8(rpk)
       if attrsize > 0 then
        	item.attr = {}
        	for j=1,attrsize do
        		local idx = ReadUint8(rpk)
        		item.attr[idx] = ReadUint32(rpk)
        	end
       end]]--
       packet.bag[i] = ReadItem(rpk,idx)			
   end    
   NetHandler[netCmd.CMD_GC_FRIEND_INFO](packet)
end,netCmd.CMD_GC_FRIEND_INFO)

SuperReg(function (rpk)
   local packet = {}
   packet.errmsg = ReadString(rpk)
   NetHandler[netCmd.CMD_GC_CREATE_ERROR](packet)
end,netCmd.CMD_GC_CREATE_ERROR)

SuperReg(function (rpk)
   local packet = {}
   packet.id = ReadUint32(rpk)	
   packet.x = ReadUint16(rpk)
   packet.y = ReadUint16(rpk)
   NetHandler[netCmd.CMD_SC_TRANSFERMOVE](packet)
end,netCmd.CMD_SC_TRANSFERMOVE)

SuperReg(function (rpk)
   local packet = {}
   NetHandler[netCmd.CMD_CC_PING](packet)
end,netCmd.CMD_CC_PING)

SuperReg(function (rpk)
   local packet = {}
   packet.errmsg = ReadString(rpk)
   packet.ticketRemain = ReadUint8(rpk)
   NetHandler[netCmd.CMD_GC_SURVIVE_APPLY](packet)
end,netCmd.CMD_GC_SURVIVE_APPLY)	

SuperReg(function (rpk)
   local packet = {}
   packet.success = ReadUint8(rpk) == 1
   if packet.success then
   	packet.item = ReadItem(rpk)
   	--packet.vipItem = ReadItem(rpk)
   end
   NetHandler[netCmd.CMD_GC_SURVIVE_CONFIRM](packet)
end,netCmd.CMD_GC_SURVIVE_CONFIRM)

SuperReg(function (rpk)
   local packet = {}
   local size = ReadUint8(rpk)
   for i = 1,size do
   	local item = {}
   	item.bagpos = ReadUint8(rpk)
   	item.id = ReadUint16(rpk)
   	item.count = ReadUint16(rpk)
   	table.insert(packet,item)
   end
   NetHandler[netCmd.CMD_SC_BAGUPDATE](packet)
end,netCmd.CMD_SC_BAGUPDATE)

SuperReg(function (rpk)
   local packet = {}
   packet.timeremain = ReadUint32(rpk)
   packet.index = ReadUint8(rpk)
   NetHandler[netCmd.CMD_SC_BOOM](packet)
end,netCmd.CMD_SC_BOOM)


SuperReg(function (rpk)
   local packet = {}
   packet.winner = ReadString(rpk)
   NetHandler[netCmd.CMD_SC_SURVIVE_WIN](packet)
end,netCmd.CMD_SC_SURVIVE_WIN)

SuperReg(function (rpk)
local packet = {}
packet.id = ReadUint32(rpk)
local weapon = {}
	weapon.id = ReadUint16(rpk)
	if weapon.id > 0 then
		weapon.count = ReadUint16(rpk)
		local attrsize = ReadUint8(rpk)
		if attrsize > 0 then
			weapon.attr = {}
			for j=1,attrsize do
				local idx = ReadUint8(rpk)
				weapon.attr[idx] = ReadUint32(rpk)
			end
		end
		packet.weapon = weapon
	end
	NetHandler[netCmd.CMD_SC_UPDATEWEAPON](packet)
end,netCmd.CMD_SC_UPDATEWEAPON)

SuperReg(function (rpk)
	local maillist = {}
	local size = ReadUint16(rpk)
	for i = 1,size do 
		local mail = {}
		mail.idx = ReadString(rpk)
		mail.title = ReadString(rpk)
		mail.content = ReadString(rpk)
		mail.readed = ReadUint8(rpk) == 1
		local attchsize  = ReadUint8(rpk)
		if attchsize > 0 then
			mail.attachments = {}
			for j = 1,attchsize do
				local attachment = {}
				attachment.id = ReadUint16(rpk)
				attachment.count = ReadUint16(rpk)
				table.insert(mail.attachments,attachment)
			end
		end
		table.insert(maillist, mail)
	end
	NetHandler[netCmd.CMD_GC_MAILLIST](maillist)
end,netCmd.CMD_GC_MAILLIST)	

SuperReg(function (rpk)
	local packet = {}
	packet.size = ReadUint16(rpk)
	NetHandler[netCmd.CMD_GC_NEWMAIL](packet)
end,netCmd.CMD_GC_NEWMAIL)

SuperReg(function (rpk)
	local packet = {}
	packet.broadcast = ReadUint8(rpk) == 1
	packet.sender = ReadString(rpk)
	packet.str = ReadString(rpk)
	NetHandler[netCmd.CMD_GC_CHAT](packet)
end,netCmd.CMD_GC_CHAT)





function OnPseudoServerPacket(rpk)
	local cmd = ReadUint16(rpk)
	local func = PseudoNetHandler[cmd]
	if func then
		func(rpk)
	end
end