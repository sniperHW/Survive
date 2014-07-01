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
}

function avatar:new(o)
  o = o or {}   
  setmetatable(o, self)
  self.__index = self
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


local player = avatar:new()

function player:new(id,avatid)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	self.id = id
	self.avatid = avatid
	self.avattype = type_player
	self.aoi_obj = GameApp.create_aoi_obj(self)
	self.see_radius = 5
	self.view_obj = {}
	self.watch_me = {}
	self.gate = nil
	self.map =  nil
	self.path = nil
	self.speed = 3
	self.pos = nil
	return o	
end


function player:isInMyScope(other)
	return 1
end

function player:enter_see(other)
	--通告客户端
	self.view_obj[other.id] = other
	other.watch_me[self.id] = self
end

function player:leave_see(other)
	--通告客户端
	self.view_obj[other.id] = nil
	other.watch_me[self.id] = nil
end

--处理客户端的移动请求
function player:mov(x,y)
	local path = self.map:findpath(self.pos,{x,y})
	if path then
		self.path = {cur=1,path=path}
		self.map:beginMov(self)
	end
end

function player:process_mov()
		
	if self.path.cur == #self.path.path then
		self.path = nil
		return true
	else
		return false
	end
end

return {
	NewPlayer = function (id,avatid) return player:new(id,avatid) end,
} 
