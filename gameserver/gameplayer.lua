package.cpath = "Survive/?.so"
local Avatar = require "Survive/gameserver/avatar"
local NetCmd = require "Survive/netcmd/netcmd"
local Aoi = require "aoi"

local player = Avatar.New()

function player:new()
	local o = {}
	setmetatable(o, self)
	self.__index = self
	return o	
end

function player:Send2Client(wpk)
	local gatesession = self.gatesession
	if gatesession then
		local wpk1 = CPacket.NewWPacket(256)
		local rpk = CPacket.NewRPacket(wpk)
		wpk1:Write_uint16(rpk:Read_uint16())
		wpk1:Write_wpk(wpk)
		wpk1:Write_uint16(1)
		wpk1:Write_uint32(gatesession.sessionid)
		gatesession.sock:Send(wpk1)
	end	
end

function player:on_entermap()
	local wpk = CPacket.NewWPacket(64)
	wpk:Write_uint16(NetCmd.CMD_SC_ENTERMAP)
	wpk:Write_uint16(self.map.maptype)
	self.attr:on_entermap(wpk)
	wpk:Write_uint32(self.id)
	local gatesession = self.gatesession
	if gatesession then
		local wpk1 = CPacket.NewWPacket(256)
		local rpk = CPacket.NewRPacket(wpk)
		wpk1:Write_uint16(rpk:Read_uint16())
		wpk1:Write_wpk(wpk)
		wpk1:Write_uint16(1)
		wpk1:Write_uint32(gatesession.sessionid)
		wpk1:Write_uint32(self.id)
		gatesession.sock:Send(wpk1)
	end			
end

function player:Mov(x,y)
	--print("player:Mov")
	local path = self.map:findpath(self.pos,{x,y})
	if path then
		self.path = {cur=1,path=path}
		self.map:beginMov(self)
		self.lastmovtick = GetSysTick()
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
	else
		local wpk = CPacket.NewWPacket(64)
		wpk:Write_uint16(NetCmd.CMD_SC_MOV_FAILED)
		self:Send2Client(wpk)			
	end
end

--客户端断线重连处理
function player:ReConnect(maptype)
	self:on_entermap()	
	for k,v in pairs(self.view_obj) do
		local wpk = CPacket.NewWPacket(1024)
		wpk:Write_uint16(NetCmd.CMD_SC_ENTERSEE)
		wpk:Write_uint32(v.id)
		wpk:Write_uint8(v.avattype)
		wpk:Write_uint16(v.avatid)
		wpk:Write_string(v.nickname)
		wpk:Write_uint16(v.pos[1])
		wpk:Write_uint16(v.pos[2])
		wpk:Write_uint8(v.dir)
		v.attr:on_entersee(wpk)			
		self:Send2Client(wpk)
	
		if v.path then
			local size = #v.path.path
			local target = v.path.path[size]
			local wpk = CPacket.NewWPacket(64)
			wpk:Write_uint16(NetCmd.CMD_SC_MOV)
			wpk:Write_uint32(v.id)
			--wpk_write_uint16(wpk,other.speed)
			wpk:Write_uint16(target[1])
			wpk:Write_uint16(target[2])
			self:Send2Client(wpk)
		end		
	end
end

function player:UseSkill(rpk)
	print("player:UseSkill")
	self.skillmgr:UseSkill(self,rpk)
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

function player:process_mov()
	local now = GetSysTick()
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
	self.lastmovtick = GetSysTick()
	
	if self.path.cur > #self.path.path then

		self.path = nil
		local wpk = CPacket.NewWPacket(64)
		wpk:Write_uint16(NetCmd.CMD_SC_MOV_ARRI)
		self:Send2Client(wpk)
		return true
	else
		return false
	end
end

return {
	New = function (id,avatid) return player:new():Init(id,avatid) end,
} 
