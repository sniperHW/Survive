local Cjson = require "cjson"
local Name2idx = require "Survive/common/name2idx"
local NetCmd = require "Survive/netcmd/netcmd"
local Db = require "Survive/common/db"
local Item = require "Survive/groupserver/item"
local bag = {}

function bag:new()
  local o = {}   
  setmetatable(o, self)
  self.__index = self
  return o
end

function bag:Init(bag)
	self.bag = bag or {size=60}
	return self
end

function bag:GetItemId(pos)
	if pos > 6 and self.bag[pos] then
		return self.bag[pos].id
	else
		return nil
	end
end

function bag:GetItemCount(pos)
	if pos > 6 and self.bag[pos] then
		return self.bag[pos].count
	else
		return nil
	end
end

function bag:GetItemAttr(pos,idx)
	if pos > 6 and self.bag[pos] then
		return self.bag[pos]:GetAttr(idx)
	else
		return nil
	end
end

function bag:SetItemAttr(pos,idx,val)
	if pos > 6 and self.bag[pos] then
		self.bag[pos]:SetAttr(idx,val)
		self.flag = self.flag or {}
		self.flag[pos] = true
	end	
end

local function findpos(self,id)
	if not id then
		for i=11,self.bag.size do
			if not self.bag[i] then
				return i
			end
		end
		return nil
	else
		local firstempty = nil
		for i=11,self.bag.size do
			if not self.bag[i] then
				firstempty = i
			elseif self.bag[i].id == id then
				return i
			end
		end
		return firstempty		
	end
end

--向背包新增加一个物品
function bag:AddItem(id,count,attr)
	if attr then
		local pos = findpos(self)
		if pos then
			self.bag[pos] = Item.New(id,count,attr)
			self.flag = self.flag or {}
			self.flag[pos] = true
			return true
		else
			return false
		end
	else
		local pos = findpos(self.id)
		if pos then
			if self.bag then
				self.bag[pos] = Item.New(id,count,attr)	
			else
				self.bag[pos].count = self.bag[pos].count + 1
			end
			self.flag = self.flag or {}			
			self.flag[pos] = true
			return true					
		else
			return false
		end
	end
end

--根据位置或id移除一定数量的物品
function bag:RemItem(pos,id,count)
	if id then
		for i=11,self.bag.size do
			if self.bag[i] and self.bag[i].id == id then
				pos = i
			end
		end
	end
	local item = self.bag[pos]
	if item and item.count >= count then
		item.count = item.count - count
		if item.count == 0 then
			self.bag[pos] = nil
		end
		self.flag = self.flag or {}
		self.flag[i] = true
		return true
	else
		return false
	end	
end

function bag:OnBegPly(wpk)
	--先打包battle相关
	wpk:Write_uint8(self.bag.size)
	wpk:Write_uint8(self.bag[1] or 0)
	wpk:Write_uint8(self.bag[2] or 0)
	wpk:Write_uint8(self.bag[3] or 0)
	wpk:Write_uint8(self.bag[4] or 0)
	wpk:Write_uint8(self.bag[5] or 0)
	wpk:Write_uint8(self.bag[6] or 0)		
	local wpos = wpk:Get_write_pos()
	wpk:Write_uint8(0)	
	local c = 0
	for k,v in pairs(self.bag) do
		if type(k) == "number" and k > 6 then
			wpk:Write_uint8(k)
			v:Pack(wpk)
			c = c + 1
		end
	end
	wpk:Rewrite_uint8(wpos,c)	
end

function bag:DbStr()
	return Cjson.encode(self.bag)
end

function bag:Save(ply)
	local cmd = "hmset chaid:" .. ply.chaid .. " bag  " .. self:DbStr()
	Db.Command(cmd)	
end

return {
	New = function () return bag:new() end,
}
