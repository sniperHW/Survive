--配置管理,从配置中心数据库获取本进程相关的配置
--package.cpath = "Survive/?.so"
local Redis = require "lua/redis"
local Cjson = require "cjson"
local Sche = require "lua/sche"
--local Base64 = require "base64"

local toredis

local function connect_to_redis(ip,port)
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
				print("connect to config server success")
				break
			end
			print("try to connect to config server after 1 sec")			
			Sche.Sleep(1000)
		end
	end)	
end

local isInit
local function Init(ip,port)
	if not isInit then
		isInit = true
		connect_to_redis(ip,port)
	end
end

local function Get(key)
	while not toredis do
		Sche.Sleep(100)
	end
	local err,result = toredis:Command("get " .. key)
	if result then
		print(key,result)
		result = Cjson.decode(result)
	end
	return err,result
end

local function Close()
	if toredis then
		toredis:Close()
	end
end

return {
	Init = Init,
	Get = Get,
	Close = Close,
}
