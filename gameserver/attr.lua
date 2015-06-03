local Cjson = require "cjson"
local Name2idx = require "common.name2idx"
local NetCmd = require "netcmd.netcmd"
local attr = {}

--需要同步到视野的属性
local attr2view ={
	level = true,--角色等级
	life = true,    --当前生命
	maxlife = true, --最大生命
}


function attr:new()
  local o = {} 
  self.__index = self 	   
  setmetatable(o, self)
  return o
end

function attr:Init(avatar,baseinfo)
	self.attr = {}
	for k,v in pairs(baseinfo) do
		if type(v) ~= "userdata" then
			self.attr[k] = v
		end
	end
	self.attr[Name2idx.Idx("life")] = self.attr[Name2idx.Idx("maxlife")]
	--for k,v in pairs(self.attr) do
	--	print(k,v)
	--end		
	self.avatar = avatar		
	return self
end

function attr:Get(name)
	local idx = Name2idx.Idx(name) or 0
	return self.attr[idx] or 0
end

function attr:Set(name,val)
	local idx = Name2idx.Idx(name) or 0
	if self.attr[idx] then
		self.attr[idx] = val or 0
		self.flag = self.flag or {}
		self.flag[idx] = true
	end
end

function attr:Add(name,val,max)
	if val < 0 then
		return nil
	end
	local idx = Name2idx.Idx(name) or 0
	if idx > 0 then
		local old = self.attr[idx]
		local new = old + val
		if new < old or new > 0xFFFFFFFF then
			new = 0xFFFFFFFF
		end
		if max and new > max then
			new = max
		end		
		self.attr[idx] = new or 0
		self.flag = self.flag or {}
		self.flag[idx] = true
		return new		
	end
	return nil
end

function attr:Sub(name,val)
	if val < 0 then
		return nil
	end
	local idx = Name2idx.Idx(name) or 0
	if idx > 0 then
		local old = self.attr[idx]
		local new = old - val
		if new < 0 or new > old then
			new = 0
		end
		self.attr[idx] = new or 0
		self.flag = self.flag or {}
		self.flag[idx] = true
		return new		
	end
	return nil
end

function attr:on_entermap(wpk)
	local wpos = wpk:Get_write_pos()
	wpk:Write_uint8(0)
	local c = 0
	for k,v in pairs(self.attr) do
		wpk:Write_uint8(k)
		wpk:Write_uint32(self.attr[k] or 0)
		--print(k,self.attr[k])
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
			wpk:Write_uint32(self.attr[k] or 0)
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
				wpk2view:Write_uint32(self.attr[k] or 0)
				c1 = c1 + 1
			end
			wpk2self:Write_uint8(k)
			wpk2self:Write_uint32(self.attr[k] or 0)			
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
	New = function (avatar,baseinfo) return attr:new():Init(avatar,baseinfo) end,
}
