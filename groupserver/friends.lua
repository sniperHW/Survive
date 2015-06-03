local Cjson = require "cjson"
local Db = require "common.db"
local NetCmd = require "netcmd.netcmd"
local MsgHandler = require "netcmd.msghandler"
local friends = {}
local maxfirends = 50

function friends:new()
  local o = {}   
  setmetatable(o, self)
  self.__index = self
  return o
end

function friends:Init(ply,data)
	data = data or {friends={},black={}}
	self.ply = ply
	self.friends = data.friends
	self.black = data.black
	for k,v in pairs(data) do
		if v.black then
			self.black[v.chaid] = v
		else
			self.friends[v.chaid] = v
		end
	end
	return self
end

function friends:DbStr()
	local tmp = {friends={},black={}}
	for k,v in pairs(self.black) do
		table.insert(tmp.black,v)
	end
	for k,v in pairs(self.friends) do
		table.insert(tmp.friends,v)
	end
	return Cjson.encode(tmp)
end

function friends:DbSave()
	local cmd = "hmset chaid:" .. self.owner.chaid .. " friends  " .. self:DbStr()
	Db.CommandAsync(cmd)
end

function friends:Pack(wpk)
	local wpos = wpk:Get_write_pos()
	wpk:Write_uint16(0)
	local c = 0	
	for k,v in pairs(self.black) do
		wpk:Write_uint32(v.chaid)
		wpk:Write_string(v.nickname)
		wpk:Write_uint16(v.avatarid)
		wpk:Write_uint8(v.level)
		wpk:Write_uint8(1)
		if GetPlyByChaid(v.chaid) then
			wpk:Write_uint8(1)
		else
			wpk:Write_uint8(0)
		end
		c = c + 1
	end
	for k,v in pairs(self.friends) do
		wpk:Write_uint32(v.chaid)
		wpk:Write_string(v.nickname)
		wpk:Write_uint16(v.avatarid)
		wpk:Write_uint8(v.level)				
		wpk:Write_uint8(0)
		if GetPlyByChaid(v.chaid) then
			wpk:Write_uint8(1)
		else
			wpk:Write_uint8(0)
		end
		c = c + 1
	end	
	wpk:Rewrite_uint16(wpos,c)	
end

function friends:Add(chaid,nickname,_type)
	local success
	if _type == "black" then
		local v = self.friends[chaid]
		if v then
			v.black = true
			self.friends[chaid] = nil
			self.black[chaid] = v
			success = true
		end
	else
		local ply
		if nickname then
			ply = GetPlyByNickname(nickname)
		else
			ply = GetPlyByChaid(chaid)
		end
		if ply then
			if not self.friends[ply.chaid] then
				self.friends[ply.chaid] = {chaid=ply.chaid,nickname=ply.nickname,avatarid = ply.avatarid,level = ply.attr:Get("level")}
				success = true
			end
		end
	end
	if success then
		self:DbSave()
	end
	return 	success
end

function friends:Remove(chaid,_type)
	local success 
	if _type == "black" then
		local v = self.black[chaid]
		if v then
			v.black = false
			self.black[chaid] = nil
			self.friends[chaid] = v
			success = true
		end
	else
		local v = self.friends[chaid]
		if v then
			self.friends[chaid] = nil
			success = true			
		end
	end
	if success then
		self:DbSave()
	end
	return 	success			
end

function friends:PeekInfo(chaid)
	local v = self.friends[chaid]
	if v then
		local ply = GetPlyByChaid(chaid)
		if ply then
			local wpk = CPacket.NewWPacket(1024)
			wpk:Write_uint16(NetCmd.CMD_GC_FRIEND_INFO)
			wpk:Write_uint32(chaid)
			wpk:Write_string(ply.nickname)
			wpk:Write_uint16(ply.avatarid)
			--pack attr
			ply.attr:Pack(wpk)
			--pack equipment
			ply.bag:PeekInfo(wpk,1,4)
			self.ply:Send2Client(wpk)
			local level = ply.attr:Get("level")
			if level ~= v.level then
				v.level = level
				self:DbSave()
			end
		end
	end 
end

MsgHandler.RegHandler(NetCmd.CMD_CG_FRIEND_PEEKINFO,function (sock,rpk)
	print("CMD_CG_FRIEND_PEEKINFO")
	local groupsession = rpk:Reverse_read_uint16()
	local ply = GetPlayerBySessionId(groupsession)
	if ply then
		local chaid = rpk:Read_uint32()
		ply.friends:PeekInfo(chaid)
	end	
end)

MsgHandler.RegHandler(NetCmd.CMD_CG_FRIEND_GETALL,function (sock,rpk)
	print("CMD_CG_FRIEND_GETALL")
	local groupsession = rpk:Reverse_read_uint16()
	local ply = GetPlayerBySessionId(groupsession)
	if ply then
		local wpk = CPacket.NewWPacket(1024)
		wpk:Write_uint16(NetCmd.CMD_GC_FRIEND_LIST)		
		ply.friends:Pack(wpk)
		ply:Send2Client(wpk)
	end	
end)

MsgHandler.RegHandler(NetCmd.CMD_CG_FRIEND_ADD,function (sock,rpk)
	print("CMD_CG_FRIEND_ADD")
	local groupsession = rpk:Reverse_read_uint16()
	local ply = GetPlayerBySessionId(groupsession)
	if ply then
		local _type = rpk:Read_string()
		local isId = rpk:Read_string() == "id"
		local chaid,nickname
		if isId then
			chaid = rpk:Read_uint32()
		else
			nickname = rpk:Read_string()
		end
		if ply.friends:Add(chaid,nickname,_type) then
			local wpk = CPacket.NewWPacket(1024)
			wpk:Write_uint16(NetCmd.CMD_GC_FRIEND_LIST)		
			ply.friends:Pack(wpk)
			ply:Send2Client(wpk)
		end
	end	
end)

MsgHandler.RegHandler(NetCmd.CMD_CG_FRIEND_REMOVE,function (sock,rpk)
	print("CMD_CG_FRIEND_REMOVE")
	local groupsession = rpk:Reverse_read_uint16()
	local ply = GetPlayerBySessionId(groupsession)
	if ply then
		local _type = rpk:Read_string()		
		local chaid = rpk:Read_uint32()
		if ply.friends:Remove(chaid,_type) then
			local wpk = CPacket.NewWPacket(1024)
			wpk:Write_uint16(NetCmd.CMD_GC_FRIEND_LIST)		
			ply.friends:Pack(wpk)
			ply:Send2Client(wpk)
		end
	end	
end)

return {
	New = function (ply,data) return friends:new():Init(ply,data) end
}
