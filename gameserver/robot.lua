local Sche = require "lua.sche"

local stat_partol = 1
local stat_trace = 2
local stat_atk = 3

local function toLong(pos1,pos2,dis)
	return math.sqrt(math.pow(pos1[1] - pos2[1] , 2) + math.pow(pos1[2] - pos2[2] , 2)) > dis
end

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
		if v ~= avatar and not v:isDead() and v.teamid ~= avatar.teamid and not toLong(avatar.pos,v.pos,30) then
			print("got target")
			self.ro.target = v
			--got target,transfer to trace
			return stat_trace
		end
	end

	--no target,random mov
	local mapdef = avatar.map.mapdef
	local randx = avatar.pos[1] + math.random(-50,50)
	if randx >= mapdef.xcount or randx < 0 then
		randx = 0
	end
	local randy = avatar.pos[2] + math.random(-50,50)
	if randy >= mapdef.ycount or randy < 0 then
		randy = 0
	end
	if avatar:Mov(randx,randy) then
		Sche.Block()
	end
	return stat_partol
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
	print("state_trace")
	local ro = self.ro
	local avatar = ro.avatar
	local target = ro.target
	if not target or target:isDead() or toLong(avatar.pos,target.pos,30) then
		ro.target = nil
		--mis target,transfer to partol
		return stat_partol
	end

	if not toLong(avatar.pos,target.pos,20) then
		--close enough,transfer to attack
		return stat_atk
	end

	--select a trace point
	if avatar:Mov(target.pos[1],target.pos[2]) then
		Sche.Block()
	else
		Sche.Sleep(500)
	end
	return stat_partol	

end

local state_atk = {}

function state_atk:new(ro)
	local o = {}   
	setmetatable(o, self)
	self.__index = self
	o.ro = ro
	return o	
end

local function AiUseSkill(ro,target)
	local avatar = ro.avatar
	function UseSkillSingle(skill)
		print("UseSkillSingle")
		return avatar:UseSkillByAi(skill,{target})
	end
	--[[function UseSkillPoint()

	end
	function UseSkillDir()

	end]]--
	local skill = avatar.skillmgr:GetAvailableSkill()
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
	end
	return false
end

function state_atk:execute()
	print("state_atk")
	local ro = self.ro
	local avatar = ro.avatar
	local target = ro.target
	if not target or target:isDead() then 
		ro.target = nil
		--mis target,transfer to partol
		return stat_partol
	end
	if toLong(avatar.pos,target.pos,20) then
		return stat_trace
	end

	--ok attack
	if not AiUseSkill(ro,target) then
		print("here 1")
		Sche.Sleep(500)
	end
	return stat_atk
end



local stateMachine = {}

function stateMachine:new(ro,aiid)
	local o = {}   
	setmetatable(o, self)
	self.__index = self
	o.ro = ro
	o.states = {}
	o.states[stat_partol] =  state_partol:new(ro)
	o.states[stat_trace] =  state_trace:new(ro)
	o.states[stat_atk] =  state_atk:new(ro)
	o.current_state = o.states[stat_partol]
	return o	
end

function stateMachine:execute()
	if self.current_state then
		local nextstate = self.current_state:execute()
		self.current_state = self.states[nextstate]
	end
end

local robot = {}

function robot:new(avatar,aiid)
	local o = {}   
	setmetatable(o, self)
	self.__index = self
	o.avatar = avatar
	o.stateMac = stateMachine:new(o,aiid)
	return o
end

function robot:Wakeup()
	--print("robot:Wakeup",self.run,self.co)
	if self.run and self.co then
		Sche.WakeUp(self.co)
	end	
end

function robot:StartRun()
	if not self.run then
		print("robot start")
		self.run = true
		--spawn a coroutine to run robot main
		self.co = Sche.Spawn(self.main,self)
	end
end

function robot:Stop()
	if self.run and self.co then
		print("robot:Stop")
		self.run = nil
		--run immediate
		Sche.Schedule(self.co)
		self.co = nil
	end
end

--the robot main loop
function robot:main()
	while self.run do
		--print("robot run")
		self.stateMac:execute()
		if not self.run then
			break
		end
		Sche.Sleep(100)
	end
	print("robot end")
end

return {
	New = function (avatar,aiid) return robot:new(avatar,aiid) end
}