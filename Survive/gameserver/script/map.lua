local Avatar = require "avatar"
local Que = require "queue"

local map = {
	maptype,
	mapid,
	astar,
	aoi,
	avatars,
	freeidx,
}

local function map:new(o)
  o = o or {}   
  setmetatable(o, self)
  self.__index = self
  return o
end

local function map:init(mapid,maptype)
	self.mapid = mapid
	self.maptype = maptype
	self.freeidx = Que.Queue()
	for i=1,65536 do
		self.freeidx:push({v=i,__next=nil})
	end
	--TODO 初始化aoi和astar
	return self
end

local function read_player_from_rpk(rpk)
	
end

local function map:entermap(rpk)
	local plys = read_player_from_rpk(rpk)
	if self.freeidx:len() < #plys then
		--没有足够的id创建玩家avatar
		return false
	else
		for _,v in pairs(plys) do
			--TODO 根据信息创建avatar
		end
		return true
	end
end

return {
	NewMap = function () map:new() end,
}



