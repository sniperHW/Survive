local Cjson = require "cjson"
local Name2idx = require "Survive/common/name2idx"
local NetCmd = require "Survive/netcmd/netcmd"
local attr = {}

--需要同步到视野的属性
local attr2view ={
	level = 1,--角色等级
	life = 23,    --当前生命
	maxlife = 24, --最大生命
}


function attr:new(o)
  local o = o or {}   
  setmetatable(o, self)
  self.__index = self
  return o
end

function attr:Init(avatar,baseinfo)
	self.attr = {}
	for k,v in pairs(baseinfo) do
		if type(v) ~= "userdata" then
			self.attr[k] = v
		end
	end
	self.avatar = avatar		
	return self
end

function attr:Get(name)
	local idx = Name2idx.Idx(name) or 0
	return self.attr[idx]
end

function attr:Set(name,val)
	local idx = Name2idx.Idx(name) or 0
	if self.attr[idx] then
		self.attr[idx] = val
		self.flag = self.flag or {}
		self.flag[idx] = true
	end
end

function attr:on_entermap(wpk)
	local wpos = wpk:Get_write_pos()
	wpk:Write_uint8(0)
	local c = 0
	for k,v in pairs(self.attr) do
		wpk:Write_uint8(k)
		wpk:Write_uint32(self.attr[k])
		c = c + 1
	end			
	wpk:Rewrite_uint8(wpos,c)	
end

function attr:on_entersee(wpk)
	local wpos = wpk:Get_write_pos()
	wpk:Write_uint8(0)
	local c = 0
	for k,v in pairs(self.attr) do
		if attr2view[Name2idx.Name(k)] then
			wpk:Write_uint8(k)
			wpk:Write_uint32(self.attr[k])
			c = c + 1
		end
	end				
	wpk:Rewrite_uint8(wpos,c)				
end

--将变更通告到视野和自身
function attr:NotifyUpdate()	
	--发送到视野的与发送到自身的包要区分开来,因为到视野的属性少而到自身的属性多	
	if not self.flag then
		return
	end		
	local wpk2view = CPacket.NewWPacket(128)
	local wpk2self = CPacket.NewWPacket(128)	
	wpk2view:Write_uint16(NetCmd.CMD_SC_ATTRUPDATE)
	wpk2self:Write_uint16(NetCmd.CMD_SC_ATTRUPDATE)
	wpk2view:Write_uint32(self.avatar.id)
	wpk2self:Write_uint32(self.avatar.id)			
	local wpos1 = wpk2view:Get_write_pos()
	local c1 = 0	
	wpk2view:Write_uint8(0)
	local wpos2 = wpk2self:Get_write_pos()
	local c2 = 0	
	wpk2self:Write_uint8(0)
	for k,v in pairs(self.attr) do		
		if self.flag[k] then
			if attr2view[Name2idx.Name(k)] then
				wpk2view:Write_uint8(k)
				wpk2view:Write_uint32(self.attr[k])
				c1 = c1 + 1
			end
			wpk2self:Write_uint8(k)
			wpk2self:Write_uint32(self.attr[k])			
			c2 = c2 + 1						
		end
	end
	
	if c1 > 0 then
		wpk2view:Rewrite_uint8(wpos1,c1)
		self.avatar:Send2view(wpk2view,{self.avatar})
	end
	
	if c2 > 0 then
		wpk2self:Rewrite_uint8(wpos2,c2)
		self.avatar:Send2Client(wpk2self)
	end		
	self.flag = nil		
end

return {
	New = function () return attr:new() end,
}
