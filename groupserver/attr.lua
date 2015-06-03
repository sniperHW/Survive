local Cjson = require "cjson"
local Name2idx = require "common.name2idx"
local NetCmd = require "netcmd.netcmd"
local Db = require "common.db"
local attr = {}

function attr:new()
  local o = {}   
  setmetatable(o, self)
  self.__index = self
  return o
end

function attr:Init(owner,baseinfo)
	self.owner = owner
	self.attr = {}
	for i=1,Name2idx.MaxIdx do
		if baseinfo[i] and type(v) ~= "userdata" then
			self.attr[i] = baseinfo[i]
		else
			self.attr[i] = 0
		end
	end
	--[[self.attr = baseinfo
	for k,v in pairs(self.attr) do
		if type(v) == "userdata" then
			self.attr[k] = 0
		end
	end]]--	
	return self
end

function attr:Get(name)
	local idx = Name2idx.Idx(name) or 0
	return self.attr[idx] or 0
end

function attr:OnBegPly(wpk)
	self:Pack(wpk,false)
end

function attr:Set(name,val)
	local idx = Name2idx.Idx(name) or 0
	if idx > 0 and self.attr[idx] ~= val then
		self.attr[idx] = val or 0
		self.flag = self.flag or {}
		self.flag[idx] = true
		self.dbchange = true		
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
		self.dbchange = true		
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
		self.dbchange = true		
		return new		
	end
	return nil
end

--return attr[name] >= val
function attr:MoreOrEq(name,val)
	local idx = Name2idx.Idx(name) or 0
	if idx > 0 then
		return self.attr[idx] >= val		
	end
	return false	
end

function attr:Pack(wpk,modfy)	
	if modfy and (not self.flag) then
		wpk:Write_uint8(0)
		return
	end
	local wpos = wpk:Get_write_pos()
	wpk:Write_uint8(0)
	local c = 0
	for k,v in pairs(self.attr) do	
		if (not modfy) or self.flag[k] then		
			wpk:Write_uint8(k)
			wpk:Write_uint32(self.attr[k] or 0)
			c = c + 1
		end
	end	
	wpk:Rewrite_uint8(wpos,c)			
end

--将属性的变更通知给客户端
function attr:Update2Client()	
	if not self.flag then
		return
	end
	local wpk = CPacket.NewWPacket(128)
	wpk:Write_uint16(NetCmd.CMD_GC_ATTRUPDATE)
	self:Pack(wpk,true)
	self.flag = nil
	self.owner:Send2Client(wpk)
end

function attr:DbStr()
	local t = {}
	for i = 1,Name2idx.attr_db_save do
		t[i] = self.attr[i] or 0
	end
	return Cjson.encode(t)
end

function attr:DbSave()
	if self.dbchange then
		local cmd = "hmset chaid:" .. self.owner.chaid .. " chainfo  " .. self:DbStr()
		Db.CommandAsync(cmd)
		self.dbchange = false
	end
end

--将game需要用到的属性对提取出来
function attr:Pack2Game()
	local t = {}
	for k,v in pairs(self.attr) do
		t[k] = v
	end
	return t
end

function attr:ClearFlag()
	self.flag = nil
end

return {
	New = function () return attr:new() end,
}
