local type_player   = 1    
local type_monster  = 2   
local type_pickable = 3

local avatar ={
	id,            
	avatid,        
	avattype,      --player/monster/pickable
	pos,
	aoi_obj,
	see_radius,   
	view_obj,      
	watch_me,      
	gate,
	map,          
	path,
	speed,         
	lastmovtick,   
	movmargin,     
	dir,           
	nickname,      
	groupid,                 
}

function avatar:new(o)
  o = o or {}   
  setmetatable(o, self)
  self.__index = self
  o.pos = {}
  return o
end


function avatar:send2view(wpk)
	--将玩家分组,同gateserver同agent的玩家为一组,发送一个统一的包
	
	--首先按gate分组	
	local gates = {}
	for k,v in pairs(self.watch_me) do
		if v.gate then
			local t
			if not gates[v.gate.conn] then
				t = {}
				gates[v.gate.conn] = {conn=v.gate.conn,plys=t}
			else
				t = gates[v.gate.conn].plys
			end
			table.insert(t,v) 
		end
	end
	
	for k,v in pairs(gates) do
		--按aid分组
		local groups = {}
		local plys = v.plys
		for k1,v1 in pairs(plys) do
			local aid = bit32.band(0x7,v1.gate.id.high)
			local t
			if not groups[aid] then
				t = {}
				groups[aid] = t
			else
				t = groups[aid]
			end
			table.insert(t,v1)	
		end
		
		for k1,v1 in pairs(groups) do
			local w = new_wpk_by_wpk(wpk)
			for k2,v2 in pairs(v1) do
				wpk_write_uint32(w,v2.gate.id.high)
				wpk_write_uint32(w,v2.gate.id.low)
			end
			wpk_write_uint32(w,#v1)
			wpk_write_uint32(w,k1)
			C.send(v.conn,w)
		end
	end
	destroy_wpk(wpk)
end

function avatar:destroy()
	if self.aoi_obj then
		GameApp.destroy_aoi_obj(self.aoi_obj)
	end
end

local player = avatar:new()

function player:new(id,avatid)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.id = id
	o.avatid = avatid
	o.avattype = type_player
	o.see_radius = 5
	o.view_obj = {}
	o.watch_me = {}
	o.gate = nil
	o.map =  nil
	o.path = nil
	o.speed = 3
	o.pos = nil
	o.nickname = ""
	--print("player:new " .. id) 
	o.aoi_obj = GameApp.create_aoi_obj(o)
	return o	
end

function player:send2gate(wpk)
	if not self.gate then
		return
	end	
	wpk_write_uint32(wpk,self.gate.id.high)
	wpk_write_uint32(wpk,self.gate.id.low)
	wpk_write_uint32(wpk,1)
	wpk_write_uint32(wpk,self.gate.id.high)	
	C.send(self.gate.conn,wpk)	
end

function player:enter_see(other)
	print(other.id .. " enter " .. self.id)
	self.view_obj[other.id] = other
	other.watch_me[self.id] = self	
	

	local wpk = new_wpk(1024)
	wpk_write_uint16(wpk,CMD_SC_ENTERSEE)
	wpk_write_uint32(wpk,other.id)
	wpk_write_uint8(wpk,other.avattype)
	wpk_write_uint16(wpk,other.avatid)
	wpk_write_string(wpk,"test")--other.nickname)
	wpk_write_uint16(wpk,other.pos[1])
	wpk_write_uint16(wpk,other.pos[2])
	wpk_write_uint8(wpk,other.dir)
	self:send2gate(wpk)
	
	if other.path then
		local size = #other.path.path
		local target = other.path.path[size]
		local wpk = new_wpk(64)
		wpk_write_uint16(wpk,CMD_SC_MOV)
		wpk_write_uint32(wpk,other.id)
		--wpk_write_uint16(wpk,other.speed)
		wpk_write_uint16(wpk,target[1])
		wpk_write_uint16(wpk,target[2])
		self:send2gate(wpk)
	end	

end

function player:leave_see(other)
	self.view_obj[other.id] = nil
	other.watch_me[self.id] = nil

	local wpk = new_wpk(64)
	wpk_write_uint16(wpk,CMD_SC_LEAVESEE)
	wpk_write_uint32(wpk,other.id)	
	self:send2gate(wpk)	
	print(other.id .. " leave " .. self.id)
end


