--角色技能
skill = {
	dirty, --是否有脏数据  
}

function skill:new()
    local o = {}
    self.__index = self
    setmetatable(o, self)
    return o
end

function skill:to_str()

end

function skill:Save2DB()
	if self.dirty then
		self.dirty = false
	end	
end

function skill:Init(data)
	self.dirty = false
	return self
end
