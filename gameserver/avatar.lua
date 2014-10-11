package.cpath = "Survive/?.so"
local Aoi = require "aoi"
local NetCmd = require "Survive/netcmd/netcmd"

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

function avatar:Init(id,avatid)
	self.id = id
	self.avatid = avatid
	self.avattype = 0
	self.see_radius = 5
	self.view_obj = {}
	self.watch_me = {}
	self.gate = nil
	self.map =  nil
	self.path = nil
	self.speed = 20
	self.pos = nil
	self.nickname = ""
	self.aoi_obj = Aoi.create_obj(self)
	return self
end

function avatar:Send2Client(wpk)
end


function avatar:Send2view(wpk,exclude) --exclude排除列表
	--将玩家分组,同gateserver的玩家为一组,发送一个统一的包	
	exclude = exclude or {}	
	local gates = {}
	for k,v in pairs(self.watch_me) do
		if v.gatesession and (not exclude[v]) then
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

function avatar:enter_see(other)
	self.view_obj[other.id] = other
	other.watch_me[self.id] = self	
	
	local wpk = CPacket.NewWPacket(1024)
	wpk:Write_uint16(NetCmd.CMD_SC_ENTERSEE)
	wpk:Write_uint32(other.id)
	wpk:Write_uint8(other.avattype)
	wpk:Write_uint16(other.avatid)
	wpk:Write_string(other.nickname)
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

function avatar:leave_see(other)
	self.view_obj[other.id] = nil
	other.watch_me[self.id] = nil

	local wpk = CPacket.NewWPacket(64)
	wpk:Write_uint16(NetCmd.CMD_SC_LEAVESEE)
	wpk:Write_uint32(other.id)	
	self:Send2Client(wpk)	
end

return {
	New = function () return avatar:new() end
}
