idmgr = {
	freeid = nil,
}

function idmgr:new()
    local o = {}
    self.__index = self
    setmetatable(o, self)
    return o
end

function idmgr:init(maxid)
	self.freeid = {}
	for i = 1,maxid do
		table.insert(self.freeid,i)
	end
	return self
end

function idmgr:get()
	return  table.remove(self.freeid) 
end

function idmgr:put(id)
	table.insert(self.freeid,id)
end
