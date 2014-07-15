local type_player   = 1    --玩家
local type_monster  = 2    --怪物
local type_pickable = 3    --地上可拾取物

local avatar ={
	id,            --对象索引
	avatid,        --模型id
	avattype,      --avatar类型
	pos,
	aoi_obj,
	see_radius,    --可视距离
	view_obj,      --在自己视野内的对象
	watch_me,      --可以看到我的对象
	gate,
	map,           --所在地图对象
	path,
	speed,         --移动速度
	lastmovtick,   --上次执行process_mov的时间  
	movmargin,     --可用于执行process_mov的剩余时间(毫秒)
	dir,           --当前朝向 
	nickname,      --昵称
	groupid,                 
}

function avatar:new(o)
  o = o or {}   
  setmetatable(o, self)
  self.__index = self
  self.pos = {}
  return o
end

--向可以看到我的对象发消息
function avatar:send2view(wpk)
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
		local w = new_wpk_by_wpk(wpk)
		local plys = v.plys
		for k1,v1 in pairs(plys) do
			wpk_write_uint32(w,v1.gate.id.high)
			wpk_write_uint32(w,v1.gate.id.low)
		end
		wpk_write_uint32(w,#plys)
		C.send(v.conn,w)
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
	self.id = id
	self.avatid = avatid
	self.avattype = type_player
	self.see_radius = 5
	self.view_obj = {}
	self.watch_me = {}
	self.gate = nil
	self.map =  nil
	self.path = nil
	self.speed = 3
	self.pos = nil
	self.nickname = ""
	self.aoi_obj = GameApp.create_aoi_obj(o)
	return o	
end

function player:send2gate(wpk)
	if not self.gate then
		return
	end	
	wpk_write_uint32(wpk,self.gate.id.high)
	wpk_write_uint32(wpk,self.gate.id.low)
	wpk_write_uint32(wpk,1)
	C.send(self.gate.conn,wpk)	
end

function player:enter_see(other)
	print("enter_see")
	print(self)
	C.debug()
	self.view_obj[other.id] = other
	other.watch_me[self.id] = self	
	
	--通告客户端	
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
	print("enter_see 1")
	
	if other.path then
		local size = #other.path.path
		local target = other.path.path[size]
		local wpk = new_wpk(64)
		wpk_write_uint16(wpk,CMD_SC_MOV)
		wpk_write_uint32(wpk,other.id)
		wpk_write_uint16(wpk,other.speed)
		wpk_write_uint16(wpk,target[1])
		wpk_write_uint16(wpk,target[2])
		self:send2gate(wpk)
	end	
	print("enter_see 2")
end

function player:leave_see(other)
	self.view_obj[other.id] = nil
	other.watch_me[self.id] = nil
	--通告客户端		
	local wpk = new_wpk(64)
	wpk_write_uint16(wpk,CMD_SC_LEAVESEE)
	wpk_write_uint32(wpk,other.id)	
	self:send2gate(wpk)	
end

--处理客户端的移动请求
function player:mov(x,y)
	print("player:mov")
	local path = self.map:findpath(self.pos,{x,y})
	if path then
		self.path = {cur=1,path=path}
		self.map:beginMov(self)
		self.lastmovtick = C.systemms()
		self.movmargin = 0
		--将移动请求广播到视野
		local size = #self.path.path
		local target = self.path.path[size]
		local wpk = new_wpk(64)
		wpk_write_uint16(wpk,CMD_SC_MOV)
		wpk_write_uint32(wpk,self.id)
		wpk_write_uint16(wpk,self.speed)
		wpk_write_uint16(wpk,target[1])
		wpk_write_uint16(wpk,target[2])	
		self:send2view(wpk)
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
	if new_t.y == old_t.y then
		if new_t.x > old_t.x then
			dir = east
		elseif new_t.x < old_t.x then
			dir = west
		end
	elseif new_t.y > old_t.y then
		if new_t.x > old_t.x then
			dir = south_east
		elseif new_t.x < old_t.x then
			dir = south_west
		else 
			dir = south
		end
	else
		if new_t.x > old_t.x then
			dir = north_east
		elseif new_t.x < old_t.x then
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
			--更新aoi
			GameApp.aoi_moveto(self.aoi_obj,node[1],node[2])
		else
			break	
		end
	end
	self.path.cur = cur
	self.movmargin = movmargin
	self.lastmovtick = C.systemms()
	
	if self.path.cur == #self.path.path then
		--到达目的地
		self.path = nil
		print("arrive")
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
