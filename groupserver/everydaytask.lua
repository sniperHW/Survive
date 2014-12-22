local MsgHandler = require "SurviveServer.netcmd.msghandler"
local Db = require "SurviveServer.common.db"
local NetCmd = require "SurviveServer.netcmd.netcmd"
local Bag = require "SurviveServer.groupserver.bag"
local Util = require "SurviveServer.groupserver.util"
require "SurviveServer.common.TableDay_Task"
local Cjson = require "cjson"
local everydaytask = {}


local taskType = {
	PVE5 = 1,                      --参加3次5人PVE
	PVP5 = 2,                      --参加5次5人PVP
	WUDIDONG = 3,         --无底洞通过15关
	GUAJI = 4,                     --挂机时长达到60分钟
	COMPOSE = 5,             --宝石合成1次
	SKILLUPGRADE = 6,     --技能升级1次
	EQUIPUPGRADE = 7,   --装备强化1次
	ADDSTAR = 8,               --装备升星1次
}

--[[
task = {
	type,
	counter,   --当前计数器
	awarded, --是否领取过奖励
}
]]

for k,v in pairs(TableDay_Task) do
	local award = {}
	local tmp = Util.SplitString(v.Award,",")
	for k1,v1 in pairs(tmp) do
		local tmp2 = Util.SplitString(v1,":")
		tmp2[1] = tonumber(tmp2[1])
		tmp2[2] = tonumber(tmp2[2])
		table.insert(award,tmp2)
	end
	v.Award = award
end

function everydaytask:new(owner,data)
	local o = {}   
	setmetatable(o, self)
	self.__index = self
	o.owner = owner
	o.tasks = {}

	if not data then
		o.lastreset = CTimeUtil.GetTSWeeHour()
		for i = taskType.PVE5,taskType.ADDSTAR do
			o.tasks[i] = {type=i,counter=0,awarded=false}
		end
	else
		o.lastreset = lastreset
		for k,v in pairs(data.tasks) do
			o.tasks[k] = v
		end
	end
	if o:CheckReset() then
		o:DbSave()
	end
	return o
end

function everydaytask:CheckReset()
	if 0 ~= CTimeUtil.DiffDay(self.lastreset,os.time()) then
		self.lastreset = CTimeUtil.GetTSWeeHour()
		for i = taskType.PVE5,taskType.ADDSTAR do
			self.tasks[i].counter = 0
			self.tasks[i].awarded = false
		end
		return true		
	end
	return false
end

function everydaytask:Pack(wpk)
	wpk:Write_uint8(taskType.ADDSTAR)
	for i = taskType.PVE5,taskType.ADDSTAR do
		wpk:Write_uint8(self.tasks[i].counter)
		if self.tasks[i].awarded then
			wpk:Write_uint8(1)
		else
			wpk:Write_uint8(0)
		end
	end
end

function everydaytask:DbStr()
	return Cjson.encode({lastreset = self.lastreset,tasks = self.tasks})
end

function everydaytask:DbSave()
	local cmd = "hmset chaid:" .. self.owner.chaid .. " everydaytask  " .. self:DbStr()
	Db.Command(cmd)
end

function everydaytask:OnEvent(eventType)

	local tb = TableDay_Task[eventType]
	local task = self.tasks[eventType]
	if not tb or not task then
		return
	end

	local condition = tb["Number"]
	if task.counter <  condition then
		task.counter = task.counter + 1
		if task.counter > condition then
			task.counter = condition
		end
		self:DbSave()
	end
end

--领取奖励
function everydaytask:GetAward(type)
	print("GetAward")
	local tb = TableDay_Task[type]
	local task = self.tasks[type]
	if not tb or not task then
		return
	end
	local condition = tb["Number"]
	print("GetAward1")
	if task.awarded or task.counter <  condition then
		return
	end

	local ply = self.owner

	local award = tb["Award"]

	for k,v in pairs(award) do
		local id = v[1]
		local count = v[2]
		if id == 4001 then
			ply.attr:Add("shell",count)
		elseif id == 4002 then
			ply.attr:Add("pearl",count)
		elseif id == 4003 then
			ply.attr:Add("soul",count)
		elseif id == 4004 then
			ply:AddExp(count)
		elseif id == 4005 then

		end
	end
	ply.attr:Update2Client()
	ply.attr:DbSave()

	local wpk = CPacket.NewWPacket(64)
	wpk:Write_uint16(NetCmd.CMD_GC_EVERTDAYTASK_AWARD)
	wpk:Write_uint8(type)
	ply:Send2Client(wpk)	


	--[[print("GetAward2")
	local award = tb["Award"]
	if Bag.NewRes(self.owner,award) then
		print("GetAward3")
		task.awarded = true
		self:DbSave()
		self.owner.bag:NotifyUpdate()
		self.owner.bag:Save()		
		local wpk = CPacket.NewWPacket(64)
		wpk:Write_uint16(NetCmd.CMD_GC_EVERTDAYTASK_AWARD)
		wpk:Write_uint8(type)
		self.owner:Send2Client(wpk)
	end
	print("GetAward4")]]--
end

MsgHandler.RegHandler(NetCmd.CMD_CG_EVERYDAYTASK,function (sock,rpk)
	local groupsession = rpk:Reverse_read_uint16()
	local ply = GetPlayerBySessionId(groupsession)
	if ply then
		local wpk = CPacket.NewWPacket(64)
		wpk:Write_uint16(NetCmd.CMD_GC_EVERYDAYTASK)	
		ply.task:Pack(wpk)
		ply:Send2Client(wpk)
	end		
end)

MsgHandler.RegHandler(NetCmd.CMD_CG_EVERYDAYTASK_GETAWARD,function (sock,rpk)
	print("CMD_CG_EVERYDAYTASK_GETAWARD")
	local groupsession = rpk:Reverse_read_uint16()
	local ply = GetPlayerBySessionId(groupsession)
	if ply then
		local type = rpk:Read_uint8()
		ply.task:GetAward(type)
	end		
end)

return {
	New = function (owner,data) return everydaytask:new(owner,data) end,
	TaskType = taskType,
}

