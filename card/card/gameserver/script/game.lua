local Map = require "script/map"
local Que = require "script/queue"
local Avatar = require "script/avatar"
local Cjson = require "cjson"
local Dbmgr = require "script/dbmgr"


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
	print("-----------------")
	print(self.key)
	print(key)
	if self.key ~= key then
		print("error3")
		self.ply:on_error()
		return 
	end
	
	if not role then
		--通知创建角色
		print("notify_create")
		self.ply:notify_create()
		return 
	end	
	self.ply.role = Cjson.decode(role)
	self.ply:notify_login_success()
	self.ply:NotifyRoleInfo()
	self.ply.status = stat_playing		
end


local function CMD_LOGIN(_,rpk,conn)
	local usrid = rpk_read_uint32(rpk);
	local key = rpk_read_string(rpk);
	print("CMD_LOGIN")
	print(usrid)
	print(key)
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
	local err = Dbmgr.DBCmd(usrid,cmd,{callback = load_login_callback,ply=player,key=key})
	if err then
		C.close(conn)
		return
	end
	player.status = stat_loading	
end

local function CREATE_ROLE(_,rpk,conn)
	print("CREATE_ROLE")
	local player = Avatar.GetPlyByConn(conn)
	if not player then
		C.close(conn)
		return
	end
	local rolename = rpk_read_string(rpk)
	player:CreateRole(rolename)
end


local function CLIENT_DISCONN(_,rpk,conn)
	print("CLIENT_DISCONN")
	Avatar.DestryPlayer(Avatar.GetPlyByConn(conn))
end

local function ENTERMAP_REQ(_,rpk,conn)
	print("ENTERMAP_REQ")
	local mapid = rpk_read_uint32(rpk)
	local diffculty = rpk_read_uint32(rpk)
	
	local ply = Avatar.GetPlyByConn(conn)
	if not ply then
		C.close(conn)
		return
	end

	local wpk = new_wpk(64)
	wpk_write_uint16(wpk,CSID_ENTERMAP_ACK)
	wpk_write_uint16(wpk,0)
	C.send(conn,wpk)
end



local function reg_cmd_handler()
	C.reg_cmd_handler(CSID_LOGIN_REQ,{handle=CMD_LOGIN})
	C.reg_cmd_handler(CSID_CREATE_ROLE_REQ,{handle=CREATE_ROLE})
	C.reg_cmd_handler(DUMMY_ON_CLI_DISCONNECTED,{handle=CLIENT_DISCONN})
	C.reg_cmd_handler(CSID_ENTERMAP_REQ,{handle=ENTERMAP_REQ})	
end

return {
	RegHandler = reg_cmd_handler,
}


