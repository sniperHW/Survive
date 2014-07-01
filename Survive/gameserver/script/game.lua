local Map = require "map"
local Que = require "queue"

local game = {
	id,
	maps,
	freeidx,
}

function game_init(id)
	game.id = id
	game.maps = {}
	local que = Que.Queue()
	for i=1,65536 do
		que:push({v=i,__next=nil})
	end
	game.freeidx = que
end


local function GGAME_ENTERMAP(_,rpk,conn)
	local mapid = rpk_read_uint16(rpk)
	local maptype = rpk_read_uint8(rpk)
	if not mapid then
		--创建实例
		mapid = game.freeidx:pop()
		if not mapid then
			--TODO 通知group,gameserver繁忙
		else
			local map = Map.NewMap():init(mapid,maptype)
			game.maps[mapid] = map
			map:entermap(rpk)
		end
	else
		local map = game.maps[mapid]
		if not map then
			--TODO 通知group错误的mapid(可能实例已经被销毁)
		else
			map:entermap(rpk)
		end
	end
end

local function CGAME_LEAVEMAP(_,rpk,conn)
	local mapid = rpk_read_uint16(rpk)
	local map = game.maps[mapid]
	if map then
		local plyid = rpk_read_uint16(rpk)
		map:leavemap(plyid)
	end
end


local function GGAME_DESTROYMAP(_,rpk,conn)
	local mapid = rpk_read_uint16(rpk)
	local map = game.maps[mapid]
	if map then
		map:clear()
		game.que:push({v=mapid,__next=nil})
		game.maps[mapid] = nil
	end
end


local function reg_cmd_handler()
	GroupApp.reg_cmd_handler(CMD_GGAME_ENTERMAP,{handle=GGAME_ENTERMAP})
	GroupApp.reg_cmd_handler(CMD_CGAME_LEAVEMAP,{handle=CGAME_LEAVEMAP})
	GroupApp.reg_cmd_handler(CMD_GGAME_DESTROYMAP,{handle=GGAME_DESTROYMAP})	
end

return {
	RegHandler = reg_cmd_handler,
}


