-- process concrete map logic
package.cpath = "Survive/?.so"
local Avatar = require "Survive.gameserver.avatar"
local Player = require "Survive.gameserver.gameplayer"
local LinkQue = require "lua.linkque"
local Cjson = require "cjson"
local Gate = require "Survive.gameserver.gate"
local Attr = require "Survive.gameserver.attr"
local Skill = require "Survive.gameserver.skill"
local Aoi = require "aoi"
local Astar = require "astar"
local NetCmd = require "Survive.netcmd.netcmd"
local IdMgr = require "Survive.common.idmgr"
local Sche = require "lua.sche"
local Robot = require "Survive.gameserver.robot"
local Name2idx = require "Survive.common.name2idx"

--the general map logic

local maplogic = {}

function maplogic:new()
	local o = {}		   
	setmetatable(o, self)
	self.__index = self 
	return o
end

function maplogic:Init(map)
	self.avatars = {}
	self.map = map
	self.freeidx = IdMgr.New(4096)
	self.plycount = 0  
	self.recycle = {}
	map.avatars = self.avatars
	return self
end

function maplogic:GetAvatar(id)
	return self.avatars[id]
end

function maplogic:leavemap(id)
	local ply = self:GetAvatar(id)
	if ply then
		ply:Release()
		self.plycount = self.plycount - 1
		self.avatars[id] = nil
		if self.plycount == 0 then
			self.map:Release()
		end
		return true
	end
	return false
end

function maplogic:OnClientDisconnect(ply)
	if not ply.robot then
		ply.robot = Robot.New(ply,1)
	end
	ply.robot:StartRun()
end

function maplogic:entermap(plys)
	if self.freeidx:Len() < #plys then
		log_gameserver:Log(CLog.LOG_INFO,"maplogic:entermap not enough free id")
		return nil
	else
		local gameids = {}
		local size = #plys
		local map = self.map
		for i=1,size do
			local v = plys[i]
			local avatid = v.avatid
			
			local gate = nil
			if v.gatesession then
				gate = Gate.GetGateByName(v.gatesession.name)
			end
			local id = self.freeidx:Get()
			--id,avatid,map,nickname,actname,groupsession,attr,skillmgr,pos,dir,teamid
			local ply = Player.New(bit32.lshift(map.mapid,16) + id,avatid,
					             map,v.nickname,
					             v.actname,v.groupsession,
					             v.attr,Skill.New(v.skills),{60,60},5,nil,v.battleitem)
			ply.fashion = v.fashion
			ply.weapon = v.weapon
			if gate then 
				Gate.Bind(gate,ply,v.gatesession.id)
			end
			self.avatars[ply.id] = ply
			table.insert(gameids,ply.id)
			ply:on_entermap()	
			self.plycount = self.plycount + 1
			Aoi.enter_map(map.aoi,ply.aoi_obj,ply.pos[1],ply.pos[2])
			log_gameserver:Log(CLog.LOG_INFO,ply.actname .. " enter map id:" .. ply.id)
		end 
		return gameids
	end
end

function maplogic:OnAvatarDead(avatar,atker,skillid)
end

local function CreateNPC(logic,avatid,nickname,weapon,attr,skills,pos,dir,teamid,aiid,runAi)
	local id = logic.freeidx:Get()
	if not id then
		return nil
	end
	id = bit32.lshift(logic.map.mapid,16) + id
	local npc = Avatar.New(id,avatid,logic.map,nickname,attr,Skill.New(skills),pos,dir,teamid)
	if weapon then
		npc.weapon = weapon
	end
	logic.avatars[id] = npc
	Aoi.enter_map(logic.map.aoi,npc.aoi_obj,pos[1],pos[2])
	npc.robot = Robot.New(npc,aiid)--:StartRun()
	if runAi then
		npc.robot:StartRun()
	end
	return npc	
end

--maplogic of 5 pve
local FiveVE = maplogic:new()

function FiveVE:new()
	local o = {}		
	setmetatable(o, self)
    	self.__index = self
    	o.recycle = {} 		
	return o	
end

