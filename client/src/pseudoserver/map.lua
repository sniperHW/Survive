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

local function CreateMonster(avatid,attr,skill,pos,dir,teamid)
	skill = skill or {11}
	map.idcounter = map.idcounter + 1
	local mon = Avatar.New(map.idcounter,avatid,map,"monster",attr,skill,pos,dir,teamid)
	map.avatars[mon.id] = mon
	map.mainCha:EnterSee(mon)
	mon.robot = Robot.New(mon,1):StartRun()
end

local function initMap()
	map = {}
	map.avatars = {}
	map.mapdef = {xcount = 180,ycount = 120}
	map.idcounter = 1
	map.mainCha = Avatar.New(map.idcounter,maincha.avatarid,map,
							 "haha",maincha.attr,nil,{60,60},2,1,maincha.fashion,
							 maincha.equip[2])
							 --{id = 5001,count=1,attr={0,0,0,0,0,0,0,0,0,0}})
	map.idcounter = map.idcounter + 1
	map.avatars[map.mainCha.id] = map.mainCha
	local wpk = GetWPacket()
	WriteUint16(wpk,NetCmd.CMD_SC_ENTERMAP)
	WriteUint16(wpk,202)
	map.mainCha.attr:pack(wpk)
	map.mainCha.battleitems:on_entermap(wpk)
	WriteUint32(wpk,map.mainCha.id)
	Send2Client(wpk)
	map.mainCha:EnterSee(map.mainCha)
	map.round = 0
	map.recycles = {}
	map.monster_size = 0

	map.GetAvatar = function (self,id)
		return map.avatars[id]
	end

	map.OnDead = function (self,avatar)
		if avatar ~= self.mainCha then
			print("Monster Dead")
			table.insert(self.recycles,{avatar,Time.SysTick() + 5000})
			self.avatars[avatar.id] = nil
		end
	end

	map.StartRound = function (self)
		local position = {{120,80},{120,60},{120,70},{120,100}}
		local monsterid = {101,102,103,104}
		if self.monster_size == 0 then
			if self.mainCha then
				self.mainCha.attr:Set("life",self.mainCha.attr:Get("maxlife"))
				self.mainCha.attr:NotifyUpdate()
			end
			self.round = self.round + 1
			print("round",self.round)
			for i=1,3 do
				mon_attr["attack"] = TableSingle_Copy[self.round]["Attack" .. i]
				mon_attr["defencse"] = TableSingle_Copy[self.round]["Defense" .. i]
				print("mondef",mon_attr["defencse"])
				mon_attr["maxlife"] = TableSingle_Copy[self.round]["Life" .. i]
				CreateMonster(monsterid[i],mon_attr,nil,position[i],2,0)	
			end
			self.monster_size = 3
		end	
	end

	map.Tick = function (self)
		local tick = Time.SysTick()
		for k,v in pairs(self.recycles) do
			if tick >= v[2] then
				if self.mainCha then
					self.mainCha:LeaveSee(v[1])
				end
				self.monster_size = self.monster_size - 1
				self.recycles[k] = nil
			end
		end
		if self.monster_size == 0 then
			self:StartRound()
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
	if map then
		for k,v in pairs(map.avatars) do
			v:Tick(Time.SysTick())
		end
		map:Tick()
	end
end

local function ProcessPacket(rpk)
	local cmd = ReadUint16(rpk)
	if cmd == NetCmd.CMD_CG_ENTERMAP then
		if not map then
			initMap()
		end
	elseif map then
		if cmd == NetCmd.CMD_CG_LEAVEMAP then
			CMD_PMAP_BALANCE(202)
		elseif map.mainCha then
			if map.mainCha:isDead() then
				return
			end
			map.mainCha:ProcessPacket(cmd,rpk)
		end
	end
end

return {
	Tick = Tick,
	ProcessPacket = ProcessPacket,
	DestroyMap = DestroyMap,
}