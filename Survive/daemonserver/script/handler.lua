local Gate = require "script/gate"
local Game = require "script/game"
local Dbmgr = require "script/dbmgr"
local Player = require "script/player"
local Rpc = require "script/rpc"
local Cjson = require "cjson"

local forbidwords = {}
table.insert(forbidwords,"共产党")

--注册各模块的消息处理函数
function reghandler(dbconfig)
	dbconfig = Cjson.decode(dbconfig)
	Rpc.RegHandler()
	return Dbmgr.Init(dbconfig)
end


