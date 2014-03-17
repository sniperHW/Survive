battlemgr = {
	battles={}, --管理的所有battle
	idmgr = nil,
}

function battlemgr:new()
    local o = {}
    self.__index = self
    setmetatable(o, self)
    return o
end

function battlemgr:init()
	self.idmgr = idmgr:new():init(65536)
	return self
end

function battlemgr:enter_battle(type,battleid,plys)
	if battleid == 0 then
		--新建战场
		battle = battle:new():init(type)
		local battleid = self.idmgr:get()
		self.battles[battleid] = battle		
		if battledefs[type].type == OPEN then
			--通知super创建了新的开放地图实例
		end		
	end
	self.battles[battleid]:enter(plys)
end


function CreateBattleMgr()
	return battlemgr:new():init()
end

function battlemgr:tick(now)
	for k,v in pairs(self.battles) do
		v:tick(now)
	end
end
