package.cpath = "SurviveServer/?.so"
local Aoi = require "aoi"
local NetCmd = require "SurviveServer.netcmd.netcmd"
local Buff = require "SurviveServer.gameserver.buff"
local Attr = require "SurviveServer.gameserver.attr"
local Skill = require "SurviveServer.gameserver.skill"
local Gate = require "SurviveServer.gameserver.gate"
local LinkQue = require "lua.linkque"
local Util = require "SurviveServer.gameserver.util"

local avatar ={}

function avatar:new()
	local o = {}
	self.__index = self
	--self.__gc = function () print("avatar gc") end     
	setmetatable(o, self)
	return o
end

function avatar:Init(id,avatid,map,nickname,attr,skillmgr,pos,dir,teamid)
	self.id = id
	self.map = map
	self.nickname = nickname
	self.attr = Attr.New(self,attr)
	self.skillmgr = skillmgr
	self.pos = pos
	self.dir = dir
	self.avatid = avatid
	self.teamid = teamid or 0
	self.avattype = 0
	self.see_radius = 5
	self.view_obj = {}
	self.watch_me = {}
	self.path = nil
	self.speed = 27
	self.aoi_obj = Aoi.create_obj(self)
	self.buff = Buff.New(self)	
	return self
end

function avatar:Send2Client(wpk)
end

function avatar:Tick(currenttick)
	self.buff:Tick(currenttick)
end

function avatar:GetViewObj()
	return self.view_obj
end

function avatar:isDead()
	if self.attr and self.attr:Get("life") > 0 then
		return false
	else
		return true
	end
end

