local Gate = require "gate"
local Game = require "game"
local Dbmgr = require "dbmgr"



local forbidwords = {}
table.insert(forbidwords,"共产党")

--注册各模块的消息处理函数
function reghandler()
	Gate.RegHandler()
	Game.RegHandler()
	initwordfilter(forbidwords)
	return Dbmgr.Init()
end

