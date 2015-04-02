local Name2idx = require "src.net.name2idx"
local NetCmd = require "src.net.NetCmd"
local attr = {}

function attr:new()
  local o = {} 
  self.__index = self 	   
  setmetatable(o, self)
  return o
end

function attr:Init(avatar,baseinfo)
	self.attr = {}
	for k,v in pairs(baseinfo) do
		local idx = Name2idx.Idx(k)
		if idx then
			self.attr[idx] = v
		end
	end
	self.attr[Name2idx.Idx("life")] = self.attr[Name2idx.Idx("maxlife")]
	self.avatar = avatar
	self.name = "attr"
	print("attr:init",self)		
	return self
end

function attr:Get(name)
	local idx = Name2idx.Idx(name) or 0
	return self.attr[idx] or 0
end

function attr:Set(name,val)
	local idx = Name2idx.Idx(name) or 0
	if self.attr[idx] then
		self.attr[idx] = val
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

function attr:pack(wpk)
	local _attr = {}
	local c = 0
	for k,v in pairs(self.attr) do
		table.insert(_attr,{k,self.attr[k]})
		c = c + 1
	end
	WriteUint8(wpk,c)
	for k,v in pairs(_attr) do
		WriteUint8(wpk,v[1])
		WriteUint32(wpk,v[2])
	end		
end

function attr:on_entersee(wpk)
	self:pack(wpk)	
end

--将变更通告到视野和自身
function attr:NotifyUpdate()
	local wpk = GetWPacket()
	WriteUint16(wpk,NetCmd.CMD_SC_ATTRUPDATE)
	WriteUint32(wpk,self.avatar.id)
	self:pack(wpk)	
	Send2Client(wpk)		
end

return {
	New = function (avatar,baseinfo) return attr:new():Init(avatar,baseinfo) end,
}
