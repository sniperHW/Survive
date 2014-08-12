--所有连接上router的daemonserver
local Rpc = require "script/rpc.lua"
local Cjson = require "cjson"

local machines = {}
local net_handler = {}


Rpc.RegisterRpcFunction("DaemonLogin",function (rpcHandle)
	local param = rpcHandle.param
	local name  = param[1] --暂时使用ip作为name	
	
	if machines[name] then
		Rpc.RPCResponse(rpcHandle,nil,name .. "already exist")
		return 
	end	
	machines[name] = {conn=rpcHandle.conn}
	Rpc.RPCResponse(rpcHandle,nil,nil)
end)

--启动另一台机器上的进程
Rpc.RegisterRpcFunction("Start",function (rpcHandle)
	local param = rpcHandle.param
	local target  = param[1] --暂时使用ip作为name	
	
	if machines[name] then
		Rpc.RPCResponse(rpcHandle,nil,name .. "not found")
		return 
	end	
	local cmd = param[2] --启动命令
	local r = Rpc.RPCCall(machines[name].conn,"Start",cmd,{OnRPCResponse=function (_,ret,err)
				Rpc.RPCResponse(rpcHandle,ret,err)
			end})
	if not r then
		Rpc.RPCResponse(rpcHandle,nil,"call Start failed")
	end
end)


--关闭另一台机器上的进程
Rpc.RegisterRpcFunction("Stop",function (rpcHandle)
	local param = rpcHandle.param
	local target  = param[1] --暂时使用ip作为name	
	
	if machines[name] then
		Rpc.RPCResponse(rpcHandle,nil,name .. "not found")
		return 
	end	
	local cmd = param[2] --启动命令
	local r = Rpc.RPCCall(machines[name].conn,"Stop",cmd,{OnRPCResponse=function (_,ret,err)
				Rpc.RPCResponse(rpcHandle,ret,err)
			end})
	if not r then
		Rpc.RPCResponse(rpcHandle,nil,"call Stop failed")
	end
end)

net_handler[DUMMY_ON_DAEMON_CONNECTED] = function (rpk,conn)
	for k,v in pairs(machines) do
		if v.conn == conn then
			machines[k] = nil
			return
		end
	end 
end

local function reg_cmd_handler()
	C.reg_cmd_handler(DUMMY_ON_DAEMON_CONNECTED,net_handler)
end

return {
	RegHandler = reg_cmd_handler,
}


