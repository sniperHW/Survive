local Que = require "lua/queue"
local NetCmd = require "Survive/netcmd/netcmd"
local freeidx = Que.New()

local id2player = {}
local sock2player = {}

--限制gateserver最大连接数4096
for i=1,4096 do
	freeidx:Push({v=i})
end

local function GetIdx()
	local n = freeidx:Pop()
	if n then 
		return n.v
	else
		return nil
	end
end

local function ReleaseIdx(idx)
	freeidx:Push({v=idx})
end

local verifying = 1
local login2group = 2
local createcha = 3
local playing = 4
local releasing = 5

local player = {}

function player:new()
	 local idx = GetIdx()
	 if not idx then
		return nil
	 end
	 local o = {}   
	 setmetatable(o, self)
	 self.__index = self
	 o.sessionid = bit32.lshift(idx,16) + bit32.band(GetSysTick(),0x0000FFFF)
	 return o
end

function player:GetId()
	return bit32.rshift(self.sessionid,16)
end

function player:GetTStamp()
	return bit32.band(self.sessionid,0x0000FFFF)
end

function player:Send2Client(wpk)
	if self.sock then
		self.sock:Send(wpk)
	end
end


local function GetPlayerById(sessionid)
	return id2player[sessionid]
end

local function GetPlayerBySock(sock)
	return sock2player[sock]
end

local function NewGatePly(sock)
	local ply = player:new()
	if ply then
		ply.sock = sock
		id2player[ply.sessionid] = ply 
		sock2player[sock] = ply
	end
	return ply
end

local function ReleasePlayer(ply)
	if ply.sessionid then	
		print("ReleasePlayer")	
		--通知group和game连接断开
		local wpk = CPacket.NewWPacket(64);
		wpk:Write_uint16(NetCmd.CMD_AG_CLIENT_DISCONN);
		wpk:Write_uint16(ply.groupsession);
		Send2Group(wpk)		
		id2player[ply.sessionid] = nil
		sock2player[ply.sock] = nil
		ReleaseIdx(ply:GetId())
		ply.sessionid = nil
	end
end

local function OnPlayerDisconnected(sock,errno)
	print("OnPlayerDisconnected")
	local ply = GetPlayerBySock(sock)
	if not ply then
		return
	end	
	if ply.status == verifying or ply.status == login2group then
		ply.status = releasing	
	else
		ReleasePlayer(ply)
	end
end

local function OnGameDisconnected(sock)
	for k,v in pairs(id2player) do
		if v.gamesession and v.gamesession.sock == sock then
			v.gamesession = nil
			v.sock:Close()
		end
	end
end

local function OnGroupDisconnected()
	for k,v in pairs(id2player) do
			v.sock:Close()
	end	
end

local function IsVaild(ply)
	return ply.status ~= releasing
end

return {
	NewGatePly = NewGatePly,
	GetPlayerBySock = GetPlayerBySock,
	GetPlayerById = GetPlayerById,
	ReleasePlayer = ReleasePlayer,
	OnPlayerDisconnected = OnPlayerDisconnected,
	OnGameDisconnected = OnGameDisconnected,
	OnGroupDisconnected = OnGroupDisconnected,
	IsVaild = IsVaild,
	verifying = verifying,
	login2group = login2group,
	createcha = createcha,
	playing = playing,
	releasing = releasing	
}
