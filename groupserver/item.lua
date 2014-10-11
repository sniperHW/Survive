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
		wpk:Rewrite_uint8(pos,c)
	end
end

function item:GetAttr(idx)
	if self.attr then
		return self.attr[idx]
	else
		return nil
	end
end

function item:SetAttr(idx,val)
	if not self.attr then
		self.attr = {}
	end
	self.attr[idx] = val
end

return {
	New = function (id,count,attr) return item:new(id,count,attr) end
}
