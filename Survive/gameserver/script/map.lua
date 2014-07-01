local Avatar = require "avatar"
local Que = require "queue"


local astarmgr = {}

local map = {
	maptype,
	mapid,
	astar,
	aoi,
	avatars,
	freeidx,
	plycount,      --地图上玩家的数量
	movingavatar,  --有移动请求的avatar
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
	self.astar = astarmgr[maptype]
	--self.aoi = GameApp.create_aoimap(100,100,0,0,100,100)
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

local function map:leavemap(plyid)
	local ply = self.avatars[plyid]
	if ply and ply.avattype == Avatar.type_player then
		--处理离开地图
	end
end

local function map:findpath(from,to)
	return GameApp.findpath(self.astar,from[1],from[2],to[1],to[2])
end

local function map:beginMov(avatar)
	if not self.movingavatar[avatar.id] then
		self.movingavatar[avatar.id] = avatar
	end
end

local function map:clear()
	GameApp.destroy_aoimap(self.aoi)
end

--处理本地图上的对象移动请求
local function map:process_mov()
	local stops = {}
	for k,v in pairs(self.movingavatar) do
		if v:process_mov() then
			table.insert(stops,k)
		end
	end
	
	for k,v in pairs(stops) do
		self.movingavatar[v] = nil
	end
end 

return {
	NewMap = function (mapid,maptype) return map:new():init(mapid,maptype) end,
}
