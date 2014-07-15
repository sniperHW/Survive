local Gate = require "script/gate"
local Game = require "script/game"
local Avatar = require "script/avatar"
local Dbmgr = require "script/dbmgr"
local Rpc = require "script/rpc"
--local MapConfig = require "script/mapconfig"

--注册各模块的消息处理函数
function reghandler()
	Gate.RegHandler()
	Game.RegHandler()
	Rpc.RegHandler()

	--[[local mapdef = MapConfig.GetDefByType(1)
	GameApp.create_aoimap(mapdef.gridlength,
			   mapdef.radius,mapdef.toleft[1],mapdef.toleft[2],mapdef.bottomright[1],mapdef.bottomright[2])	
--]]	
	
	return Dbmgr.Init()	
end
