local Gate = require "gate"
local Game = require "game"
local Avatar = require "avatar"

--注册各模块的消息处理函数
function reghandler()
	Gate.RegHandler()
	Game.RegHandler()
end