function FiveVE:entermap(plys)
	if self.freeidx:Len() < #plys then
		log_gameserver:Log(CLog.LOG_INFO,"FiveVE:entermap not enough free id")
		return nil
	else
		local gameids = {}
		local size = #plys
		local map = self.map
		for i=1,size do
			local v = plys[i]
			local avatid = v.avatid
			
			local gate = nil
			if v.gatesession then
				gate = Gate.GetGateByName(v.gatesession.name)
			end
			local id = self.freeidx:Get()
			--id,avatid,map,nickname,actname,groupsession,attr,skillmgr,pos,dir,teamid
			local ply = Player.New(bit32.lshift(map.mapid,16) + id,avatid,
					             map,v.nickname,
					             v.actname,v.groupsession,
					             v.attr,Skill.New(v.skills),{60,60},5,1,v.battleitem)
			ply.fashion = v.fashion
			ply.weapon = v.weapon
			ply.isPlayer = true
			if gate then 
				Gate.Bind(gate,ply,v.gatesession.id)
			end
			self.avatars[ply.id] = ply
			table.insert(gameids,ply.id)
			ply:on_entermap()	
			self.plycount = self.plycount + 1
			Aoi.enter_map(map.aoi,ply.aoi_obj,ply.pos[1],ply.pos[2])
			log_gameserver:Log(CLog.LOG_INFO,ply.actname .. " enter map id:" .. ply.id)
		end

		if self.plycount < 5 then
			local robotPos = {{65,65},{60,65},{65,60},{70,70}}
			local skills = {{1030,1},{1040,1},{11,1},{1020,1}}
			local attr={
				[Name2idx.Idx("level")] = 1,
				[Name2idx.Idx("exp")] = 0,
				[Name2idx.Idx("power")] = 0,
				[Name2idx.Idx("endurance")] = 0,
				[Name2idx.Idx("constitution")] = 0,
				[Name2idx.Idx("agile")] = 0,
				[Name2idx.Idx("lucky")] = 0,
				[Name2idx.Idx("accurate")] = 0,
				[Name2idx.Idx("movement_speed")] = 0,
				[Name2idx.Idx("shell")] = 0,
				[Name2idx.Idx("pearl")] = 0,
				[Name2idx.Idx("soul")] = 0,
				[Name2idx.Idx("action_force")] = 0,
				
				[Name2idx.Idx("attack")] = 50,
				[Name2idx.Idx("defencse")] = 20,
				[Name2idx.Idx("maxlife")] = 1000,			
				[Name2idx.Idx("dodge")] = 0,
				[Name2idx.Idx("crit")] = 0,
				[Name2idx.Idx("hit")] = 0,
				[Name2idx.Idx("anger")] = 0,
				[Name2idx.Idx("combat_power")] = 0,
			}			
			--not enough player,create robot player
			local robotcount = 5 - self.plycount
			for i=1,robotcount do 
				local robotPly = CreateNPC(self,math.random(1,4),"robot", {id=5001,count=1,attr = {0,0,0,0,0,0,0,0,0,0}},attr,skills,robotPos[i],5,1,2,true)
				if robotPly then 
					robotPly.isNPC = true 
				end
			end	
		end
		self.monster_count  = 0
		self.Round = 0
		return gameids
	end
end

function FiveVE:StartRound()
	local skills = {{11,1}}
	local attr={
		[Name2idx.Idx("level")] = 1,
		[Name2idx.Idx("exp")] = 0,
		[Name2idx.Idx("power")] = 0,
		[Name2idx.Idx("endurance")] = 0,
		[Name2idx.Idx("constitution")] = 0,
		[Name2idx.Idx("agile")] = 0,
		[Name2idx.Idx("lucky")] = 0,
		[Name2idx.Idx("accurate")] = 0,
		[Name2idx.Idx("movement_speed")] = 0,
		[Name2idx.Idx("shell")] = 0,
		[Name2idx.Idx("pearl")] = 0,
		[Name2idx.Idx("soul")] = 0,
		[Name2idx.Idx("action_force")] = 0,
		
		[Name2idx.Idx("attack")] = 10,
		[Name2idx.Idx("defencse")] = 10,
		[Name2idx.Idx("maxlife")] = 500,			
		[Name2idx.Idx("dodge")] = 0,
		[Name2idx.Idx("crit")] = 0,
		[Name2idx.Idx("hit")] = 0,
		[Name2idx.Idx("anger")] = 0,
		[Name2idx.Idx("combat_power")] = 0,
	}	
	self.Round = self.Round + 1

	local monPos = {{150,60},{150,70},{150,80},{150,90},{150,100}}
	local monid = {101,102,103,104,104}
	for i = 1,5 do
		--logic,avatid,nickname,attr,skills,pos,dir,teamid,aiid
		local mon = CreateNPC(self,monid[i],"",nil,attr,skills,monPos[i],5,0,1,true)
		if mon then 
			self.monster_count = self.monster_count + 1
			mon.isMon = true 
		end
	end
end

function FiveVE:Tick(tick)
	if self.monster_count == 0 then
		self:StartRound()
	end
	for k,v in pairs(self.recycle) do
		if tick >= v[2] then
			if v[1].isMon then
				self.monster_count  = self.monster_count - 1
			end
			v[1]:Release()
			self.recycle[k] = nil
		end
	end
end

function FiveVE:OnAvatarDead(avatar,atker,skillid)
	if not avatar.isPlayer then
		table.insert(self.recycle,{avatar,C.GetSysTick() + 2000})
	else

	end
end

--maplogic of 5 pvp

local FiveVP = maplogic:new()

function FiveVP:new()
	local o = {}		
	setmetatable(o, self)
    	self.__index = self
    	o.recycle = {} 		
	return o	
end

