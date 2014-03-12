battle = {
	avatars={}, --地图上所有的avatar
	aoi = nil,  --视野处理
	path = nil, --寻路处理
}

function battle:new()
    local o = {}
    self.__index = self
    setmetatable(o, self)
    return o
end

function battle:init()
	self.aoi = NewAoiMap()
	self.path = CreateAstarMap()
	--创建地图上的资源,NPC等
	
	return self
end

function battle:ondestroy()
	DestroyAstarMap(self.path)
	DestroyAoiMap(self.aoi)
end

--地图定时器函数
function battle:tick(now)
	--处理地图上avatar的位置移动和视野移动
end


