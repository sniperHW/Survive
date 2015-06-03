local Que = {}

function Que:new(o)
	  local o = o or {}   
	  setmetatable(o, self)
	  self.__index = self
	  o.data = {}
	  return o
end

function Que:Push(v)
	table.insert(self.data,v)
end

function Que:Front()
	if #self.data > 0 then
		return self.data[1]
	else
		return nil
	end
end


function Que:Pop()
	if #self.data > 0 then
		local r = self.data[1]
		table.remove(self.data,1)
		return r
	else
		return nil
	end
end

function Que:IsEmpty()
	return #self.data == 0
end

function Que:Len()
	return #self.data
end

return {
	New = function () return Que:new() end
}