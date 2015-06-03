-- process concrete map logic
package.cpath = "./?.so"
local Avatar = require "gameserver.avatar"
local Player = require "gameserver.gameplayer"
local LinkQue = require "lua.linkque"
local Cjson = require "cjson"
local Gate = require "gameserver.gate"
local Attr = require "gameserver.attr"
local Skill = require "gameserver.skill"
local Aoi = require "aoi"
local Astar = require "astar"
local NetCmd = require "netcmd.netcmd"
local IdMgr = require "common.idmgr"
local Sche = require "lua.sche"
local Robot = require "gameserver.robot"
local Name2idx = require "common.name2idx"
local Trigger = require "gameserver.areatrigger"
local Snali = require "gameserver.snail"
require "common.TableTower_Coefficient"
require "common.TableTower_Defense"
require "common.TableFixed_Attribute"
--require "common.TableScene_Pond"

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

function maplogic:OnEnterMap(wpk)
	--print("OnEnterMap",self.start_tick)
	if not self.start_tick then
		wpk:Write_uint32(0)
	else
		local now = C.GetSysTick()
		if now < self.start_tick then
			wpk:Write_uint32(self.start_tick - now)
		else
			wpk:Write_uint32(0)
		end
	end
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
		--if not self.trigger then
		--	Trigger.New(self.freeidx:Get(),self.map,1,{159,66})
		--end  
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

local function CreateDrop(logic,avatid,pos)
	--print("CreateDrop",avatid)
	local id = logic.freeidx:Get()
	if not id then
		return nil
	end
	id = bit32.lshift(logic.map.mapid,16) + id
	local drop = Avatar.New(id,avatid,logic.map,"",{},nil,pos,1,0)
	Aoi.enter_map(logic.map.aoi,drop.aoi_obj,pos[1],pos[2])
	drop.Pickable = true
	logic.avatars[id] = drop
	return drop
end

--maplogic of 5 pve
local FiveVE = maplogic:new()

function FiveVE:new()
	local o = {}		
	setmetatable(o, self)
    	self.__index = self		
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
		local ava_level
		local base_attr
		self.start_tick = C.GetSysTick() + 10000
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
			if not base_attr then
				base_attr = v.attr
			end
			ply.fashion = v.fashion
			ply.weapon = v.weapon
			ply.isPlayer = true
			if gate then 
				Gate.Bind(gate,ply,v.gatesession.id)
			end

			if not ava_level then
				ava_level = ply.attr:Get("level")
			else
				ava_level = math.floor((ply.attr:Get("level") + ava_level)/2)
			end

			self.avatars[ply.id] = ply
			table.insert(gameids,ply.id)
			ply:on_entermap()	
			self.plycount = self.plycount + 1
			Aoi.enter_map(map.aoi,ply.aoi_obj,ply.pos[1],ply.pos[2])
			log_gameserver:Log(CLog.LOG_INFO,ply.actname .. " enter map id:" .. ply.id)
		end
		self.ava_level = ava_level
		if self.plycount < 5 then
			local robotPos = {{65,65},{60,65},{65,60},{70,70}}
			local skills = {{1030,1},{1040,1},{11,1},{1020,1}}		
			--not enough player,create robot player
			local robotcount = 5 - self.plycount
			for i=1,robotcount do 
				local robotPly = CreateNPC(self,math.random(1,4),"robot", {id=5001,count=1,attr = {0,0,0,0,0,0,0,0,0,0}},base_attr,skills,robotPos[i],5,1,2)
				if robotPly then 
					robotPly.isNPC = true 
				end
			end	
		end
		self.monster_count  = 0
		self.live_ply_count = 5
		self.Round = 0
		--for k,v in pairs(self.avatars) do
		--	v.stick = true
		--end	
		return gameids
	end
end

