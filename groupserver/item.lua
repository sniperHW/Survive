--游戏道具
local item = {}


function item:new(id,count,attr)
  local o = {}   
  setmetatable(o, self)
  self.__index = self
  o.id = id
  o.count = count
  o.attr = attr
  return o	
end

function item:Pack(wpk)
	wpk:Write_uint16(self.id)
	wpk:Write_uint16(self.count)
	local wpos = wpk:Get_write_pos()
	wpk:Write_uint8(0)	
	if self.attr then
		local c = 0
		for k,v in pairs(self.attr) do
			wpk:Write_uint8(k)
			wpk:Write_uint32(self.attr[k])
			c = c + 1
		end
		wpk:Rewrite_uint8(wpos,c)
	end
end

function item:GetAttr(idxs)
	if self.attr then
		local ret = {}
		for i=1,#idxs do
			table.insert(ret,self.attr[idxs[i]])
		end
		if #ret > 0 then
			return table.unpack(ret)
		end
	end
	return nil
end

function item:SetAttr(idxs,vals)
	if not self.attr then
		self.attr = {}
	end
	for i=1,#idxs do
		self.attr[idxs[i]] = vals[i]
	end
end

function item:GetAttrHigh(idx)
	if self.attr then
		local attr = self.attr[idx]
		if attr then
			return bit32.rshift(attr,16)
		end
	end
	return nil
end

function item:GetAttrLow(idx)
	if self.attr then
		local attr = self.attr[idx]
		if attr then
			return bit32.band(attr,0x0000FFFF)
		end
	end
	return nil	
end

function item:SetAttrHigh(idx,val)
	if self.attr then
		local attr = self.attr[idx]
		if attr then
			attr = bit32.band(attr,0x0000FFFF)
			attr = bit32.bor(bit32.lshift(val,16),attr)
			self.attr[idx] = attr
		end
	end
end

function item:SetAttrLow(idx,val)
	if self.attr then
		local attr = self.attr[idx]
		if attr then
			attr = bit32.band(attr,0xFFFF0000)
			attr = attr + val
			self.attr[idx] = attr
		end
	end
end

function PackEmpty(wpk)
	wpk:Write_uint16(0)
	wpk:Write_uint16(0)
	wpk:Write_uint8(0)	
end

return {
	New = function (id,count,attr) return item:new(id,count,attr) end,
	PackEmpty = PackEmpty
}
