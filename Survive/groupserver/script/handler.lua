local gate = require "gate"
local game = require "game"

--注册各模块的消息处理函数
function reghandler()
	gate.RegHandler()
	game.RegHandler()
end