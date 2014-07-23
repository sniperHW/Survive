local Map = require "script/map"
local Que = require "script/queue"
local Avatar = require "script/avatar"
local Cjson = require "cjson"


local function load_login_callback(self,error,result)
	print("load_login_callback")
	if error then
		print("error1")
		self.ply:on_error()
		return
	end
	
	if not result then
		print("error2")
		self.ply:on_error()
		return 
	end
	
	local key = result[1]
	local role = result[2]
	
	if self.key ~= key then
		print("error3")
		self.ply:on_error()
		return 
	end
	
	if not role then
		--通知创建角色
		self.ply:notify_create()
		return 
	end	
	self.ply.role = Cjson.decode(role)
	self.ply:notify_login_success()
	self.ply:NotifyRoleInfo()
	self.ply.status = stat_playing		
end


local function CMD_LOGIN(_,rpk,conn)
	local usrid = rpk_read_uint16(rpk);
	local key = rpk_read_string(rpk);
	if Avatar.GetPlyByConn(conn) then
		return
	end
	local player = Avatar.GetPlyById(usrid)	
	if player then
		C.close(conn)
	end
	--向redis请求用户数据	
	local player = Avatar.NewPlayer(conn,usrid)
	local cmd = "hmget usrid:" .. usrid .. " key" .. " role" .. " card" .. " map" .. " mapstory"
	local err = Dbmgr.DBCmd(usrid,cmd,{callback = load_login_callback,ply=ply,key=key})
	if err then
		C.close(conn)
		return
	end
	ply.status = stat_loading	
end

local function CREATE_ROLE(_,rpk,conn)
	local player = Avatar.GetPlyByConn(conn)
	if not player then
		C.close(conn)
		return
	end
	local rolename = rpk_read_string(rpk)
	player:CreateRole(rolename)
end


local function CLIENT_DISCONN(_,rpk,conn)
	Avatar.DestryPlayer(Avatar.GetPlyByConn(conn))
end



local function reg_cmd_handler()
	game_init()
	C.reg_cmd_handler(CSID_LOGIN_REQ,{handle=CMD_LOGIN})
	C.reg_cmd_handler(CSID_CREATE_ROLE_REQ,{handle=CREATE_ROLE})
	C.reg_cmd_handler(
	C.reg_cmd_handler(CMD_CLIENT_DISCONN,{handle=CLIENT_DISCONN})	
end

return {
	RegHandler = reg_cmd_handler,
}


