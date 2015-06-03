local Sche = require "lua.sche"
local Util = require "gameserver.util"

local stat_partol = 1
local stat_trace = 2
local stat_atk = 3

local state_partol = {}

function state_partol:new(ro)
	local o = {}   
	setmetatable(o, self)
	self.__index = self
	o.ro= ro
	return o	
end

function state_partol:execute()
	if self.ro.target then
		return stat_trace
	end
	local avatar = self.ro.avatar
	--check if there is a available target in view
	local viewObjs = avatar:GetViewObj()
	for k,v in pairs(viewObjs) do
		if not v.invisible and v ~= avatar and not v:isDead() and v.teamid ~= avatar.teamid then-- and not Util.TooLong(avatar.pos,v.pos,500) then
			self.ro.target = v
			v:AddTraceMe(avatar)
			--got target,transfer to trace
			return stat_trace
		end
	end

	--no target,random mov
	local mapdef = avatar.map.mapdef
	local randx = avatar.pos[1] + math.random(-10,10)
	if randx >= mapdef.xcount or randx < 0 then
		randx = 0
	end
	local randy = avatar.pos[2] + math.random(-10,10)
	if randy >= mapdef.ycount or randy < 0 then
		randy = 0
	end
	if avatar:Mov(randx,randy) then
		Sche.Block()
		Sche.Sleep(math.random(200,1000))
	end
	return stat_partol
end

local state_partol_goto = {}

function state_partol_goto:new(ro,targetpoint,stateMgr)
	local o = {}   
	setmetatable(o, self)
	self.__index = self
	o.ro= ro
	o.targetpoint = targetpoint
	o.stateMgr = stateMgr
	return o	
end

function state_partol_goto:execute()
	if self.ro.target then
		return stat_trace
	end
	local avatar = self.ro.avatar
	--check if there is a available target in view
	local viewObjs = avatar:GetViewObj()
	for k,v in pairs(viewObjs) do
		if v ~= avatar and not v:isDead() and v.teamid ~= avatar.teamid and not Util.TooLong(avatar.pos,v.pos,300) then
			self.ro.target = v
			v:AddTraceMe(avatar)
			--got target,transfer to trace
			return stat_trace
		end
	end

	if not (self.targetpoint[1] == avatar.pos[1] and self.targetpoint[2] == avatar.pos[2]) then
		if avatar:Mov(self.targetpoint[1],self.targetpoint[2]) then
			Sche.Block()
		else
			Sche.Sleep(500)
		end		
	else
		if self.stateMgr[stat_partol] == self then
			self.stateMgr[stat_partol] = state_partol:new(self.ro)
		end
	end
	return stat_partol
end


local state_partol_npc = {}

function state_partol_npc:new(ro)
	local o = {}   
	setmetatable(o, self)
	self.__index = self
	o.ro= ro
	return o	
end

function state_partol_npc:execute()
	if self.ro.target then
		return stat_trace
	end

	local avatar = self.ro.avatar
	for k,v in pairs(avatar.map.avatars) do
		if v ~= avatar and not v:isDead() then
			if v.teamid ~= avatar.teamid then-- and not Util.TooLong(avatar.pos,v.pos,300) then
				print("got target")
				self.ro.target = v
				v:AddTraceMe(avatar)
				--got target,transfer to trace
				return stat_trace
			end
		end
	end
	local mapdef = avatar.map.mapdef
	local randx = avatar.pos[1] + math.random(-10,10)
	if randx >= mapdef.xcount or randx < 0 then
		randx = 0
	end
	local randy = avatar.pos[2] + math.random(-10,10)
	if randy >= mapdef.ycount or randy < 0 then
		randy = 0
	end
	if avatar:Mov(randx,randy) then
		Sche.Block()
	end
	--end
	return stat_partol
end

local state_trace_npc = {}

function state_trace_npc:new(ro)
	local o = {}   
	setmetatable(o, self)
	self.__index = self
	o.ro = ro
	return o	
end

function state_trace_npc:execute()
	local ro = self.ro
	local avatar = ro.avatar
	local target = ro.target
	if not target or target.invisible or target:isDead() then
		if target then
			ro.target:RemTraceMe(avatar)
			ro.target = nil
		end
		--mis target,transfer to partol
		return stat_partol
	end

	if not Util.TooLong(avatar.pos,target.pos,150) then
		--close enough,transfer to attack
		return stat_atk
	end
	--print("trace")
	local trace_point = target:AssignAtkPoint(avatar,140)
	if not trace_point then
		Sche.Sleep(1000)
	else
		if avatar:Mov(trace_point[1],trace_point[2]) then
			Sche.Block()
		else
			Sche.Sleep(500)
		end
	end	
	return stat_trace
end



local state_trace = {}

function state_trace:new(ro)
	local o = {}   
	setmetatable(o, self)
	self.__index = self
	o.ro = ro
	return o	
end

function state_trace:execute()
	local ro = self.ro
	local avatar = ro.avatar
	local target = ro.target
	if not target or target.invisible or target:isDead() or Util.TooLong(avatar.pos,target.pos,500) then
		if target then
			ro.target:RemTraceMe(avatar)
			ro.target = nil
		end
		--mis target,transfer to partol
		return stat_partol
	end

	if not Util.TooLong(avatar.pos,target.pos,150) then
		--close enough,transfer to attack
		return stat_atk
	end
	--print("trace")
	local trace_point = target:AssignAtkPoint(avatar,140)
	if not trace_point then
		--print("trace no point")
		Sche.Sleep(1000)
	else
		if avatar:Mov(trace_point[1],trace_point[2]) then
			Sche.Block()
		else
			--print("trace move failed",trace_point[1],trace_point[2])
			Sche.Sleep(500)
		end
	end	

