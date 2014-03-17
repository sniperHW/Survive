--在superservice中的player结构

dofile("bag.lua")
dofile("attr.lua")
dofile("skill.lua")

player = {
	cply = nil,        --C中的player对象
	select_item = nil, --玩家选择带入战场的物品
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
