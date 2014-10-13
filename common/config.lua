--配置管理,从配置中心数据库获取本进程相关的配置
--package.cpath = "Survive/?.so"
local Db = require "Survive/common/db"
local Cjson = require "cjson"
--local Base64 = require "base64"

local function Init(ip,port)
	Db.Init(ip,port)
end

local function IsInitFinish()
	return Db.Finish()
end

local function Get(key)
	local err,result = Db.Command("get " .. key)
	if result then
		print(key,result)
		result = Cjson.decode(result)
	end
	return err,result
end

return {
	Init = Init,
	IsInitFinish = IsInitFinish,
	Get = Get,
}
