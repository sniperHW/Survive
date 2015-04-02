local Time = require "src.pseudoserver.time"
local Timer = require "src.pseudoserver.timer"
local Sche = require "src.pseudoserver.sche"
local NetCmd = require "src.net.NetCmd"
local Avatar = require "src.pseudoserver.avatar"
local Name2idx = require "src.net.name2idx"
local Robot = require "src.pseudoserver.robot"

require "src.table.TableMap"
require "src.table.TableSkill"
require "src.table.TableSingle_Copy"

local map = nil
local gridpixel = 8
function Pixel2Grid(pixel)
	return math.floor(pixel/gridpixel)
end

local mon_attr={
	["level"] = 1,
	["exp"] = 0,
	["power"] = 0,
	["endurance"] = 0,
	["constitution"] = 0,
	["agile"] = 0,
	["lucky"] = 0,
	["accurate"] = 0,
	["movement_speed"] = 0,
	["shell"] = 0,
	["pearl"] = 0,
	["soul"] = 0,
	["action_force"] = 0,
	
	["attack"] = 0,
	["defencse"] = 0,
	["maxlife"] = 0,			
	["dodge"] = 0,
	["crit"] = 0,
	["hit"] = 0,
	["anger"] = 0,
	["combat_power"] = 0,
}

local function CreateMonster(avatid,attr,skill,pos,dir,teamid,startRobot)
	skill = skill or {11}
	map.idcounter = map.idcounter + 1
	local mon = Avatar.New(map.idcounter,avatid,map,"",attr,skill,pos,dir,teamid)
	map.avatars[mon.id] = mon
	map.mainCha:EnterSee(mon)
	if startRobot then
		mon.robot = Robot.New(mon,1):StartRun()
	end
end

local function InitMap(round)
	map = {}
	map.avatars = {}
	map.mapdef = {xcount = 180,ycount = 120}
	map.idcounter = 1
	local battleitems = {}
	for i=5,10 do
		if maincha.equip[i] and maincha.equip[i].count > 0 then
            table.insert(battleitems, {i,maincha.equip[i].id,maincha.equip[i].count})
		end
	end
	
	local pos = {30, 60}
	local dir = 2 
	
	if round > 1000 and MgrPlayer[maincha.id] then
        local player = MgrPlayer[maincha.id] 
        local mapPosX, mapPosY = player:getPosition()
        local tilePos = cc.WalkTo:map2TilePos(cc.p(mapPosX, mapPosY))
        pos = {tilePos.x, tilePos.y}
        dir = player:GetAvatar3D():getRotation3D().y - 90
	end
	
	map.mainCha = Avatar.New(map.idcounter,maincha.avatarid,map,
							 maincha.nickname,maincha.attr,nil,pos,dir,1,maincha.fashion,
							 maincha.equip[2],battleitems)
							 --{id = 5001,count=1,attr={0,0,0,0,0,0,0,0,0,0}})
	map.idcounter = map.idcounter + 1
	map.avatars[map.mainCha.id] = map.mainCha
	local wpk = GetWPacket()
	WriteUint16(wpk,NetCmd.CMD_SC_ENTERMAP)
	WriteUint16(wpk,202)
	map.mainCha.attr:pack(wpk)
	map.mainCha.battleitems:on_entermap(wpk)
	WriteUint32(wpk,0)
	WriteUint32(wpk,map.mainCha.id)
	Send2Client(wpk)
	map.mainCha:EnterSee(map.mainCha)
	map.round = round
	map.recycles = {}
	map.monster_size = 0

	map.GetAvatar = function (self,id)
		return map.avatars[id]
	end

	map.OnDead = function (map,avatar)
		if avatar ~= map.mainCha then
			print("Monster Dead")
			table.insert(map.recycles,{avatar,Time.SysTick() + 5000})
			map.avatars[avatar.id] = nil
		else
			map.mainCha = nil
		end
	end
    
    
	local position = nil
	if round < 1000 then
	   position = {{120,80},{120,60},{120,70},{140,80},{140,65}}
    else
       position = {{80,50},{80,40},{80,60},{140,80},{140,65}}
    end
	--local monsterid = {101,102,103,104}
	--local monskill = {{3020},{3010},{3040},{3030}}
	map.monster_size = 0
	for i=1,5 do
		local monid  = TableSingle_Copy[round]["Monster" .. i .. "_ID"]
		if monid then
			map.monster_size = map.monster_size + 1
			mon_attr["attack"] = TableSingle_Copy[round]["Attack" .. i]
			mon_attr["defencse"] = TableSingle_Copy[round]["Defense" .. i]
			mon_attr["maxlife"] = TableSingle_Copy[round]["Life" .. i]
			local startRobot
			if round < 1000 or round == 1003 then
				startRobot = true
			end	
			CreateMonster(monid,mon_attr,nil,position[i],2,0,startRobot)
		end	
	end
	

	map.Tick = function (map)
		if map.finish then
			return
		end
		if not map.mainCha then
			map.finish = true
			local wpk = GetWPacket()
			WriteUint16(wpk,NetCmd.CMD_CC_SPVE_RESULT)
			WriteUint16(wpk,map.round)
			WriteString(wpk,"lose")
			Send2Client(wpk)
			return
		end
		local tick = Time.SysTick()
		for k,v in pairs(map.recycles) do
			if tick >= v[2] then
				if map.mainCha then
					map.mainCha:LeaveSee(v[1])
				end
				map.monster_size = map.monster_size - 1
				map.recycles[k] = nil
			end
		end

		if map.monster_size == 0 then
			map.finish = true
			local wpk = GetWPacket()
			WriteUint16(wpk,NetCmd.CMD_CC_SPVE_RESULT)
			WriteUint16(wpk,map.round)
			WriteString(wpk,"win")
			Send2Client(wpk)
		end
	end
end

local function DestroyMap()
	if map then
		for k,v in pairs(map.avatars) do
			if v.robot then
				v.robot:Stop()
				v.robot = nil
			end
			v:StopMov()
		end
		map = nil
	end	
end

local function Tick()
	if map and map.Tick then
		for k,v in pairs(map.avatars) do
			v:Tick(Time.SysTick())
		end
		map:Tick()
	end
end

local function ProcessPacket(rpk)
	local cmd = ReadUint16(rpk)
	if map and map.mainCha then
		if map.mainCha:isDead() then
			return
		end
		map.mainCha:ProcessPacket(cmd,rpk)
	end
end

return {
	Tick = Tick,
	ProcessPacket = ProcessPacket,
	DestroyMap = DestroyMap,
	InitMap = InitMap,
}