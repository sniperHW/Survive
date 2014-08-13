local Game = require "script/game"

local gatemgr = {
	con2gate  = {},
	name2gate = {}
}

local gate_net_handler = {}

gate_net_handler[CMD_AG_LOGIN] =  function (rpk,conn)
	C.set_conn_type(conn,GATESERVER)
	local name = rpk_read_string(rpk)
	if gatemgr.con2gate[conn] == nil and gatemgr.name2gate[name] == nil then
		local gate = {conn=conn,name=name,gateplys={}}
		gatemgr.con2gate[conn] = gate
		gatemgr.name2gate[name] = gate
		print("gateserver: " .. name .. " login success")
		--向gate发送game信息
		Game.OnGateLogin(gate)
	end
end

gate_net_handler[DUMMY_ON_GATE_DISCONNECTED] =  function (rpk,conn)
	print("gate_disconnected")
	if gatemgr.con2gate[conn] then
		local gate = gatemgr.con2gate[conn]
		gatemgr.con2gate[conn] = nil
		gatemgr.name2gate[gate.name] = nil
		print("gateserver: " .. gate.name .. " disconnected")
		
		for k,v in pairs(gate.gateplys) do
			v.gate = nil
		end
	end
end

local function reg_cmd_handler()
	print("gate reg_cmd_handler")
	C.reg_cmd_handler(CMD_AG_LOGIN,gate_net_handler)
	C.reg_cmd_handler(DUMMY_ON_GATE_DISCONNECTED,gate_net_handler)
end


function BoradCast2Gate(wpk)
	for k,_ in pairs(gatemgr.con2gate) do
		local l_wpk = new_wpk_by_wpk(wpk)
		C.send(k,l_wpk)
	end
	destroy_wpk(wpk)
end

local function insertGatePly(ply,gate)
	local t = gatemgr.con2gate[gate.conn]
	if t then
		t.gateplys[ply] = nil
	end
end

local function removeGatePly(ply,gate)
	local t = gatemgr.con2gate[gate.conn]
	if t then
		t.gateplys[ply] = ply
	end
end

local function getGateByName(name)
	return gatemgr.name2gate[name]
end

local function getGateByConn(conn)
	return gatemgr.con2gate[conn]
end

return {
	RegHandler = reg_cmd_handler,
	InsertGatePly = insertGatePly,
	RemoveGatePly = removeGatePly,
	GetGateByName = getGateByName,
	GetGateByConn = getGateByConn,
}
