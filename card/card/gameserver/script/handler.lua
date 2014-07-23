local Game = require "script/game"
local Avatar = require "script/avatar"
local Dbmgr = require "script/dbmgr"

--注册各模块的消息处理函数
function reghandler()
	Game.RegHandler()
	return Dbmgr.Init()	
end
