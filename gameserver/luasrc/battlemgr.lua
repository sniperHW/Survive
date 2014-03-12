battlemgr = {
	battles={}, --管理的所有battle
}

function battlemgr:new()
    local o = {}
    self.__index = self
    setmetatable(o, self)
    return o
end

function battlemgr:init()
	
	return self
end


function CreateBattleMgr()
	return battlemgr:new():init()
end

--创建战场
function battlemgr:CreateBattle()

end

function battlemgr:tick(now)
	for k,v in pairs(self.battles) do
		v:tick(now)
	end
end
