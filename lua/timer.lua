local Sche = require "lua.sche"
local timer = {
	minheap,
}

function timer:new(runImmediate,tickinterval)
  local o = {}   
  setmetatable(o, self)
  self.__index = self
  o.minheap = CMinHeap.New()
  o.tickinterval = tickinterval or 1
  if runImmediate then
  	Sche.SpawnAndRun(function () o:Run() end)
  end
  return o
end

function timer:Register(callback,ms,...)
	local t = {}
	t.callback = callback
	t.ms = ms
	t.arg = table.pack(...)
	t.timer = self
	self.minheap:Insert(t,C.GetSysTick() + ms)
	return self,t
end

function timer:Remove(t)
	if t.timer ~= self or t.invaild then
		return false
	else
		t.invaild = true
		return true
	end
end

function timer:Stop()
	self.stop = true
end

function timer:Run()
	if self.running then
		return "timer already running"
	end
	local timer = self.minheap
	self.stop = false
	while true do
		while not self.stop do
			local timeouts = timer:Pop(C.GetSysTick())
			if not timeouts then
				break
			end
			for k,v in pairs(timeouts) do
				if not v.invaild then
					local errmsg,stack
					local ok,ret = xpcall(v.callback,
										  function (err)
										  	errmsg = err
										  	stack  = debug.traceback()
										  end,	
										  table.unpack(v.arg))
					if not ok then
						CLog.SysLog(CLog.LOG_ERROR,string.format("timer error:%s\n%s",errmsg,stack))
					else
						if ret == nil then
							self:Register(v.callback,v.ms,table.unpack(v.arg))
						end
					end
				end
			end
		end
		if self.stop  then
			return nil
		end
		Sche.Sleep(self.tickinterval)
	end	
end

return {
	New = function (runImmediate,tickinterval) return timer:new(runImmediate,tickinterval) end
}

