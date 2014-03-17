battlemgr = {
	battles={}, --管理的所有battle
	max_service = 0,
}

function battlemgr:new()
    local o = {}
    self.__index = self
    setmetatable(o, self)
    return o
end

function battlemgr:init(max_service)
	self.max_service = max_service
	return self
end


function CreateBattleMgr(max_service)
	return battlemgr:new():init(max_service)
end

function battlemgr:get_battle_instance(type)

end

function battlemgr:on_enter_battle(rpk,ply)
	local type = rpk_read_uint8(rpk)
	local itemsize = rpk_read_uint8(rpk)
	if itemsize > 0 then
			
	end
	
	local battledef = battledefs[type]
	
	if battledef == nil then
		return INVAILD_BATTLE
	end
	
	if battledef.type == OPEN then
		--开放地图
		local serviceid,battleid = self:get_battle_instance()
		if not serviceid or not battleid then
			--随机选择一个serviceid
			serviceid = math.rand(0,self.max_service)
			battleid = 0
		end
		
		local plys = {}
		table.insert(plys,{ply=ply.cply,attr=ply.attr:to_str(),skill=ply.skill:to_str(),item=ply.select_item})
		enter_battle_map(serviceid,battleid,plys)						 		
	else
		--进入配对
	end
end

function battlemgr:tick(now)
	for k,v in pairs(self.battles) do
		v:tick(now)
	end
end