--[[	local distance = Util.Grid2Pixel(Util.Distance(avatar.pos,target.pos))
	local tpos = Util.ForwardTo(avatar.map,avatar.pos,target.pos,distance-120) 
	if not tpos then
		Sche.Sleep(1000)
	else
		if avatar:Mov(tpos[1],tpos[2]) then
			Sche.Block()
		else
			Sche.Sleep(500)
		end
	end
]]--
	return stat_trace
end

local state_atk = {}

function state_atk:new(ro)
	local o = {}   
	setmetatable(o, self)
	self.__index = self
	o.ro = ro
	return o	
end

local function AiUseSkill(ro,target,skill)
	local avatar = ro.avatar
	function UseSkillSingle(skill)
		return avatar:UseSkillByAi(skill,{target})
	end
	function UseSkillPoint()
		local targets = {}
		local viewObjs = avatar:GetViewObj()
		for k,v in pairs(viewObjs) do
			if v ~= avatar and not v:isDead() and v.teamid ~= avatar.teamid and Util.TooClose(avatar.pos,v.pos,200) then
				table.insert(targets,v)
			end
		end
		return avatar:UseSkillByAi(skill,{avatar.pos,targets})
	end
	function UseSkillDir(skill)
		return avatar:UseSkillByAi(skill,{avatar.dir,{target}})
	end
	skill = skill or avatar.skillmgr:GetAvailableSkill()
	if not skill then
		return false
	end
	local targettype = skill.tb["Target_type"]
	local atktype = skill.tb["Attack_Types"]
	if atktype == 3 then
		target = avatar
	end
	if atktype == 3 or atktype == 0 then
		return UseSkillSingle(skill)
	elseif atktype == 2 then
		return UseSkillDir(skill)
	else
		return UseSkillPoint()
	end
	return false
end

function state_atk:execute()
	local ro = self.ro
	local avatar = ro.avatar
	local target = ro.target
	if not target or target.invisible or target:isDead() then 
		if target then
			ro.target:RemTraceMe(avatar)
			ro.target = nil
		end
		--mis target,transfer to partol
		return stat_partol
	end
	if Util.TooLong(avatar.pos,target.pos,150) then
		Sche.Sleep(math.random(100,500))
		return stat_trace
	end
--[[
	--select attack position
	local checkpos = {avatar.pos}
	local find = false
	for i=1,10 do 
		table.insert(checkpos,target:GetDirPoint(math.random(0,359),140))
	end
	for k,v in pairs(checkpos) do
		if not Util.CheckOverLap(avatar,v) then
			find = true
			break
		end
	end
	if not find then
		Sche.Sleep(500)
		return stat_atk
	end
]]--
	Sche.Sleep(150)
	avatar:DirTo(target)
	if not AiUseSkill(ro,target) then
		Sche.Sleep(500)
	end
	return stat_atk
end

local AiTable = {
	[1] = {[stat_partol] = state_partol,[stat_trace] =state_trace,[stat_atk] = state_atk},
	[2] = {[stat_partol] = state_partol_npc,[stat_trace] =state_trace_npc,[stat_atk] = state_atk},
}


local stateMachine = {}

function stateMachine:new(ro,aiid)
	local o = {}	   
	setmetatable(o, self)
  	self.__index = self 	
	o.ro = ro
	o.states = {}
	local tb = AiTable[aiid]
	o.states[stat_partol] =  tb[stat_partol]:new(ro)--state_partol_follow:new(ro)--state_partol:new(ro)
	o.states[stat_trace] =  tb[stat_trace]:new(ro)--state_trace:new(ro)
	o.states[stat_atk] =  tb[stat_atk]:new(ro)--state_atk:new(ro)
	o.current_state = o.states[stat_partol]
	return o	
end

function stateMachine:execute()
	if self.current_state then
		local nextstate = self.current_state:execute()
		self.current_state = self.states[nextstate]
	end
end

function stateMachine:NotifyEnterSee()
	if self.current_state == self.states[stat_partol]  then
		self.ro.avatar:StopMov()
	end
end

function stateMachine:NotifyTargetPosChange()
	if self.current_state == self.states[stat_trace]  then
		self.ro:Wakeup()
	end
end

local robot = {}

function robot:new(avatar,aiid)
	local o = {}
--  	self.__mode = "v"		   
	setmetatable(o, self)
  	self.__index = self 	
	o.avatar = avatar
	o.stateMac = stateMachine:new(o,aiid)
	return o
end

function robot:Wakeup()
	if self.run and self.co then
		Sche.WakeUp(self.co)
	end	
end

function robot:StartRun()
	if not self.run then
		self.run = true
		--spawn a coroutine to run robot main
		self.co = Sche.Spawn(self.main,self)
	end
	return self
end

function robot:Stop()
	if self.run and self.co then
		if self.target then
			self.target:RemTraceMe(self.avatar)
			self.target = nil
		end
		if self.follow_obj then
			self.follow_obj:RemTraceMe(self.avatar)
			self.follow_obj = nil			
		end
		self.run = nil
		--run immediate
		Sche.Schedule(self.co)
		self.co = nil
	end
end

--the robot main loop
function robot:main()
	while self.run do
		self.stateMac:execute()
		if not self.run then
			break
		end
		Sche.Yield()
	end
end

function robot:NotifyEnterSee()
	if self.run then
		self.stateMac:NotifyEnterSee()
	end
end

function robot:NotifyTargetPosChange()
	if self.run then
		self.stateMac:NotifyTargetPosChange()
	end	
end

function robot:UseBuffSkill(skillid)
	AiUseSkill(self,nil,self.avatar.skillmgr.skills[skillid])
end

return {
	New = function (avatar,aiid) return robot:new(avatar,aiid) end
}