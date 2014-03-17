
local battles={}

function get_battle_instance(type)

end

function request_enter_battle(rpk,ply)
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
		local serviceid,battleid = get_battle_instance()
		if not serviceid or not battleid then
			--随机选择一个serviceid
			serviceid = math.rand(0,self.max_service)
			battleid = 0
		end
		enter_battle_map(serviceid,battleid,{{ply=ply.cply,attr=ply.attr:to_str(),skill=ply.skill:to_str(),item=ply.select_item}})						 		
	else
		--进入配对
	end
end
