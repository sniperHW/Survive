
local gamemgr = {
	con2game  = {},
	name2game = {}
}


local function game_login(rpk,conn)
	local name = rpk_read_string(rpk)
	if gamemgr.con2game[conn] == nil and gamemgr.name2game[name] == nil then
		local game = {conn=conn,name=name}
		gamemgr.con2game[conn] = game
		gamemgr.name2game[name] = game
		--通知所有gate新的game加入系统
	end
end

local function game_disconnected(rpk,conn)
	if gamemgr.con2game[conn] then
		local game = gamemgr.con2game[conn]
		gamemgr.con2game[conn] = nil
		gamemgr.name2game[game.name] = nil
	end
end

local function reg_cmd_handler()
	GroupApp.reg_cmd_handler(CMD_GAMEG_LOGIN,{handle=game_login})
	GroupApp.reg_cmd_handler(DUMMY_ON_GAME_DISCONNECTED,{handle=game_disconnected})
end


local function BoradCast(wpk)
	for k,_ in pairs(gamemgr.con2game) do
		local l_wpk = C.new_wpk_by_wpk(wpk)
		C.send(k,l_wpk)
	end
	destroy_wpk(wpk)
end

return {
	RegHandler = reg_cmd_handler,
	BoradCast = BoradCast,
}
