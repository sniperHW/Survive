local Cjson = require "cjson"
stat_normal  = 1
stat_loading = 2
stat_playing = 3
stat_destroy = 4

local player = {
	conn,
	id,
	role,
	status,
}

local id2player = {}
local conn2player = {}

function player:new(o)
  o = o or {}   
  setmetatable(o, self)
  self.__index = self
  return o
end


function player:on_error()
	if self.status ~= stat_destroy then
		C.close(self.conn)
	end
end

function player:notify_create()
	if self.status ~= stat_destroy then	
		local wpk = new_wpk(64)
		wpk_write_uint16(wpk,CSID_LOGIN_REQ)
		wpk_write_uint16(wpk,ERROR_STATUS_LOGIN_NOROLE)
		wpk_write_uint32(wpk,0)
		C.send(self.conn,wpk)
		self.status = stat_normal
	end
end

function player:notify_login_success()
	if self.status ~= stat_destroy then	
		local wpk = new_wpk(64)
		wpk_write_uint16(wpk,CSID_LOGIN_REQ)
		wpk_write_uint16(wpk,ERROR_STATUS_SUCCESS)
		wpk_write_uint32(wpk,0)
		C.send(self.conn,wpk)
	end	
end

function player:notify_create_success()
	if self.status ~= stat_destroy then	
		local wpk = new_wpk(64)
		wpk_write_uint16(wpk,SCID_CREATE_ROLE_ACK)
		wpk_write_uint16(wpk,ERROR_STATUS_SUCCESS)
		wpk_write_uint32(wpk,0)
		C.send(self.conn,wpk)
	end	
end


local function db_create_callback(self,error,result)
	print("db_create_callback")
	if error then
		print("error1")
		on_error(self.ply)
		return
	end
	self.ply:notify_create_success()
	self.ply:NotifyRoleInfo()
	self.ply.status = stat_playing
end


function player:NotifyRoleInfo()
	local wpk = new_wpk(256)
	wpk_write_uint16(wpk,SCID_ROLE_INFO_ACK)
	wpk_write_uint32(wpk,self.id)
	wpk_write_string(wpk,self.role.name)
	wpk_write_uint16(wpk,self.role.viplev)
	wpk_write_uint32(wpk,self.role.gold)
	wpk_write_uint16(wpk,self.role.power)
	wpk_write_uint32(wpk,0)
	wpk_write_uint32(wpk,0)
	C.send(self.conn,wpk)	
end

function player:CreateRole(rolename)
	self.role = {
		name = rolename,
		viplev = 0,
		vocation = 0,
		exp = 0,
		gold = 3541,
		power = 0,
		icon = 0,
		gemstone = 0,		
	}
	
	local cmd = "hmset usrid:" .. self.id .. " role " .. Cjson.encode(self.role)
	local err = Dbmgr.DBCmd(self.id,cmd,{callback = db_create_callback,ply=self})
	if err then
		C.close(self.conn)
	end	
end

local function GetPlyByConn(conn)
	return conn2player[conn]
end

local function GetPlyById(id)
	return id2player[id]
end

local function NewPlayer(conn,id)
	local player = player:new()
	player.id = id
	player.conn = conn
	player.role = nil
	player.status = stat_normal
	id2player[id] = player
	conn2player[conn] = player	
	return player 	
end

local function DestryPlayer(player)
	if not player then
		return
	end
	id2player[player.id] = nil
	conn2player[player.conn] = nil
	player.status = stat_destroy
	player.conn = nil
end

return {
	DestryPlayer = DestryPlayer,
	NewPlayer = NewPlayer,
	GetPlyById = GetPlyById,
	GetPlyByConn = GetPlyByConn,
}
