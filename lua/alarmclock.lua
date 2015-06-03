local Sche = require "lua.sche"
local Timer = require "lua.timer"
local LinkQue =  require "lua.linkque"

local alarmclock = {}

function alarmclock:new()
	local o = {}   
	setmetatable(o, self)
	self.__index = self
	o.slot = {}
	return o
end

--[[
alarmtime = {
	year,
	mon,
	day,
	hour,
	min,
	sec,
}
]]--
function alarmclock:SetAlarm(alarmtime,onAlarm,...)
	if not alarmtime or not onAlarm then
		return nil,"invaild argument1"
 	end
 	--[[if not alarmtime.year or not alarmtime.mon or not alarmtime.day then
 		return nil,"invaild argument2"
 	end
 	alarmtime.hour = alarmtime.hour or 0
 	alarmtime.min = alarmtime.min or 0]]--

 	if #alarmtime < 5 then
 		return nil,"invaild argument2"
 	end

 	if type(alarmtime[1]) ~= "number" and alarmtime[1] < 1900 then
 		return nil,"invaild year"
 	end

  	if type(alarmtime[2]) ~= "number" and not (alarmtime[2] > 0 and  alarmtime[2] < 13) then
 		return nil,"invaild mon"
 	end

   	if type(alarmtime[3]) ~= "number" and not (alarmtime[3] > 0 and  alarmtime[3] < 32) then
 		return nil,"invaild day"
 	end

    	if type(alarmtime[4]) ~= "number" and not (alarmtime[4] >= 0 and  alarmtime[4] < 24) then
 		return nil,"invaild hour"
 	end
 	
     	if type(alarmtime[5]) ~= "number" and not (alarmtime[5] >= 0 and  alarmtime[5] < 60) then
 		return nil,"invaild min"
 	end

 	local sec = 0
      	if alarmtime[6] then
      		if type(alarmtime[6]) ~= "number" and not (alarmtime[6] >= 0 and  alarmtime[6] < 60) then
 			return nil,"invaild sec"
 		else
 			sec =  alarmtime[6]
 		end
 	end						

 	local now = os.time()
 	local alarmstamp = CTimeUtil.GetTS(table.unpack(alarmtime)) + sec
 	if alarmstamp <= now then
 		return nil,"can't set alarm in the past time"
 	end
 	local alarm = {
 		fireTime = alarmstamp,
 		onAlarm = onAlarm,
 		isVaild = true,
 		arg = table.pack(...)
 	}
 	if not self.minheap then
 		self.minheap = CMinHeap.New()
 		startRun = true
 	end
 	local slot = self.slot[alarmstamp]
 	if not slot then
 		slot = {
 			alarmstamp = alarmstamp,
			alarms = LinkQue.New()
		}
		self.slot[alarmstamp] = slot    	
		self.minheap:Insert(slot,alarmstamp)
 	end
 	slot.alarms:Push(alarm)
 	if not self.timer then
 		self.timer = Timer.New("runImmediate",1000):Register(function (o) 
 										o:CheckAlarm() 
 									end,1000,self)
 	end
 	return alarm
end

function alarmclock:CheckAlarm()
	local timeouts = self.minheap:Pop(os.time())
	if timeouts then
		for k,v in pairs(timeouts) do
			local alarms = v.alarms
			while not alarms:IsEmpty() do
				local alarm = alarms:Pop()
				local status,err = pcall(alarm.onAlarm,table.unpack(alarm.arg))
				if not status then
					CLog.SysLog(CLog.LOG_ERROR,"alarmclock error:" .. err)
				end
				alarms.isVaild = false
			end
			self.slot[v.alarmstamp] = nil
		end
	end
	return true
end

function alarmclock:RemoveAlarm(alarm)
	local slot = self.slot[alarm.fireTime]
	if slot then
		local ret = slot.alarms:Remove(alarm)
		if ret and slot.alarms:IsEmpty() then
			alarm.isVaild = false
			self.slot[slot.alarmstamp] = nil
		end
		return ret
	else
		return false
	end
end

local AlarmClock = alarmclock:new()
return AlarmClock