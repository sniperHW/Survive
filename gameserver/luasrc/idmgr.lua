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
	return self
end

function idmgr:get()
end

function idmgr:put(id)
end
