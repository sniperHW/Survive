local Sche = require "lua.sche"
local Util = require "SurviveServer.gameserver.util"

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
		if v ~= avatar and not v:isDead() and v.teamid ~= avatar.teamid and not Util.TooLong(avatar.pos,v.pos,300) then
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
		Sche.Sleep(math.random(1000,3000))
	end
	return stat_partol
end


local state_partol_follow = {}

function state_partol_follow:new(ro)
	local o = {}   
	setmetatable(o, self)
	self.__index = self
	o.ro= ro
	return o	
end

function state_partol_follow:execute()
	if self.ro.target then
		return stat_trace
	end

	if self.follow_obj and self.follow_obj:isDead() then
		self.follow_obj = nil
		self.follow_obj:RemTraceMe(avatar)
	end

	local avatar = self.ro.avatar
	--check if there is a available target in view
	local viewObjs = avatar:GetViewObj()
	local follow_objs = {}
	for k,v in pairs(viewObjs) do
		if v ~= avatar and not v:isDead() then
			if v.teamid ~= avatar.teamid and not Util.TooLong(avatar.pos,v.pos,300) then
				if self.ro.follow_obj then
					self.ro.follow_obj:RemTraceMe(avatar)					
					self.ro.follow_obj = nil
				end
				self.ro.target = v
				v:AddTraceMe(avatar)
				--got target,transfer to trace
				return stat_trace
			elseif v.isPlayer then
				table.insert(follow_objs,v)
			end
		end
	end

	if not self.ro.follow_obj and #follow_objs > 0 then
		self.ro.follow_obj = follow_objs[math.random(1,#follow_objs)]
		self.ro.follow_obj:AddTraceMe(avatar)
	end

	if self.ro.follow_obj then
		local distance = Util.Grid2Pixel(Util.Distance(avatar.pos,self.ro.follow_obj.pos))
		if distance > 180 or Util.CheckOverLap(avatar,avatar.pos) then
			local tpos
			tpos,self.ro.trace_dir = self.ro.follow_obj:GetFollowPos(self.ro.trace_dir)
			if not tpos then
				Sche.Sleep(500)
			else
				if avatar:Mov(tpos[1],tpos[2]) then
					Sche.Block()
				else
					Sche.Sleep(500)
				end
			end
		else
			Sche.Sleep(math.random(500,1000))
		end		
	else
		Sche.Sleep(math.random(500,1000))
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
	local ro = self.ro
	local avatar = ro.avatar
	local target = ro.target
	if not target or target:isDead() or Util.TooLong(avatar.pos,target.pos,300) then
		if target then
			ro.target:RemTraceMe(avatar)
			ro.target = nil
		end
		--mis target,transfer to partol
		return stat_partol
	end

	if not Util.TooLong(avatar.pos,target.pos,120) then
		--close enough,transfer to attack
		return stat_atk
	end

	--select a trace point
	if target:SizeTraceMe() <= 1 then
		local distance = Util.Grid2Pixel(Util.Distance(avatar.pos,target.pos))
		local tpos = Util.ForwardTo(avatar.map,avatar.pos,target.pos,distance-90) 
		if not tpos then--or Util.CheckOverLap(avatar,tpos) then
			Sche.Sleep(1000)
		else
			if avatar:Mov(tpos[1],tpos[2]) then
				Sche.Block()
			else
				Sche.Sleep(500)
			end
		end
	else
		local tpos
		tpos,self.ro.trace_dir = target:GetFollowPos(self.ro.trace_dir)
		if not tpos then
			Sche.Sleep(500)
		else
			if avatar:Mov(tpos[1],tpos[2]) then
				Sche.Block()
			else
				Sche.Sleep(500)
			end
		end
	end
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
	if not target or target:isDead() then 
		if target then
			ro.target:RemTraceMe(avatar)
			ro.target = nil
		end
		--mis target,transfer to partol
		return stat_partol
	end
	if Util.TooLong(avatar.pos,target.pos,120) then
		return stat_trace
	end
	--ok attack
	--print("atkdir",avatar:DirTo(target))
	--print("dir:",avatar.dir)
	--print("angle:",avatar:Dir2Angle(avatar.dir))
	avatar:DirTo(target)
	if not AiUseSkill(ro,target) then
		Sche.Sleep(500)
	end
	return stat_atk
end

local AiTable = {
	[1] = {[stat_partol] = state_partol,[stat_trace] =state_trace,[stat_atk] = state_atk},
	[2] = {[stat_partol] = state_partol_follow,[stat_trace] =state_trace,[stat_atk] = state_atk},
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
	--if self.current_state == self.states[stat_trace]  then
	self.ro:Wakeup()
	--end
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