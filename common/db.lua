local Redis = require "lua.redis"
local Sche = require "lua.sche"


local toredis

--建立到redis的连接
local function connect_to_redis(ip,port)
    if toredis then
    	CLog.SysLog(CLog.LOG_INFO,string.format("redis %s:%d disconnected",ip,port))
    end
    toredis = nil
	Sche.Spawn(function ()
		while true do
			local err
			err,toredis = Redis.Connect(ip,port,
										function (redisconn)
												if not redisconn.activeclose then	
													connect_to_redis(ip,port)
												end
										end)
			if toredis then
				CLog.SysLog(CLog.LOG_INFO,string.format("connect to redis %s:%d success",ip,port))
				break
			end
			--print("try to connect to redis after 1 sec")			
			Sche.Sleep(1000)
		end
	end)	
end

local function Command(str)
	if not toredis then
		return "redis invaild"
	end	
	return toredis:CommandSync(str)
end

local isInit
local function Init(ip,port)
	if not isInit then
		isInit = true
		connect_to_redis(ip,port)
	end
end

local function Finish()
	return toredis
end

return {
	Command = Command,
	Init = Init,
	Finish = Finish,
}
