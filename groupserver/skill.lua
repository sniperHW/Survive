local Cjson = require "cjson"
local Db = require "Survive/common/db"
local skills = {}

function skills:new(o)
  local o = o or {}   
  setmetatable(o, self)
  self.__index = self
  return o
end

function skills:Init(sks)
	self.skills = sks or {}
	self.flag = {}
	return self
end

function skills:OnBegPly(wpk)
	local wpos = wpk:Get_write_pos()
	wpk:Write_uint16(0)
	local c = 0	
	for k,v in pairs(self.skills) do
		wpk:Write_uint16(k)
		wpk:Write_uint16(v)
		c = c + 1
	end
	wpk:Rewrite_uint16(wpos,c)	
end

function skills:DbStr()
	return Cjson.encode(self.skills)
end

function skills:Save(ply)
	local cmd = "hmset chaid:" .. ply.chaid .. " skill  " .. self:DbStr()
	Db.Command(cmd)	
end

return {
	New = function () return skills:new() end
}

