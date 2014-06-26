
local gatemgr = {
	con2gate  = {},
	name2gate = {}
}


local function gate_login(_,rpk,conn)
	local name = rpk_read_string(rpk)
	if gatemgr.con2gate[conn] == nil and gatemgr.name2gate[name] == nil then
		local gate = {conn=conn,name=name}
		gatemgr.con2gate[conn] = gate
		gatemgr.name2gate[name] = gate
		print("gateserver: " .. name .. " login success")
		--向gate发送game信息		
	end
end

local function gate_disconnected(_,rpk,conn)
	print("gate_disconnected")
	if gatemgr.con2gate[conn] then
		local gate = gatemgr.con2gate[conn]
		gatemgr.con2gate[conn] = nil
		gatemgr.name2gate[gate.name] = nil
		print("gateserver: " .. gate.name .. " disconnected")
	end
end

local function reg_cmd_handler()
	print("gate reg_cmd_handler")
	GroupApp.reg_cmd_handler(CMD_AG_LOGIN,{handle=gate_login})
	GroupApp.reg_cmd_handler(DUMMY_ON_GATE_DISCONNECTED,{handle=gate_disconnected})
end


local function BoradCast(wpk)
	for k,_ in pairs(gatemgr.con2gate) do
		local l_wpk = C.new_wpk_by_wpk(wpk)
		C.send(k,l_wpk)
	end
	destroy_wpk(wpk)
end

return {
	RegHandler = reg_cmd_handler,
	BoradCast = BoradCast,
}
