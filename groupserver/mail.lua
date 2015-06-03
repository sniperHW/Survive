local Cjson = require "cjson"
local Name2idx = require "common.name2idx"
local NetCmd = require "netcmd.netcmd"
local Db = require "common.db"
local MsgHandler = require "netcmd.msghandler"
local Util = require "groupserver.util"

function Pack(id,mail,wpk)
	wpk:Write_string(id)
	wpk:Write_string(mail.title)
	wpk:Write_string(mail.content)
	wpk:Write_uint8(mail.readed or 0)
	if mail.attachment then
		wpk:Write_uint8(#mail.attachment)
		for k,v in pairs(mail.attachment) do
			--print(v.item,v.count)
			wpk:Write_uint16(v.item)
			wpk:Write_uint16(v.count)
		end
	else
		wpk:Write_uint8(0)
	end
end

local mailModule = {}

function mailModule:new(ply,dbdata)
	local o = {}   
	setmetatable(o, self)
	self.__index = self
	o.owner = ply
	o.list = dbdata or {}
	o.counter = 1
	--for k,v in pairs(o.list) do
	--	print(v.item,v.count)
		--wpk:Write_uint16(v.item)
		--wpk:Write_uint16(v.count)
	--end	
	--print("mail count",#o.list)
	return o	
end

function mailModule:SendMailList()
	local wpk = CPacket.NewWPacket(512)
	wpk:Write_uint16(NetCmd.CMD_GC_MAILLIST)
	local c = 0
	local wpos = wpk:Get_write_pos()
	wpk:Write_uint16(0)
	for k,v in pairs(self.list) do
		Pack(k,v,wpk)
		c = c + 1
	end
	wpk:Rewrite_uint8(wpos,c)
	self.owner:Send2Client(wpk)
end

function mailModule:SendMail(mail)
	--print("SendMail")
	local id = string.format("%d:%d",os.time(),self.counter)
	self.counter = self.counter + 1
	self.list[id] = mail
	self:Save()
	local c = 0
	for k,v in pairs(self.list) do
		if not v.readed or v.readed == 0 then
			c = c + 1
		end
	end
	local wpk = CPacket.NewWPacket(512)
	wpk:Write_uint16(NetCmd.CMD_GC_NEWMAIL)
	wpk:Write_uint16(c)
	self.owner:Send2Client(wpk)	
end

--local encode_str = CBase64.encode(inputstr)
--print(inputstr)
--print(encode_str)
--print(CBase64.decode(encode_str))

function mailModule:DbStr()
	return CBase64.encode(Cjson.encode(self.list))
end

function mailModule:Save()
	local cmd = "hmset chaid:" .. self.owner.chaid .. " mail  " .. self:DbStr()
	Db.CommandAsync(cmd)	
end


MsgHandler.RegHandler(NetCmd.CMD_CG_GETMAILLIST,function (sock,rpk)
	print("CMD_CG_GETMAILLIST")
	local groupsession = rpk:Reverse_read_uint16()
	local ply = GetPlayerBySessionId(groupsession)
	if ply and ply.mail then
		ply.mail:SendMailList()
	end	
end)

MsgHandler.RegHandler(NetCmd.CMD_CG_MAILMARKREAD,function (sock,rpk)
	print("CMD_CG_MAILMARKREAD")
	local groupsession = rpk:Reverse_read_uint16()
	local ply = GetPlayerBySessionId(groupsession)
	if ply and ply.mail then
		local id = rpk:Read_string()
		local mail = ply.mail.list[id]
		if mail then
			if mail.attachment then
				for k,v in pairs(mail.attachment) do
					Util.NewRes(ply,v.item,v.count)
				end
				ply.bag:NotifyUpdate()
				ply.bag:Save()
				ply.attr:Update2Client()
				ply.attr:DbSave()	
				--ply.mail:SendMailList()
				--ply.mail:Save()
			end
			ply.mail.list[id] = nil
			--table.remove(ply.mail.list,idx)
			ply.mail:Save()
		end		
	end	
end)

--[[MsgHandler.RegHandler(NetCmd.CMD_CG_MAILDELETE,function (sock,rpk)
	print("CMD_CG_MAILDELETE")
	local groupsession = rpk:Reverse_read_uint16()
	local ply = GetPlayerBySessionId(groupsession)
	if ply and ply.mail then
		local idx = rpk:Read_uint16()
		local mail = ply.mail.list[idx]
		if mail then
			table.remove(ply.mail.list,idx)
			ply.mail:SendMailList()
			ply.mail:Save()
		end	
	end	
end)

MsgHandler.RegHandler(NetCmd.CMD_CG_MAILGETATTACH,function (sock,rpk)
	print("CMD_CG_MAILGETATTACH")
	local groupsession = rpk:Reverse_read_uint16()
	local ply = GetPlayerBySessionId(groupsession)
	if ply and ply.mail then
		local idx = rpk:Read_uint16()
		local mail = ply.mail.list[idx]
		if mail and mail.attachment then
			for k,v in pairs(mail.attachment) do
				Util.NewRes(ply,v.item,v.count)
			end
			ply.bag:NotifyUpdate()
			ply.bag:Save()	
			ply.mail:SendMailList()
			ply.mail:Save()
		end	
	end	
end)
]]--

local function SendMail(ply,mail)
	ply.mail:SendMail(mail)
end

return {
	New = function (ply,data) return mailModule:new(ply,data) end,
	SendMail = SendMail,
}
