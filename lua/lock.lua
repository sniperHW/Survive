local Sche = require "lua.sche"


local LinkQue  = require "lua.linkque"
local lock = {}

function lock:new()
  local o = {}
  self.__index = self      
  setmetatable(o,self)
  o.block = LinkQue.New()
  o.flag  = false
  return o
end

function lock:Lock()
	while self.flag do
		self.block:Push(Sche.Running())
		Sche.Block()
	end
	self.flag = true
end

function lock:Unlock()
	self.flag = false
	local co = self.block:Pop()
	if co then
		Sche.Schedule(co)
	end
end

return {
	New = function () return lock:new() end
}



