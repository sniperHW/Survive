--在superservice中的player结构
--基本属性
base_attr = {
	attrs = nil,
	dirty, --是否有脏数据  
}

function base_attr:new()
    local o = {}
    self.__index = self
    setmetatable(o, self)
    return o
end

function base_attr:GetAttr(attr)

end

function base_attr:SetAttr(attr,value)
	self.dirty = true
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

function skill:Save2DB()
	if self.dirty then
		self.dirty = false
	end	
end

function skill:Init(data)
	self.dirty = false
	return self
end

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

player = {
	cply = nil, --C中的player对象
}

function player:new()
    local o = {}
    self.__index = self
    setmetatable(o, self)
    return o
end

function player:init()
		
	return self
end

function CreateLuaPlayer(cply,data)
	  local lply = player:new()
	  lply.ply = cply
	  lply.attr = base_attr:new():Init(data[1])
	  lply.bag = bag:new():Init(data[2])
	  lply.skill = skill:new():Init(data[3])	  
	  --通知客户端，进入游戏成功
	  return lply
end
