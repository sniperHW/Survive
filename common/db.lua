local Redis = require "lua/redis"
local Sche = require "lua/sche"

local toredis

--建立到redis的连接
local function connect_to_redis()
    if toredis then
		print("to redis disconnected")
    end
    toredis = nil
	Sche.Spawn(function ()
		while true do
			local err
			err,toredis = Redis.Connect("127.0.0.1",6379,connect_to_redis)
			if toredis then
				print("connect to redis success")
				break
			end
			print("try to connect to redis after 1 sec")			
			Sche.Sleep(1000)
		end
	end)	
end

local function Command(str)
	if not toredis then
		return "redis invaild"
	end	
	return toredis:Command(str)
end

local function Init()
	connect_to_redis()
end

local function Finish()
	return toredis
end

return {
	Command = Command,
	Init = Init,
	Finish = Finish,
}
