--基本属性
base_attr = {
	attrs = nil,
	dirty, --是否有脏数据  
}

local attr_maxdb_index = 32 --此下标之前的属性需要保存到数据库
local attr_max_attr_index = 64

function base_attr:new()
    local o = {}
    self.__index = self
    setmetatable(o, self)
    return o
end

function base_attr:GetAttr(attr)
	if attr > attr_max_attr_index then
		return nil
	end
end

function base_attr:SetAttr(attr,value)
	if attr > attr_max_attr_index then
		return
	end
	if attr < attr_maxdb_index then
		self.dirty = true
	end	
end

function base_attr:to_str()

end

function base_attr:Init(data)
	self.dirty = false
	return self
end

function base_attr:Save2DB()
	if self.dirty then
		self.dirty = false
	end	
end
