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
			print(name .. " Login Success")
			return "Login Success"
		else
			return "Login failed"
		end
	end)
end

local function OnGateDisconnected(sock,errno)
	local gate = sock2gate[sock]
	if gate then
		print(gate.name .. " disconnected")
		for k,v in pairs(gate.players) do
			--玩家的网络连接断开
			v.gatesession = nil
		end
		sock2gate[sock] = nil
		name2gate[gate.name] = nil
	end
end

local function Bind(gate,player,sessionid)
	 gate.players[player] = player
	 player.gatesession = {sock=gate.sock,sessionid=sessionid,gate=gate}
end

local function UnBind(player)
	local gate = player.gatesession.gate
	if gate then
		gate.players[player] = nil
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
