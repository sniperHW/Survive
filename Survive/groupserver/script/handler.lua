local Gate = require "gate"
local Game = require "game"
local Dbmgr = require "dbmgr"

--注册各模块的消息处理函数
function reghandler()
	Gate.RegHandler()
	Game.RegHandler()
	return Dbmgr.Init()
end

