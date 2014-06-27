ATTR_HP = 1
ATTR_MP = 2
ATTR_SPEED = 3

local attr = {
	attr,
}

function attr:new(o)
  o = o or {}   
  setmetatable(o, self)
  self.__index = self
  self.attr = {}
  return o
end

function attr:init(attr)	
	for k,v in pairs(attr) do
		self.attr[k] = {v=v,dirty=false}
	end	
end

function attr:pack(wpk)
	wpk_write_uint16(#self.attr)
	for k,v in pairs(self.attr) do
		wpk_write_uint16(k)
		wpk_write_uint32(v.v)
	end		
end

function attr:updata2client(ply)
	local tmp
	local c
	for k,v in pairs(self.attr) do
		if v.dirty then
			c = c + 1
			tmp[k] = v.v
			v.dirty = false
		end
	end		
	if c > 0 then
		local wpk = new_wpk()
		wpk_write_uint16(wpk,CMD_GC_UPDATEATTR)	
		wpk_write_uint16(#tmp)
		for k,v in pairs(tmp) do
			wpk_write_uint16(k)
			wpk_write_uint32(v)
		end
		ply:send2gate(wpk)			
	end	
end

function attr:save2db(ply)
	
end

function attr:get(idx)
	return self.attr[idx]
end

function attr:set(idx,v)
	local attr = self.attr[idx]
	if attr and attr.v ~= v then
		attr.dirty = true
		attr.v = v
	end
end

return {
	NewAttr = function () attr:new() end,
}