function player:mov(x,y)
	--[[local wpk = new_wpk(64)
	wpk_write_uint16(wpk,CMD_SC_MOV_ARRI)
	self:send2gate(wpk)		
	if true then
		return
	end]]--
	local path = self.map:findpath(self.pos,{x,y})
	if path then
		self.path = {cur=1,path=path}
		self.map:beginMov(self)
		self.lastmovtick = C.systemms()
		self.movmargin = 0

		local size = #self.path.path
		local target = self.path.path[size]
		local wpk = new_wpk(64)
		wpk_write_uint16(wpk,CMD_SC_MOV)
		wpk_write_uint32(wpk,self.id)
		--wpk_write_uint16(wpk,self.speed)
		wpk_write_uint16(wpk,target[1])
		wpk_write_uint16(wpk,target[2])	
		self:send2view(wpk)
		--self:send2gate(wpk)			
	else
		print("mov failed")
		local wpk = new_wpk(64)
		wpk_write_uint16(wpk,CMD_SC_MOV_FAILED)
		self:send2gate(wpk)			
	end
end


function player:reconn(maptype)
	local wpk = new_wpk(64)
	wpk_write_uint16(wpk,CMD_SC_ENTERMAP)
	wpk_write_uint16(wpk,maptype)
	wpk_write_uint32(wpk,self.id)
	wpk_write_uint16(wpk,self.groupid)
	self:send2gate(wpk)			

	for k,v in pairs(self.view_obj) do
		local wpk = new_wpk(1024)
		wpk_write_uint16(wpk,CMD_SC_ENTERSEE)
		wpk_write_uint32(wpk,v.id)
		wpk_write_uint8(wpk,v.avattype)
		wpk_write_uint16(wpk,v.avatid)
		wpk_write_string(wpk,"test")--other.nickname)
		wpk_write_uint16(wpk,v.pos[1])
		wpk_write_uint16(wpk,v.pos[2])
		wpk_write_uint8(wpk,v.dir)
		self:send2gate(wpk)
	
		if v.path then
			local size = #v.path.path
			local target = v.path.path[size]
			local wpk = new_wpk(64)
			wpk_write_uint16(wpk,CMD_SC_MOV)
			wpk_write_uint32(wpk,v.id)
			--wpk_write_uint16(wpk,other.speed)
			wpk_write_uint16(wpk,target[1])
			wpk_write_uint16(wpk,target[2])
			self:send2gate(wpk)
		end		
	end

end

local north = 1
local south = 2
local east = 3
local west = 4
local north_east = 5
local north_west = 6
local south_east = 7
local south_west = 8

local function direction(old_t,new_t,olddir)	
	local dir = olddir	
	if new_t[2] == old_t[2] then
		if new_t[1] > old_t[1] then
			dir = east
		elseif new_t[1] < old_t[1] then
			dir = west
		end
	elseif new_t[2] > old_t[2] then
		if new_t[1] > old_t[1] then
			dir = south_east
		elseif new_t[1] < old_t[1] then
			dir = south_west
		else 
			dir = south
		end
	else
		if new_t[1] > old_t[1] then
			dir = north_east
		elseif new_t[1] < old_t[1] then
			dir = north_west
		else 
			dir = north
		end	
	end
	return dir
end

local tiled_width = 32
local tiled_hight = 16

local tiled_half_width = tiled_width/2
local tiled_half_hight = tiled_hight/2

local function distance(dir)
	if dir == north or dir == south or dir == east or dir == west then
		return math.sqrt(tiled_half_width*tiled_half_width + tiled_half_hight*tiled_half_hight)
	elseif dir == south_east or dir == north_west then
		return tiled_hight
	else 
		return tiled_width
	end
end

function player:process_mov()
	local now = C.systemms()
	local movmargin = self.movmargin + now - self.lastmovtick
	local path = self.path.path
	local cur  = self.path.cur
	local size = #path
	while cur <= size do
		local node = path[cur]
		local tmpdir = direction(self.pos,node,self.dir)
		local dis    =  distance(tmpdir)
		local speed  = self.speed * 0.9 * (1000/30) / 1000
		local elapse = dis/speed
		if elapse < movmargin then
			self.dir = tmpdir
			self.pos = node
			cur = cur + 1
			movmargin = movmargin - elapse;			

			GameApp.aoi_moveto(self.aoi_obj,node[1],node[2])
		else
			break	
		end
	end
	self.path.cur = cur
	self.movmargin = movmargin
	self.lastmovtick = C.systemms()
	
	if self.path.cur > #self.path.path then

		self.path = nil
		print("arrive")
		local wpk = new_wpk(64)
		wpk_write_uint16(wpk,CMD_SC_MOV_ARRI)
		self:send2gate(wpk)		
		return true
	else
		return false
	end
end

return {
	NewPlayer = function (id,avatid) return player:new(id,avatid) end,
	type_player   = type_player,
	type_monster  = type_monster,
	type_pickable = type_pickable,
} 
