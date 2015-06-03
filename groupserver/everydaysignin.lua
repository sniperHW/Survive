local MsgHandler = require "netcmd.msghandler"
local Db = require "common.db"
local NetCmd = require "netcmd.netcmd"
local Cjson = require "cjson"
local everydaysignin = {}

local function DiffMon(a,b)
	local year = CTimeUtil.GetYear()
	local mon = CTimeUtil.GetMon()
	if mon == 1 then
		mon = 12
		year = year - 1
	end
	local daycount = CTimeUtil.GetDayCountOfMon(year,mon)
	if CTimeUtil.DiffDay(a,b) >=  daycount then
		return true
	else
		return false
	end
end

function everydaysignin:new(owner,data)
	local o = {}   
	setmetatable(o, self)
	self.__index = self
	o.owner = owner
	local year = CTimeUtil.GetYear()
	local mon = CTimeUtil.GetMon()
	data = data or {count = 0,lastreset = CTimeUtil.GetMonFDay(),lastsign = 0}
	--signdata will be reset in the first day of every month
	o.count = tonumber(data.count)
	o.lastsign = tonumber(data.lastsign)
	o.lastreset = tonumber(data.lastreset) 
	o.daycount = CTimeUtil.GetDayCountOfMon(year,mon)
	o:CheckReset()
	return o
end

function everydaysignin:OnBegPly(wpk)
	wpk:Write_uint8(self.daycount)
	wpk:Write_uint8(self.count)
	if CTimeUtil.DiffDay(self.lastsign,os.time()) ~= 0 then
		wpk:Write_uint8(1)
	else
		wpk:Write_uint8(0)
	end
end

function everydaysignin:Sign()
	self:CheckReset()
	if CTimeUtil.DiffDay(self.lastsign,os.time()) ~= 0 and 
	    self.count < self.daycount then	
	    	self.count = self.count + 1
	    	self.lastsign = CTimeUtil.GetTSWeeHour()
	    	self:Update2Client()
	    	self:DbSave()
	end
end

function everydaysignin:Update2Client()
	local wpk = CPacket.NewWPacket(64)
	wpk:Write_uint16(NetCmd.CMD_GC_EVERYDAYSIGN)	
	wpk:Write_uint8(self.daycount)
	wpk:Write_uint8(self.count)
	if CTimeUtil.DiffDay(self.lastsign,os.time()) ~= 0 then
		wpk:Write_uint8(1)
	else
		wpk:Write_uint8(0)
	end
	self.owner:Send2Client(wpk)
end

function everydaysignin:CheckReset(notify)
	local tstamp = CTimeUtil.GetMonFDay()
	if DiffMon(self.lastreset,tstamp) then
		self.count = 0
		self.lastreset = tstamp
		local year = CTimeUtil.GetYear()
		local mon = CTimeUtil.GetMon()		
		self.daycount = CTimeUtil.GetDayCountOfMon(year,mon)
		if notify then
			self:Update2Client()
		end
		return true
	end
	return false
end

function everydaysignin:DbStr()
	return Cjson.encode({count=self.count,lastreset = self.lastreset,lastsign = self.lastsign})
end

function everydaysignin:DbSave()
	local cmd = "hmset chaid:" .. self.owner.chaid .. " everydaysign  " .. self:DbStr()
	Db.CommandAsync(cmd)
end

MsgHandler.RegHandler(NetCmd.CMD_CG_EVERYDAYSIGN,function (sock,rpk)
	local groupsession = rpk:Reverse_read_uint16()
	local ply = GetPlayerBySessionId(groupsession)
	if ply then
		ply.sign:Sign()
	end		
end)

return {
	New = function (owner,data) return everydaysignin:new(owner,data) end
}
