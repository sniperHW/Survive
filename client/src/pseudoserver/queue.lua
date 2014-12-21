local queue = {}

function queue:new(o)
	  local o = o or {}   
	  setmetatable(o, self)
	  self.__index = self
	  o.size = 0
	  o.head = {}
	  o.tail = {}
	  o.size = 0
	  o.head.__pre = nil
	  o.head.__next = o.tail
	  o.tail.__next = nil
	  o.tail.__pre = o.head
	  return o
end

function queue:Push(node)
	if node.__owner then
		return 
	end
	self.tail.__pre.__next = node
	node.__pre = self.tail.__pre
	self.tail.__pre = node
	node.__next = self.tail
	node.__owner = self
	self.size = self.size + 1	

end

function queue:Front()
    if self.size > 0 then
	return self.head.__next
    else
	return nil
    end	
end

function queue:Pop()
	if self.size > 0 then

	end
end

function queue:Remove(node)
	if node.__owner == self and self.size > 0 then
		node.__pre.__next = node.__next
		node.__next.__pre = node.__pre
		node.__next = nil
		node.__pre = nil
		node.__owner = nil
		self.size = self.size - 1
	end
end

function queue:Pop()
	if self.size > 0 then
		local node = self.head.__next
		self:Remove(node)
		return node
	else
		return nil
	end
end

function queue:IsEmpty()
	return self.size == 0
end

function queue:Len()
	return self.size
end

return {
	New = function () return queue:new() end
}


--[[
local queue = {
	head = nil,
	tail = nil,
	size = 0,
}

function queue:new(o)
  local o = o or {}   
  setmetatable(o, self)
  self.__index = self
  o.size = 0
  o.head = nil
  o.tail = nil
  return o
end

function queue:Push(node)
    if node.__que then
    	print(debug.traceback())
    	print(node.status)	
    	--Break()
    	node.__que:Remove(node)
    end
    if not self.tail then
        	self.head = node
        	self.tail = node
    else
	self.tail.__next = node
	self.tail = node
    end
    node.__que = self
   self.size = self.size + 1
end

function queue:Front()
    if not self.head then
		return nil
	else
		return self.head
	end	
end

function queue:Pop()
    if not self.head then
		return nil
	else
		local node = self.head
		local next = node.__next
		if next == nil then
			self.head = nil
			self.tail = nil
		else
			self.head = next
		end
		self.size = self.size - 1
		node.__next = nil
		node.__que = nil
		return node
	end
end

function queue:Remove(ele)
	local cur = self.head
	local pre = self.head
	while cur do
		if cur == ele then
			self.size = self.size - 1
			if self.size == 0 then
				self.head = nil
				self.tail = nil
			elseif cur == self.head then
				--head
				self.head = cur.__next
			else
				pre.__next = ele.__next
				if pre.__next == nil then
					self.tail = pre
				end
			end
			ele.__next = nil
			ele.__que = nil						
			return
		else
			pre = cur
			cur = cur.__next
		end	
	end	
end

function queue:IsEmpty()
	return self.size == 0
end

function queue:Len()
	return self.size
end

return {
	New = function () return queue:new() end
}]]--