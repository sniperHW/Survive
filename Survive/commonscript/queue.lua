local queue = {
	head = nil,
	tail = nil,
	size = 0,
}

function queue:new(o)
  o = o or {}   
  setmetatable(o, self)
  self.__index = self
  o.size = 0
  o.head = nil
  o.tail = nil
  return o
end

function queue:push(node)
    if not self.tail then
        self.head = node
        self.tail = node
	else
		self.tail.__next = node
		self.tail = node
	end
	self.size = self.size + 1
end

function queue:pop()
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
		return node
	end
end

function queue:is_empty()
	return self.size == 0
end

function queue:len()
	return self.size
end

return {
	Queue = function () return queue:new() end
}
