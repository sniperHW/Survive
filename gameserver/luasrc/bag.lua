--背包
bag = {
	dirty, --是否有脏数据  
}

function bag:new()
    local o = {}
    self.__index = self
    setmetatable(o, self)
    return o
end

function bag:Init(data)
	self.dirty = false
end

function bag:Save2DB()
	if self.dirty then
		self.dirty = false
	end	
end
