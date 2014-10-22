package.cpath = "SurviveServer/?.so"
local Aoi = require "aoi"
local NetCmd = require "Survive.netcmd.netcmd"
local Buff = require "Survive.gameserver.buff"
local Attr = require "Survive.gameserver.attr"
local Skill = require "Survive.gameserver.skill"
local Time = require "lua.time"

local avatar ={
	id,            
	avatid,        
	pos,
	aoi_obj,
	see_radius,   
	view_obj,      
	watch_me,      
	gatesession,
	groupsession,
	map,          
	path,
	speed,         
	lastmovtick,   
	movmargin,     
	dir,           
	nickname,      
	skillmgr,
	attr,                 
}

function avatar:new()
  local o = {}   
  setmetatable(o, self)
  self.__index = self
  return o
end

function avatar:Init(id,avatid,map,nickname,actname,groupsession,attr,skillmgr,pos,dir,teamid)
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
	self.speed = 20
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

function avatar:Release(idmgr)
	if self.aoi_obj then
		Aoi.destroy_obj(self.aoi_obj)
	end
	idmgr:Release(bit32.band(self.id,0x0000FFFF))
end

function avatar:SendEnterSee(other)
	local wpk = CPacket.NewWPacket(1024)
	wpk:Write_uint16(NetCmd.CMD_SC_ENTERSEE)
	wpk:Write_uint32(other.id)
	wpk:Write_uint8(other.avattype)
	wpk:Write_uint16(other.avatid)
	--print("enter see avatid",other.avatid)
	wpk:Write_string(other.nickname)
	wpk:Write_uint16(other.teamid)
	wpk:Write_uint16(other.pos[1])
	wpk:Write_uint16(other.pos[2])
	wpk:Write_uint8(other.dir)
	other.attr:on_entersee(wpk)	
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
end

function avatar:enter_see(other)
	self.view_obj[other.id] = other
	other.watch_me[self.id] = self	
	self:SendEnterSee(other)

end

function avatar:leave_see(other)
	self.view_obj[other.id] = nil
	other.watch_me[self.id] = nil

	local wpk = CPacket.NewWPacket(64)
	wpk:Write_uint16(NetCmd.CMD_SC_LEAVESEE)
	wpk:Write_uint32(other.id)	
	self:Send2Client(wpk)	
end

function avatar:Mov(x,y)
	--print("player:Mov",x,y)
	local path = self.map:findpath(self.pos,{x,y})
	if path then
		self.path = {cur=1,path=path}
		self.map:beginMov(self)
		self.lastmovtick = Time.SysTick()
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
	self.skillmgr:UseSkill(self,rpk)
end

function avatar:UseSkillByAi(skill,param)
	print("avatar:UseSkillByAi")
	self.skillmgr:UseSkillAi(self,skill,param)
end

local array_direction = {
	[1] = {0,-1},--north
	[2] = {0,1}, --south
	[3] = {1,0}, --east
	[4] = {-1,0},--west
	[5] = {1,-1},--north east
	[6] = {-1,-1}, --north west
	[7] = {1,1},   --south east
	[8] = {-1,1}   --south west
}

local grid_edge = 8
local grid_diagonal = 8 * 1.41

local function direction(old_t,new_t,olddir)	
	for i = 1,8 do
		if old_t[1] + array_direction[i][1] == new_t[1] and old_t[2] + array_direction[i][2] == new_t[2] then
			return i
		end
	end
	return olddir
end

local function distance(dir)
	if dir <= 4 then
		return grid_edge
	else
		return grid_diagonal
	end
end

function avatar:process_mov()
	local now = Time.SysTick()
	local movmargin = self.movmargin + now - self.lastmovtick
	local path = self.path.path
	local cur  = self.path.cur
	local size = #path
	while cur <= size do
		local node = path[cur]
		local tmpdir = direction(self.pos,node,self.dir)
		local dis    =  distance(tmpdir)
		local speed  = self.speed * grid_edge
		local elapse = dis/speed * 1000
		if elapse < movmargin then
			self.dir = tmpdir
			self.pos = node
			cur = cur + 1
			movmargin = movmargin - elapse;			
			Aoi.moveto(self.aoi_obj,node[1],node[2])
		else
			break	
		end
	end
	self.path.cur = cur
	self.movmargin = movmargin
	self.lastmovtick = Time.SysTick()
	
	if self.path.cur > #self.path.path then
		self.path = nil
		local wpk = CPacket.NewWPacket(64)
		wpk:Write_uint16(NetCmd.CMD_SC_MOV_ARRI)
		self:Send2Client(wpk)
		--print("mov arrive")
		if self.robot then
			--print("wakeup robot")
			self.robot:Wakeup() --if we have a robot,wake it up
		end
		return true
	else
		return false
	end
end


return {
	New = function () return avatar:new() end
}