function FiveVE:StartRound()
	local now = C.GetSysTick()
	if self.start_tick and now < self.start_tick then
		return
	end
	if self.Round == 0 then
		self.start_tick = nil
		for k,v in pairs(self.avatars) do
			if v.isNPC and v.robot then
				v.robot:StartRun()
			end			
			v.canUseSkill = true
			--v.stick = nil
		end		
	end
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
	for k,v in pairs(self.avatars) do
		if not v.robot then
			local wpk = CPacket.NewWPacket(512)
			wpk:Write_uint16(NetCmd.CMD_SC_NOTI_5PVE_ROUND)
			wpk:Write_uint16(self.Round)
			v:Send2Client(wpk)
		end
	end
	local monPos = {{120,80},{120,60},{120,70},{140,80},{140,65}}
	local monid = {101,102,103,104,104}
	local tb1 = TableTower_Defense[self.ava_level]
	local tb2 = TableTower_Coefficient[self.Round]
	local Attack_Coefficient = tb2["Attack_Coefficient"]
	local Life_Coefficient = tb2["Life_Coefficient"]
	--print(self.ava_level)
	for i = 1,5 do
	             local attack = math.floor(tb1["Attack" .. i] * Attack_Coefficient)
	             local defence = tb1["Defense" .. i]
	             local maxlife = math.floor(tb1["Life" .. i] * Life_Coefficient)
	             attr[Name2idx.Idx("attack")] = attack
	             attr[Name2idx.Idx("defencse")] = defence
	             attr[Name2idx.Idx("maxlife")] = maxlife
		--logic,avatid,nickname,attr,skills,pos,dir,teamid,aiid
		local mon = CreateNPC(self,monid[i],"",nil,attr,skills,monPos[i],5,0,1,true)
		if mon then 
			self.monster_count = self.monster_count + 1
			mon.isMon = true 
			mon.canUseSkill = true
		end
	end
end

function FiveVE:Tick(tick)
	if self.KickAll then
		local now = os.time()
		if now > self.KickAll then
			for k,v in pairs(self.avatars) do
				if v.groupsession then
					v:Release()
					local wpk = CPacket.NewWPacket(128)
					wpk:Write_uint16(NetCmd.CMD_GAMEG_KICK)
					wpk:Write_uint16(v.groupsession)
					togroup:Send(wpk)					
				end
			end
			self.map:Release()			
		end
		return
	end	
	if self.isFinish then
		return
	end
	if self.live_ply_count == 0 then
		local wpk = CPacket.NewWPacket(512)
		wpk:Write_uint16(NetCmd.CMD_GAMEG_5PVEAWARD)
		wpk:Write_uint16(self.Round)
		local c = 0
		local wpos = wpk:Get_write_pos()
		wpk:Write_uint8(c)
		for k,v in pairs(self.avatars) do
			if v.isPlayer then
				c = c + 1
				wpk:Write_uint16(v.groupsession)
				local wpk1 = CPacket.NewWPacket(512)
				wpk1:Write_uint16(NetCmd.CMD_SC_5PVE_RESULT)
				wpk1:Write_uint16(self.Round)
				v:Send2Client(wpk1)
			end
		end
		wpk:Rewrite_uint8(wpos,c)
		togroup:Send(wpk)		
		self.isFinish = true
		self.KickAll = os.time() + 5
		return
	end
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
	if avatar.isMon then
		table.insert(self.recycle,{avatar,C.GetSysTick() + 2000})
	else
		self.live_ply_count = self.live_ply_count - 1
	end
end

--maplogic of 5 pvp

local FiveVP = maplogic:new()

function FiveVP:new()
	local o = {}		
	setmetatable(o, self)
    	self.__index = self		
	return o	
end