function FiveVP:entermap(plys)
	if self.freeidx:Len() < #plys then
		log_gameserver:Log(CLog.LOG_INFO,"FiveVP:entermap not enough free id")
		return nil
	else

		local initpos = {[1] = {
				         {138,130},
			           	         {137,120},
				         {134,154},
				         {135,165},
				         {133,180}},
			             [2] = {	         	
			           	         {153,157},
			           	         {153,138},
			                       {165,143},
			                       {150,120},
			                       {147,130},
			                       }}
	              local teamidx = {[1] = 1,[2] = 1}		                       
		local gameids = {}
		local size = #plys
		local map = self.map
		local teamid = 1
		for i=1,size do
			local v = plys[i]
			local avatid = v.avatid
			
			local gate = nil
			if v.gatesession then
				gate = Gate.GetGateByName(v.gatesession.name)
			end
			local id = self.freeidx:Get()
			--id,avatid,map,nickname,actname,groupsession,attr,skillmgr,pos,dir,teamid
			local ply = Player.New(bit32.lshift(map.mapid,16) + id,avatid,
					             map,v.nickname,
					             v.actname,v.groupsession,
					             v.attr,Skill.New(v.skills),initpos[teamid][teamidx[teamid]],5,teamid,v.battleitem)
			if teamid == 1 then
				teamidx[1] = teamidx[1] + 1
				teamid = 2
			else
				teamidx[2] = teamidx[2] + 1
				teamid = 1
			end
			ply.fashion = v.fashion
			ply.weapon = v.weapon
			ply.isPlayer = true
			if gate then 
				Gate.Bind(gate,ply,v.gatesession.id)
			end
			self.avatars[ply.id] = ply
			table.insert(gameids,ply.id)
			ply:on_entermap()	
			self.plycount = self.plycount + 1
			Aoi.enter_map(map.aoi,ply.aoi_obj,ply.pos[1],ply.pos[2])
			log_gameserver:Log(CLog.LOG_INFO,ply.actname .. " enter map id:" .. ply.id)
		end

		if self.plycount < 10 then
			--local robotPos = {{65,65},{60,65},{65,60},{70,70}}
			local skills = {{1030,1},{1040,1},{11,1},{1020,1}}
			local attr={
				[Name2idx.Idx("level")] = 1,
				[Name2idx.Idx("exp")] = 0,
				[Name2idx.Idx("power")] = 0,
				[Name2idx.Idx("endurance")] = 0,
				[Name2idx.Idx("constitution")] = 0,
				[Name2idx.Idx("agile")] = 0,
				[Name2idx.Idx("lucky")] = 0,
				[Name2idx.Idx("accurate")] = 0,
				[Name2idx.Idx("movement_speed")] = 0,
				[Name2idx.Idx("shell")] = 0,
				[Name2idx.Idx("pearl")] = 0,
				[Name2idx.Idx("soul")] = 0,
				[Name2idx.Idx("action_force")] = 0,
				
				[Name2idx.Idx("attack")] = 50,
				[Name2idx.Idx("defencse")] = 20,
				[Name2idx.Idx("maxlife")] = 1000,			
				[Name2idx.Idx("dodge")] = 0,
				[Name2idx.Idx("crit")] = 0,
				[Name2idx.Idx("hit")] = 0,
				[Name2idx.Idx("anger")] = 0,
				[Name2idx.Idx("combat_power")] = 0,
			}			
			--not enough player,create robot player
			local robotcount = 10 - self.plycount
			for i=1,robotcount do 		
				local robotPly = CreateNPC(self,math.random(1,4),"robot", {id=5001,count=1,attr = {0,0,0,0,0,0,0,0,0,0}},attr,skills,initpos[teamid][teamidx[teamid]],5,teamid,1)
				if teamid == 1 then
					teamidx[1] = teamidx[1] + 1
					teamid = 2
				else
					teamidx[2] = teamidx[2] + 1
					teamid = 1
				end					
				if robotPly then 
					robotPly.isNPC = true 
				end
			end
			self.start_time = os.time() + 10
			self.isFinish = false	
		end
		return gameids
	end
end

function FiveVP:Tick(tick)
	if self.start_time  then
		local now = os.time()
		if now > self.start_time then
			for k,v in pairs(self.avatars) do
				if v.isNPC and v.robot then
					v.robot:StartRun()
				end
			end
			self.start_time = nil
		end
	end 

	if not self.isFinish then
		local team_alive_count = {[1] = 0,[2] = 0}
		for k,v in pairs(self.avatars) do
			if not v:isDead() then
				team_alive_count[v.teamid] = team_alive_count[v.teamid] + 1
			end
		end

		if team_alive_count[1] == 0 or team_alive_count[2] == 0 then
			if team_alive_count[1] == 0 then
				print("game finish team 2 win")
			else
				print("game finish team 1 win")
			end
			self.isFinish = true
		end
	end
end

function FiveVP:OnAvatarDead(avatar,atker,skillid)
	--[[if not avatar.isPlayer then
		table.insert(self.recycle,{avatar,C.GetSysTick() + 2000})
	else
	end]]--
end

return {
	New = function (map) 
			local logicname = map.mapdef["PlayType"]
			if logicname == "open" then
				return maplogic:new():Init(map)
			elseif map.maptype == 203 then
				return FiveVE:new():Init(map)
			elseif map.maptype == 204 then
				return FiveVP:new():Init(map)
			else
				return nil
			end
	             end
}


