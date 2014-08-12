local Dbmgr = require "script/dbmgr"
local Rpc = require "script/rpc"
local Machine = require "script/machine"


local dbconfig ={
	["deploy_db"] = {ip="127.0.0.1",port=6379}
}

function reghandler()
	Rpc.RegHandler()
	Machine.RegHandler()
	return Dbmgr.Init(dbconfig)
end


