local Que = require "queue"

local player = {
	groupid,    --在group管理器中的player对象索引
	gameid,     --在game管理器中的player对象索引(如果有)
	gateid,     --在gateserver中agentplayer对象的索引
	gateconn,   --所在gateserver的网络连接
	gameconn,   --所在gameserver的网络连接(如果有)
	actname,    --帐号名
	chaname,    --角色名
	attr,       --角色属性
}

local function player:new(o)
  o = o or {}   
  setmetatable(o, self)
  self.__index = self
  self.groupid = 0
  self.game = nil
  self.gate = nil
  self.actname = nil
  self.chaname = nil
  self.attr = {}
  return o
end


local function initfreeidx()
	local que = Que.Queue()
	for i=1,65536 do
		que:push({v=i,__next=nil})
	end
	return que
end 

--player管理容器
local playermgr = {
	freeidx = initfreeidx(),
	players = {},
	actname2player ={},
}

local function playermgr:new_player(actname)
	if not actname or actname = '' then
		return nil
	end
	if self.freeidx:is_empty() then
		return nil
	else
		local newply = player:new()
		newply.actname = actname
		newply.groupid = self.freeidx:pop().v
		self.players[newply.groupid] = newply
		self.actname2player[actname] = newply
		return newply
	end
end

local function playermgr:release_player(ply)
	if ply.groupid and ply.groupid >= 1 and ply.groupid <= 65536 then
		self.freeidx:push({v=ply.groupid,__next=nil})
		self.players[ply.groupid] = nil
		self.actname2player[ply.actname] = nil
		ply.groupid = nil
	end
end

local function playermgr:getplybyid(groupid)
	return self.players[groupid]
end

local function playermgr:getplybyactname(actname)
	if not actname or actname = '' then
		return nil
	end
	return self.actname2player[actname]
end


local function AG_PLYLOGIN(rpk,conn)
	local actname = rpk_read_string(rpk)
	local gateid = {}
	gateid.high = rpk_read_uint32(rpk)
	gateid.low = rpk_read_uint32(rpk)
	
	local ply = playermgr:getplybyactname(actname)
	if ply then
		--玩家没有下线还在游戏中,现在重新与服务器建立连接，处理重连逻辑
		return
	end
	
	ply = playermgr:new_player(actname)
	if not ply then
		--通知gate繁忙，请求gate断开客户端连接
		local wpk = new_wpk()
		wpk_write_uint16(wpk,CMD_GA_BUSY)
		wpk_write_uint32(wpk,gateid.high)
		wpk_write_uint32(wpk,gateid.low)
		C.send(conn,wpk)
	else
		ply.gate = {id=gateid,conn = conn}
		--从数据库导入玩家数据
	end
end

local function CG_CREATE(rpk,conn)
	local chaname = rpk_read_string(rpk)
	local groupid = rpk_read_uint32(rpk)
	--执行创建流程
	local wpk = new_wpk()
	wpk_write_uint16(wpk,CMD_GC_BEGINPLY)
	wpk_write_uint32(wpk,gateid.high)
	wpk_write_uint32(wpk,gateid.low)
	C.send(conn,wpk)
end


local function reg_cmd_handler()
	GroupApp.reg_cmd_handler(CMD_AG_PLYLOGIN,{handle=AG_PLYLOGIN})
	GroupApp.reg_cmd_handler(CMD_CG_CREATE,{handle=CG_CREATE})
end

return {
	RegHandler = reg_cmd_handler,
}