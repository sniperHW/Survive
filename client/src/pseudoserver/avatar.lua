local Time = require "src.pseudoserver.time"
local Timer = require "src.pseudoserver.timer"
local Sche = require "src.pseudoserver.sche"
local NetCmd = require "src.net.NetCmd"
local Attr = require "src.pseudoserver.attr"
local Buff = require "src.pseudoserver.buff"
local Skill = require "src.pseudoserver.skill"
local Que =  require "src.pseudoserver.queue"
local Util = require "src.pseudoserver.util"

local battleitems = {}


function battleitems:new(items)
	local o = {}   
	setmetatable(o, self)
	self.__index = self
	o.items = {}
	items = items or {}
	for k,v in pairs(items) do
		o.items[v[1]] = {id=v[2],count=v[3]}
		--print(v[1],v[2],v[3])
	end
	return o	
end

function battleitems:on_entermap(wpk)
	local tmp = {}
	for k,v in pairs(self.items) do
		table.insert(tmp,{k,v})
	end
	WriteUint8(wpk,#tmp)
	for k,v in pairs(tmp) do
			WriteUint8(wpk,v[1])
			WriteUint16(wpk,v[2].id)
			WriteUint16(wpk,v[2].count)
	end
end

local avatar ={}

function avatar:new()
	local o = {}
	self.__index = self
	setmetatable(o, self)
	return o
end

function avatar:Init(id,avatid,map,nickname,attr,skill,pos,dir,teamid,fashion,weapon,items)
	self.id = id
	self.map = map
	self.nickname = nickname
	self.pos = pos
	self.dir = dir
	self.attr = Attr.New(self,attr)
	self.avatid = avatid
	self.avattype = 0
	self.teamid = teamid or 0
	self.path = nil
	self.skillmgr = Skill.New(skill)
	self.speed = 27
	self.buff = Buff.New(self)
	self.fashion = fashion
	self.battleitems = battleitems:new(items)
	print("avatar init",weapon)
	self.weapon = weapon
	return self
end

function avatar:Tick(currenttick)
	self.buff:Tick(currenttick)
	self:process_mov()
end

function avatar:isDead()
	if self.attr and self.attr:Get("life") > 0 then
		return false
	else
		return true
	end
end

function avatar:Release(onMapDestroy)
	print("avatar:Release")
	self.path = nil
	if self.robot then
		self.robot:Stop()
	end
	self:ClearTraceMe()
end

local function packWeapon(wpk,weapon)
	--print("packWeapon",weapon.id,weapon.count)
	if weapon and  weapon.id then
		WriteUint16(wpk,weapon.id)
		WriteUint16(wpk,weapon.count)
		WriteUint8(wpk,10)	
		for k,v in pairs(weapon.attr) do
			WriteUint8(wpk,k)
			WriteUint32(wpk,weapon.attr[k])
		end
	else
		WriteUint16(wpk,0)
	end
end

function avatar:EnterSee(other)
	local wpk = GetWPacket()
	WriteUint16(wpk,NetCmd.CMD_SC_ENTERSEE)
	WriteUint32(wpk,other.id)
	WriteUint8(wpk,other.avattype)
	WriteUint16(wpk,other.avatid)
	WriteString(wpk,other.nickname)
	WriteUint16(wpk,other.teamid)
	WriteUint16(wpk,other.pos[1])
	WriteUint16(wpk,other.pos[2])
	WriteUint16(wpk,other.dir)
	other.attr:on_entersee(wpk)
	WriteUint16(wpk,other.fashion or 0)
	packWeapon(wpk,other.weapon)		
	Send2Client(wpk)
	if other.path then
		local size = #other.path.path
		local target = other.path.path[size]
		local wpk = GetWPacket()
		WriteUint16(wpk,NetCmd.CMD_SC_MOV)
		WriteUint32(wpk,other.id)
		WriteUint16(wpk,other.speed)
		WriteUint16(wpk,target[1])
		WriteUint16(wpk,target[2])
		Send2Client(wpk)
	end	
end

function avatar:LeaveSee(other)
	local wpk = GetWPacket()
	WriteUint16(wpk,NetCmd.CMD_SC_LEAVESEE)
	WriteUint32(wpk,other.id)	
	Send2Client(wpk)
end

function avatar:Mov(x,y)
	local path = FindPath(self.pos[1],self.pos[2],x,y)
	if path then
		--print("mov",self.pos[1],self.pos[2],x,y,#path)
		self.path = {cur=1,path=path}
		--self.map:beginMov(self)
		self.lastmovtick = Time.SysTick()
		self.movmargin = 0

		local size = #self.path.path
		local target = self.path.path[size]
		local wpk = GetWPacket()
		WriteUint16(wpk,NetCmd.CMD_SC_MOV)
		WriteUint32(wpk,self.id)
		WriteUint16(wpk,self.speed)
		WriteUint16(wpk,target[1])
		WriteUint16(wpk,target[2])	
		Send2Client(wpk)
		return true			
	else
		return false			
	end
end

function avatar:UseSkill(rpk)
	self.skillmgr:UseSkill(self,rpk)
end

function avatar:UseSkillByAi(skill,param)
	self.skillmgr:UseSkillAi(self,skill,param)
end

function avatar:OnDead(atker,skillid)
	if self.robot then
		self.robot:Stop()
		self.robot = nil
	end
	self.buff:OnAvatarDead()
	self:StopMov()
	self.map:OnDead(self)
end

function avatar:GetViewObj()
	return self.map.avatars
end

local grid_edge = 8
local grid_diagonal = 8 * 1.41

local function distance(dir)
	if dir == 0 or dir == 90 or dir == 180 or dir == 270 then
		return grid_edge
	else
		return grid_diagonal
	end
end

function avatar:DirTo(o)
	local targetpos = o.pos
	local pos = self.pos
	self.dir = Util.Dir(pos,targetpos)
	return self.dir
end

function avatar:process_mov()
	if not self.path then
		return true
	end
	local path = self.path.path
	local now = Time.SysTick()
	local movmargin = self.movmargin + now - self.lastmovtick	
	local cur  = self.path.cur
	local size = #path
	--print(size)
	while cur <= size do
		local node = path[cur]
		local newdir = Util.Dir(self.pos,node)
		local dis = distance(newdir)
		local speed  = self.speed * grid_edge
		local elapse = dis/speed * 1000
		if elapse < movmargin then
			self.dir = newdir
			self.pos = node
			--if self.avatid <= 4 then
			--	print(self.pos[1],self.pos[2])
			--end
			--pos change,if there is a robot traceme,notify it target pos change
			self:NotifyTraceMe()
			cur = cur + 1
			movmargin = movmargin - elapse;
			if not self.path then return true end				
		else
			break	
		end
	end
	self.path.cur = cur
	self.movmargin = movmargin
	self.lastmovtick = Time.SysTick()
	
	if self.path.cur > #self.path.path then
		self.path = nil
		local wpk = GetWPacket()
		WriteUint16(wpk,NetCmd.CMD_SC_MOV_ARRI)
		Send2Client(wpk)
		if self.robot then
			self.robot:Wakeup() --if we have a robot,wake it up
		end
		return true
	else
		return false
	end
end

function avatar:StopMov()
	if self.path then
		self.path = nil
		if self.robot then
			self.robot:Wakeup()
		end
	end
end


local eighttracepos ={
	[1] = {-12,-12},
	[2] = {0,-14},
	[3] = {12,-12},
	[4] = {14,0},
	[5] = {12,12},
	[6] = {0,14},
	[7] = {-12,12},
	[8] = {-14,0}
}

function avatar:AddTraceMe(ava)
	self.traceme = self.traceme or {}
	self.traceme_size = self.traceme_size or 0
	self.eighttracepos = self.eighttracepos or {}
	if not self.traceme[ava.id] then
		self.traceme[ava.id] = ava.robot
		self.traceme_size = self.traceme_size + 1
	end
end

function avatar:RemTraceMe(ava)
	self.traceme = self.traceme or {}
	self.traceme_size = self.traceme_size or 0
	if self.traceme[ava.id] then
		self.traceme[ava.id] = nil
		self.traceme_size = self.traceme_size - 1
		if ava.traceidx then
			self.eighttracepos[ava.traceidx] = nil
		end
	end
end

function avatar:SizeTraceMe()
	self.traceme = self.traceme or {}
	self.traceme_size = self.traceme_size or 0
	return self.traceme_size
end

function avatar:NotifyTraceMe()
	self.traceme = self.traceme or {}
	self.traceme_size = self.traceme_size or 0
	for k,v in pairs(self.traceme) do	
		v:NotifyTargetPosChange()
	end
end

function avatar:ClearTraceMe()
	if self.traceme then
		self.traceme = {}
		self.traceme_size = 0
		self.eighttracepos = {}
	end
end

local function distance(pos1,pos2)
	return math.sqrt(math.pow(pos1[1] - pos2[1] , 2) + math.pow(pos1[2] - pos2[2] , 2))
end

function avatar:GetTracePos(ava)
	local idx = ava.traceidx
	local min = 0xEFFFFFFF
	if not idx then
		for i=1,8 do
			if not self.eighttracepos[i] then
				local pos = {self.pos[1] + eighttracepos[i][1],self.pos[2] + eighttracepos[i][2]}
				local dis = distance(ava.pos,pos)
				if dis < min then
					idx = i
					min = dis
				end
			end
		end
	end
	if idx then
		ava.traceidx = idx
		self.eighttracepos[idx] = true
		return {self.pos[1] + eighttracepos[idx][1],self.pos[2] + eighttracepos[idx][2]}		
	else
		return nil
	end 
end

function avatar:GetFollowPos(curdir)
	if not self.followdir then
		self.followdir = Que.New()
		self.followdir:Push({0})
		self.followdir:Push({90})
		self.followdir:Push({180})
		self.followdir:Push({270})
		self.followdir:Push({45})
		self.followdir:Push({135})
		self.followdir:Push({225})
		self.followdir:Push({315})
	end

	if curdir then
		--print("have dir")
		local tpos = Util.DirTo(self.map,self.pos,150,curdir)
		if tpos and not Util.CheckOverLap(self,tpos) then
			--print("use old dir")
			return tpos,curdir
		end		
	end

	for i = 1,8 do
		local dir = self.followdir:Pop()
		self.followdir:Push(dir)
		if dir ~= curdir then
			dir = dir[1]
			local tpos = Util.DirTo(self.map,self.pos,150,dir)
			if tpos and not Util.CheckOverLap(self,tpos) then
				return tpos,dir
			end
		end
	end
	return nil
end

function avatar:ProcessPacket(cmd,rpk)
	if cmd == NetCmd.CMD_CS_MOV then
		local x = ReadUint16(rpk)
		local y = ReadUint16(rpk)
		self:Mov(x,y)
	elseif cmd == NetCmd.CMD_CS_USESKILL then
		self:UseSkill(rpk)
	end
end

return {
	New = function (id,avatid,map,nickname,attr,skill,pos,dir,teamid,fashion,weapon,items) 
		return avatar:new():Init(id,avatid,map,nickname,attr,skill,pos,dir,teamid,fashion,weapon,items)
	end
}