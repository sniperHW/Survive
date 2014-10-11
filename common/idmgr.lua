local Que = require "lua/queue"
local idmgr = {}

function idmgr:new(size)
  local o = o or {}   
  setmetatable(o, self)
  self.__index = self
  o.idx = Que.New()
  for i=1,size do
	o.idx:Push({v=i})
  end 
  return o	
end

function idmgr:Get()
	local n = self.idx:Pop()
	if n then 
		return n.v
	else
		return nil
	end
end

function idmgr:Release(id)
	self.idx:Push({v=idx})
end

function idmgr:Len()
	return self.idx:Len()
end

return {
	New = function (size) return idmgr:new(size) end
}