function avatar:Send2view(wpk,exclude) --exclude排除列表
	--将玩家分组,同gateserver的玩家为一组,发送一个统一的包	
	local function isInExclude(a)
		if not exclude then
			return false
		end
		for k,v in pairs(exclude) do
			if a == v then
				return true
			end
		end
		return false
	end
	local gates = {}
	for k,v in pairs(self.watch_me) do
		if v.gatesession and (not isInExclude(v)) then
			local t = gates[v.gatesession]
			if not t then
				t = {}
				gates[v.gatesession] = t
			end
			table.insert(t,v)
		end
	end
	
	for k,v in pairs(gates) do
		local w = CPacket.NewWPacket(512)
		local rpk = CPacket.NewRPacket(wpk)
		w:Write_uint16(rpk:Read_uint16())
		w:Write_wpk(wpk)
		w:Write_uint16(#v)
		for k1,v1 in pairs(v) do
			w:Write_uint32(v1.gatesession.sessionid)
		end
		k.sock:Send(w)
	end
end

function avatar:Release(onMapDestroy)
	self.path = nil
	if self.aoi_obj then
		Aoi.destroy_obj(self.aoi_obj,onMapDestroy or 0)
	end
	if self.robot then
		self.robot:Stop()
	end
	if not onMapDestroy then
		local idmgr = self.map.logic.freeidx
		idmgr:Release(bit32.band(self.id,0x0000FFFF))
	end
	Gate.UnBind(self)
	self.map.avatars[self.id] = nil
	self.map = nil
	self.Release = nil
	self:ClearTraceMe()
	self.isRelease = true
end

local function packWeapon(wpk,weapon)
	if weapon and  weapon.id then
		wpk:Write_uint16(weapon.id)
		wpk:Write_uint16(weapon.count)
		local wpos = wpk:Get_write_pos()
		wpk:Write_uint8(0)	
		if weapon.attr then
			local c = 0
			for k,v in pairs(weapon.attr) do
				wpk:Write_uint8(k)
				wpk:Write_uint32(weapon.attr[k])
				c = c + 1
			end
			wpk:Rewrite_uint8(wpos,c)
		end	
	else
		wpk:Write_uint16(0)
	end
end

function avatar:SendEnterSee(other)
	if not self.gatesession then
		return
	end
	local wpk = CPacket.NewWPacket(1024)
	wpk:Write_uint16(NetCmd.CMD_SC_ENTERSEE)
	wpk:Write_uint32(other.id)
	wpk:Write_uint8(other.avattype)
	wpk:Write_uint16(other.avatid)
	wpk:Write_string(other.nickname)
	wpk:Write_uint16(other.teamid)
	wpk:Write_uint16(other.pos[1])
	wpk:Write_uint16(other.pos[2])
	wpk:Write_uint16(other.dir)
	other.attr:on_entersee(wpk)
	wpk:Write_uint16(other.fashion or 0)
	packWeapon(wpk,other.weapon)
	self:Send2Client(wpk)
	
	if other.path then
		local size = #other.path.path
		local target = other.path.path[size]
		local wpk = CPacket.NewWPacket(64)
		wpk:Write_uint16(NetCmd.CMD_SC_MOV)
		wpk:Write_uint32(other.id)
		--wpk_write_uint16(wpk,other.speed)
		wpk:Write_uint16(target[1])
		wpk:Write_uint16(target[2])
		self:Send2Client(wpk)
	end
	if other.buff then 	
		other.buff:OnEnterSee(self)
	end	
end

function avatar:enter_see(other)
	if not other.hide then
		if self.robot then
			self.robot:NotifyEnterSee()
		end
		self.view_obj[other.id] = other
		other.watch_me[self.id] = self	
		self:SendEnterSee(other)
	end
end

function avatar:leave_see(other)
	if not other.hide then
		self.view_obj[other.id] = nil
		other.watch_me[self.id] = nil
		if self.gatesession then
			local wpk = CPacket.NewWPacket(64)
			wpk:Write_uint16(NetCmd.CMD_SC_LEAVESEE)
			wpk:Write_uint32(other.id)	
			self:Send2Client(wpk)
		end
	end	
end

function avatar:Mov(x,y)
	if self.isRelease or self:isDead() then
		return false
	end
	local path = self.map:findpath(self.pos,{x,y})
	if path then
		self.path = {cur=1,path=path}
		self.map:beginMov(self)
		self.lastmovtick = C.GetSysTick()
		self.movmargin = 0

		local size = #self.path.path
		local target = self.path.path[size]
		local wpk = CPacket.NewWPacket(64)
		wpk:Write_uint16(NetCmd.CMD_SC_MOV)
		wpk:Write_uint32(self.id)
		--wpk_write_uint16(wpk,self.speed)
		wpk:Write_uint16(target[1])
		wpk:Write_uint16(target[2])
		self:Send2view(wpk)
		return true			
	else
		local wpk = CPacket.NewWPacket(64)
		wpk:Write_uint16(NetCmd.CMD_SC_MOV_FAILED)
		self:Send2Client(wpk)
		return false			
	end
end

function avatar:UseSkill(rpk)
	if self.isRelease or self:isDead() then
		return
	end
	self.skillmgr:UseSkill(self,rpk)
end

function avatar:UseSkillByAi(skill,param)
	if self.isRelease or self:isDead() then
		return
	end
	self.skillmgr:UseSkillAi(self,skill,param)
end

function avatar:OnDead(atker,skillid)
	if self.isRelease then
		return
	end
	self.buff:OnAvatarDead()
	local maplogic = self.map.logic
	if maplogic and maplogic.OnAvatarDead then
		maplogic:OnAvatarDead(self,atker,skillid)
	end
	if self.robot then
		self.robot:Stop()
		self.robot = nil
	end
	self:StopMov()
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

--return false will break the process_mov
function avatar:process_mov()
	if self.isRelease or self:isDead() or not self.path then
		return false
	end		
	local path = self.path.path
	local now = C.GetSysTick()
	local movmargin = self.movmargin + now - self.lastmovtick	
	local cur  = self.path.cur
	local size = #path
	while cur <= size do
		local node = path[cur]
		local newdir = Util.Dir(self.pos,node)
		local dis = distance(newdir)
		local speed  = self.speed * grid_edge * 1.2
		local elapse = dis/speed * 1000
		if elapse < movmargin then
			self.dir = newdir
			self.pos = node
			--pos change,if there is a robot traceme,notify it target pos change
			self:NotifyTraceMe()
			cur = cur + 1
			movmargin = movmargin - elapse;			
			Aoi.moveto(self.aoi_obj,node[1],node[2]) 
			--[[Aoi.moveto may trigger stateMachine:NotifyEnterSee,in where map call StopMov
			so we must check self.path here]]--
			if not self.path then
				return false 
			end				
		else
			break	
		end
	end
	self.path.cur = cur
	self.movmargin = movmargin
	self.lastmovtick = C.GetSysTick()
	
	if self.path.cur > #self.path.path then
		self.path = nil
		local wpk = CPacket.NewWPacket(64)
		wpk:Write_uint16(NetCmd.CMD_SC_MOV_ARRI)
		self:Send2Client(wpk)
		if self.robot then
			self.robot:Wakeup() --if we have a robot,wake it up
		end
		return false
	else
		return true
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
	[1] = {-10,-10},
	[2] = {0,-12},
	[3] = {10,-10},
	[4] = {12,0},
	[5] = {10,10},
	[6] = {0,12},
	[7] = {-10,10},
	[8] = {-12,0}
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
		self.followdir = LinkQue.New()
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
		local tpos = Util.DirTo(self.map,self.pos,150,curdir)
		if tpos and not Util.CheckOverLap(self,tpos) then
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

return {
	New = function (...) 
		local arg = table.pack(...)
		if #arg > 0 then
			return avatar:new():Init(table.unpack(arg))
		else
			return avatar:new()
		end	
	end
}
