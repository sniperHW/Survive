local MinHeap = require "src.pseudoserver.minheap"
local Sche = require "src.pseudoserver.sche"
local Time = require "src.pseudoserver.time"
local timer = {
	minheap,
}

function timer:new(o)
  local o = o or {}   
  setmetatable(o, self)
  self.__index = self
  o.minheap = MinHeap.New()
  return o
end

function timer:Register(callback,ms,...)
	local t = {}
	t.callback = callback
	t.ms = ms
	t.index = 0
	t.timeout = Time.SysTick() + ms
	t.arg = table.pack(...)
	t.timer = self
	self.minheap:Insert(t)
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
	local timer = self.minheap
	while true do
		local now = Time.SysTick()
		while not self.stop  and timer:Min() ~= 0 and timer:Min() <= now do
			t = timer:PopMin()
			if not t.invaild then
				local status,ret = pcall(t.callback,table.unpack(t.arg))
				if not status then
					print("timer error:" .. ret)
				elseif ret then
					self:Register(t.callback,t.ms,table.unpack(t.arg))
				end
			end
		end
		if self.stop  then return end
		Sche.Sleep(1)
	end	
end

return {
	New = function () return timer:new() end
}

