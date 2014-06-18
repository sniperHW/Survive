local Gate = require "gate"
local Game = require "game"

--注册各模块的消息处理函数
function reghandler()
	Gate.RegHandler()
	Game.RegHandler()
end

--[[
function callback(_,error,result)
	print(result[1])	
	print(result[2])	
end

function on_redis_connect(_,conn,err)
	if conn then 
		print("connect to redis ok")
		C.redisCommand(conn,"hmget huangwei age location",{callback = callback})
	end
end

function on_redis_disconnect(_,conn)

end

function test()
	local ret = C.redis_connect("127.0.0.1",6379,{on_connect = on_redis_connect,
					on_disconnect = on_redis_disconnect})
	if not ret then
		print("connect to redis error")	
	end
end
]]--
