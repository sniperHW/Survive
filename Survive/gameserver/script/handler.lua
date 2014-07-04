local Gate = require "script/gate"
local Game = require "script/game"
local Avatar = require "script/avatar"
local Dbmgr = require "script/dbmgr"
local Rpc = require "script/rpc"

--注册各模块的消息处理函数
function reghandler()
	Gate.RegHandler()
	Game.RegHandler()
	Rpc.RegHandler()
	return Dbmgr.Init()	
end