function FiveVP:entermap(plys)
	if self.freeidx:Len() < #plys then
		log_gameserver:Log(CLog.LOG_INFO,"FiveVP:entermap not enough free id")
		return nil
	else
		local initpos = {[1] = {
				         {70,30},
			           	         {70,40},
				         {70,50},
				         {70,60},
				         {70,70}},
			             [2] = {	         	
			           	         {110,30},
			           	         {110,40},
			                       {110,50},
			                       {110,60},
			                       {110,70},
			                       }}
	             local teamidx = {[1] = 1,[2] = 1}		                       
		local teamdir = {[1] = 0,[2] = 180}
		local gameids = {}
		local size = #plys
		local map = self.map
		self.start_tick = C.GetSysTick() + 10000
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
					             v.attr,Skill.New(v.skills),initpos[teamid][teamidx[teamid]],teamdir[teamid],teamid,v.battleitem)
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

		if self.plycount < self.map.mapdef.MaxPly then
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
			local robotcount = self.map.mapdef.MaxPly - self.plycount
			for i=1,robotcount do 		
				local robotPly = CreateNPC(self,math.random(1,4),"robot", {id=5001,count=1,attr = {0,0,0,0,0,0,0,0,0,0}},attr,skills,initpos[teamid][teamidx[teamid]],teamdir[teamid],teamid,1)
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
			self.isFinish = false	
		end	
		self.team1_alive_count = self.map.mapdef.MaxPly / 2
		self.team2_alive_count = self.team1_alive_count
		return gameids
	end
end

function FiveVP:Tick(tick)
	if self.KickAll then
		local now = os.time()
		if now > self.KickAll then
			for k,v in pairs(self.avatars) do
				if v.groupsession then
					v:Release()
					local wpk = CPacket.NewWPacket(128)
					wpk:Write_uint16(NetCmd.CMD_GAMEG_KICK)
					wpk:Write_uint16(v.groupsession)
					togroup:Send(wpk)
				end
			end
			self.map:Release()			
		end
		return
	end
	if self.isFinish then
		return
	end
	if self.start_tick  then
		local now = C.GetSysTick()
		if now > self.start_tick then
			for k,v in pairs(self.avatars) do
				if v.isNPC and v.robot then
					v.robot:StartRun()
				end
				v.canUseSkill = true
			end
			self.start_tick = nil
		end
	end 
	if not self.isFinish then
		local winteam
		if self.team1_alive_count == 0 then
			winteam = 2
		elseif self.team2_alive_count == 0 then
			winteam = 1
		end
		if winteam then
			local wpk = CPacket.NewWPacket(128)
			wpk:Write_uint16(NetCmd.CMD_GAMEG_PVPAWARD)
			wpk:Write_uint16(self.map.maptype);
			local c = 0
			local wpos = wpk:Get_write_pos()
			wpk:Write_uint8(c)
			self.isFinish = true
			for k,v in pairs(self.avatars) do
				if v.groupsession then
					local wpk1 = CPacket.NewWPacket(128)	
					wpk1:Write_uint16(NetCmd.CMD_SC_5PVP_RESULT)
					wpk:Write_uint16(v.groupsession)
					if v.teamid == winteam then
						wpk:Write_uint8(1)
						wpk1:Write_uint8(1)
					else
						wpk:Write_uint8(0)
						wpk1:Write_uint8(0)
					end
					c = c + 1
					v:Send2Client(wpk1)
				end
			end
			if c > 0 then
				wpk:Rewrite_uint8(wpos,c)
				togroup:Send(wpk)
			end
			self.KickAll = os.time() + 5		
		end
	end
end

function FiveVP:OnAvatarDead(avatar,atker,skillid)
	if avatar.teamid == 1 then
		self.team1_alive_count = self.team1_alive_count - 1
	else
		self.team2_alive_count = self.team2_alive_count - 1
	end 
end


--生存游戏

local area = {}

function area:new()
	local o = {}		
	setmetatable(o, self)
    	self.__index = self		
	return o
end

local maxx = 4
local maxy = 3


local direction = {
	up = function (x,y)
		y = y - 1
		if y < 1 then
			return nil
		end
		return x,y
	end, 
	down = function (x,y)
		y = y + 1
		if y > maxy then
			return nil
		end
		return x,y
	end, 
	left  = function (x,y)
		x = x - 1
		if x < 1 then
			return nil
		end
		return x,y
	end,
	right = function (x,y)
		x = x + 1
		if x > maxx then
			return nil
		end
		return x,y
	end
}

local areaids = {
	{1,2,3,4},
	{5,6,7,8},
	{9,10,11,12}
}

local drops = {
	511,512,513,514,515,516,531,532,533,534,551,552,553,554,555,556
}

