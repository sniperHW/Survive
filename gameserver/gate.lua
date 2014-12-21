local sock2gate = {}
local name2gate = {}

local function RegRpcService(app)
	--gateserver登录到gameserver
	app:RPCService("Login",function (sock,name)
		if sock2gate[sock] == nil and name2gate[name] == nil then
			local gate = {sock = sock,name = name,players={}}
			sock.type = "gate"
			sock2gate[sock] = gate
			name2gate[name] = gate
			log_gameserver:Log(CLog.LOG_INFO,name .. " login success")
			return "Login Success"
		else
			return "Login failed"
		end
	end)
end

local function OnGateDisconnected(sock,errno)
	local gate = sock2gate[sock]
	if gate then
		log_gameserver:Log(CLog.LOG_INFO,gate.name .. " disconnected")
		for k,v in pairs(gate.players) do
			--玩家的网络连接断开
			v.gatesession = nil
		end
		sock2gate[sock] = nil
		gate.sock = nil
		name2gate[gate.name] = nil
	end
end

local function Bind(gate,player,sessionid)
	 gate.players[player.id] = player
	 player.gatesession = {sock=gate.sock,sessionid=sessionid,gate=gate}
end

local function UnBind(player)
	if not player.gatesession then
		return
	end
	local gate = player.gatesession.gate
	if gate then
		gate.players[player.id] = nil
		player.gatesession = nil
	end
end

function BoradCast2Gate(wpk)
	for k,v in pairs(sock2gate) do
		k:Send(CPacket.NewWPacket(wpk))
	end
end

function GetGateByName(name)
	return name2gate[name]
end

return {
	Bind = Bind,
	UnBind = UnBind,
	OnGateDisconnected = OnGateDisconnected,
	RegRpcService = RegRpcService,
	GetGateByName = GetGateByName, 
}