function area:Init(logic,index,leftTop,rightBottom,x,y)
	self.logic = logic
	self.leftTop = leftTop
	self.rightBottom = rightBottom
	self.index = index

	local jump_left = {leftTop[1] + 10,leftTop[2] + 72}
	local jump_left_target = {jump_left[1] - 51,jump_left[2]}
	local jump_right = {leftTop[1]  + 176,leftTop[2] + 66}
	local jump_right_target = {jump_right[1] + 51,jump_right[2]}	
	local jump_up = {leftTop[1] + 72,leftTop[2] + 20}
	local jump_up_target = {jump_up[1],jump_up[2] - 51}
	local jump_down = {leftTop[1] + 102,leftTop[2] + 95}
	local jump_down_target = {jump_down[1],jump_down[2] + 51}

	if jump_left_target[1] > 0 then
		self.jumpLeft = Trigger.New(logic.freeidx:Get(),logic.map,1,jump_left)
		self.jumpLeft.targetPoint = jump_left_target
		local targetx,targety = direction.left(x,y)
		self.jumpLeft.targetID = areaids[targety][targetx]
		self.jumpLeft.survive = logic
	end

	if  jump_right_target[1] < 183*4 then
		self.jumpRight = Trigger.New(logic.freeidx:Get(),logic.map,1,jump_right)
		self.jumpRight.targetPoint = jump_right_target
		--print(x,y)
		local targetx,targety = direction.right(x,y)
		--print(targetx,targety)
		self.jumpRight.targetID = areaids[targety][targetx]
		self.jumpRight.survive = logic		
	end

	if jump_up_target[2] > 0 then
		self.jumpUp = Trigger.New(logic.freeidx:Get(),logic.map,1,jump_up)
		self.jumpUp.targetPoint = jump_up_target
		local targetx,targety = direction.up(x,y)
		self.jumpUp.targetID = areaids[targety][targetx]
		self.jumpUp.survive = logic		
	end

	if jump_down_target[2] < 309 then
		self.jumpDown = Trigger.New(logic.freeidx:Get(),logic.map,1,jump_down)
		self.jumpDown.targetPoint = jump_down_target
		local targetx,targety = direction.down(x,y)
		self.jumpDown.targetID = areaids[targety][targetx]
		self.jumpDown.survive = logic		
	end

	self.dropObj = LinkQue.New()
	for i = 1,5 do
		local droppos = {leftTop[1] + math.random(30,160),leftTop[2] + math.random(30,90)}
		self.dropObj:Push(CreateDrop(logic,drops[math.random(1,#drops)],droppos))		
	end
	--local droppos = {leftTop[1] + 75,leftTop[2] + 75}
	--local drop = CreateDrop(logic,501,droppos)
	--drop.area = self
	--drop.onRelease = onDropRelease
	return self
end



function area:RandomDrop()
	local now = C.GetSysTick()
	if not self.nextCheckDrop or now > self.nextCheckDrop then
		local c = 5 - self.dropObj:Len()
		if c > 0 then
			for i = 1,c do
				local droppos = {self.leftTop[1] + math.random(20,20),self.leftTop[2] + math.random(130,80)}
				self.dropObj:Push(CreateDrop(logic,drops[math.random(1,#drops)],droppos))
			end
		end
		self.nextCheckDrop = math.random(1000,2000)
	end
end

function area:InArea(pos)
	if pos[1] > self.leftTop[1] and pos[2] > self.leftTop[2] and
	   pos[1] < self.rightBottom[1] and pos[2] < self.rightBottom[2] then
	   	return true
	end
	return false
end

function area:Boom()
	if self.Boomed then
		return
	end
	--print("boom",self.index)
	--kill player on this area
	for k,v in pairs(self.logic.avatars) do
		if v.isPlayer then
			local wpk = CPacket.NewWPacket(64)
			wpk:Write_uint16(NetCmd.CMD_SC_BOOM)
			wpk:Write_uint32(0)
			wpk:Write_uint8(self.index)
			v:Send2Client(wpk)
			if self:InArea(v.pos) then
				v.attr:Set("life",0)
				v.attr:NotifyUpdate()
			end
		end
	end	
	--release jump trigger
	if self.jumpLeft then
		self.jumpLeft:Release()
		self.jumpLeft = nil
	end
	if self.jumpRight then
		self.jumpRight:Release()
		self.jumpRight = nil
	end
	if self.jumpUp then
		self.jumpUp:Release()
		self.jumpUp = nil
	end
	if self.jumpDown then
		self.jumpDown:Release()
		self.jumpDown = nil
	end			
	self.Boomed = true

	for k,v in pairs(self.logic.areas) do
		if v ~= self then
			while true do
				if v.jumpLeft and self:InArea(v.jumpLeft.targetPoint) then
					v.jumpLeft:Release()
					v.jumpLeft = nil
					break
				end 
				if v.jumpRight and self:InArea(v.jumpRight.targetPoint) then
					v.jumpRight:Release()
					v.jumpRight = nil
					break
				end
				if v.jumpUp and self:InArea(v.jumpUp.targetPoint) then
					v.jumpUp:Release()
					v.jumpUp = nil
					break
				end
				if v.jumpDown and self:InArea(v.jumpDown.targetPoint) then
					v.jumpDown:Release()
					v.jumpDown = nil
					break
				end
				break
			end			 			 			
		end
	end
end

function area:NofifyBoom(boomtime)
	for k,v in pairs(self.logic.avatars) do
		if v.isPlayer then
			local wpk = CPacket.NewWPacket(64)
			wpk:Write_uint16(NetCmd.CMD_SC_BOOM)
			wpk:Write_uint32(boomtime)
			wpk:Write_uint8(self.index)
			v:Send2Client(wpk)
		end
	end
end

local Survive = maplogic:new()

function Survive:new()
	local o = {}		
	setmetatable(o, self)
    	self.__index = self		
	return o	
end

local boomScheme = Snali

--for k,v in pairs(boomScheme) do
--	print(v[1],v[2],v[3],v[4],v[5],v[6],v[7],v[8],v[9],v[10],v[11],v[12])
--end

function Survive:Init(map)
	self.avatars = {}
	self.map = map
	self.freeidx = IdMgr.New(1024)
	self.plycount = 0
	self.areas = {}  
	map.avatars = self.avatars
	local xcount = map.mapdef.xcount
	local ycount = map.mapdef.ycount
	local lenght = math.floor(xcount / 4)
	local height = math.floor(ycount / 3)
	local index = 1
	for i=0,2 do
		for j=0,3 do
			local leftTop =  {j*lenght,i*height}
			local rightBottom = {(j+1)*lenght,(i+1)*height}
			self.areas[index] = area:new():Init(self,index,leftTop,rightBottom,j+1,i+1)
			index = index + 1
		end
	end
	self.boomOrder = LinkQue.New()
	local scheme = boomScheme[math.random(1,#boomScheme)]
	for i=1,12 do
		self.boomOrder:Push(self.areas[scheme[i]])
	end
	--self.start_tick = os.time() + 2*60
	return self
end

function Survive:GetArea(index)
	return self.areas[index] 
end


function Survive:Tick(tick)
	local now = os.time()
	if self.isFinish then
		--print(self)
		if now > self.destroyTime then
			local wpk = CPacket.NewWPacket(512)
			wpk:Write_uint16(NetCmd.CMD_GAMEG_SURVIVE_FINISH)
			wpk:Write_string(self.winner or "")
			local wpos = wpk:Get_write_pos()
			local c = 0	
			wpk:Write_uint8(0)
			for k,v in pairs(self.avatars) do 
				if v.isPlayer then
					wpk:Write_uint32(v.groupsession)
					c = c + 1
				end
			end
			wpk:Rewrite_uint8(wpos,c)
			Send2Group(wpk)			
			--self.isFinish = true
			self.map:Release()
			g_survive = nil
		end
		return
	end
	if self.start_tick and now > self.start_tick then
		print("Survive start")
		self.start_tick = nil
		self.nextBoomArea = self.boomOrder:Pop()
		self.nextBoomTime = now + 10
		self.nextBoomArea:NofifyBoom(self.nextBoomTime)
	end

	local winner
	if not self.start_tick then
		local alive_count = 0
		for k,v in pairs(self.avatars) do
			if v.isPlayer and v.attr:Get("life") > 0 then
				alive_count = alive_count + 1
				winner = v.nickname
			end
		end
		if alive_count == 1 then
			self.isFinish = true
		end
	end
	if not self.isFinish and self.nextBoomTime and now >= self.nextBoomTime then
		self.nextBoomArea:Boom()
		self.nextBoomArea = self.boomOrder:Pop()
		if not self.nextBoomArea then
			--Ok game over
			self.isFinish = true
		else
			self.nextBoomTime = now + 10
			self.nextBoomArea:NofifyBoom(self.nextBoomTime)
		end
	end
	if self.isFinish then
		for k,v in pairs(self.avatars) do
			if v.isPlayer then
				local wpk = CPacket.NewWPacket(64)
				wpk:Write_uint16(NetCmd.CMD_SC_SURVIVE_WIN)
				wpk:Write_string(winner or "")
				v:Send2Client(wpk)
			end
		end
		self.winner = winner
		self.destroyTime = os.time() + 2
	else
		for k,v in pairs(self.areas) do
			if not v.Boomed then
				v:RandomDrop()
			end
		end
	end
end

function Survive:entermap(v)
	if self.freeidx:Len() < 1 then
		log_gameserver:Log(CLog.LOG_INFO,"Survive:entermap not enough free id")
		return nil
	else
		local map = self.map
		local gate = nil
		if v.gatesession then
			gate = Gate.GetGateByName(v.gatesession.name)
		end
		local id = self.freeidx:Get()

		for i = 5,7 do
			v.battleitem[i] = {i,0,0}
		end
		v.attr[Name2idx.Idx("defencse")] =  TableFixed_Attribute[500].Defense
		v.attr[Name2idx.Idx("maxlife")] =  TableFixed_Attribute[500].Life
		v.attr[Name2idx.Idx("agile")] =  TableFixed_Attribute[500].agile
		v.attr[Name2idx.Idx("crit")] =  TableFixed_Attribute[500].Crit
		v.attr[Name2idx.Idx("hit")] =  TableFixed_Attribute[500].accurate
		local ply = Player.New(bit32.lshift(map.mapid,16) + id,v.avatid,
				             map,v.nickname,
				             v.actname,v.groupsession,
				             v.attr,Skill.New(v.skills),{60,60},5,id,v.battleitem)
		ply.fashion = v.fashion
		
		local item = v.item
		print(item)
		local itemtb = TableItem[item.id]
		if itemtb then
			print(item.id,item.count) 
			if  itemtb["Item_Type"] < 5 then
				ply.weapon = {id = item.id,count = item.count,attr = item.attr}
			else
				ply.battleitems:AddItem(item.id,item.count)
			end
		end
		--ply.weapon = v.weapon
		ply.isPlayer = true
		if gate then 
			Gate.Bind(gate,ply,v.gatesession.id)
		end
		self.avatars[ply.id] = ply
		ply:on_entermap()	
		self.plycount = self.plycount + 1
		Aoi.enter_map(map.aoi,ply.aoi_obj,ply.pos[1],ply.pos[2])
		log_gameserver:Log(CLog.LOG_INFO,ply.actname .. " enter map id:" .. ply.id)
		return ply.id				             		
	end
end

function Survive:leavemap(id)
	local ply = self:GetAvatar(id)
	if ply then
		ply:Release()
		self.plycount = self.plycount - 1
		self.avatars[id] = nil
		return true
	end
	return false
end

function Survive:OnClientDisconnect(ply)
end

return {
	New = function (map) 
			local logicname = map.mapdef["PlayType"]
			if logicname == "open" then
				return maplogic:new():Init(map)
			elseif map.maptype == 206 then
				return Survive:new():Init(map)
			elseif map.maptype == 203 then
				return FiveVE:new():Init(map)
			elseif map.maptype == 204 or  map.maptype == 207 or map.maptype == 208 then
				return FiveVP:new():Init(map)
			else
				return nil
			end
	             end
}
