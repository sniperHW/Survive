local Cjson = require "cjson"

local pending_rpc = {}
local rpc_function = {}
local counter = 1

local rpcCall(conn,remoteFunc,param,callbackObj)
	local rpcno = '' .. C.systemms .. '' .. counter
	counter = counter + 1
	local wpk = new_wpk()
	wpk_write_uint16(wpk,CMD_RPC_CALL)
	local rpcReq = {rpcno = rpcno,param=param}
	wpk_write_string(Cjson.encode(rpcReq))
	if C.send(conn,wpk) then
		local conn_pending_rpc = pending_rpc[conn]
		if not conn_pending_rpc then
			conn_pending_rpc = {}
			pending_rpc[conn] = conn_pending_rpc
		end
		conn_pending_rpc[rpcno] = callbackObj
		return true
	else
		return false
	end
end

local rpcResponse(rpcHandle,result,error)
	local conn = rpcHandle.conn
	local rpcno = rpcHandle.rpcno
	local response = {rpcno = rpcno,ret=result,err=error}
	local wpk = new_wpk()
	wpk_write_uint16(wpk,CMD_RPC_RESPONSE)
	wpk_write_string(Cjson.encode(response))
	C.send(conn,wpk)
end


local registerRpcFunction(name,func)
	rpc_function[name] = func
end


local function RPC_CALL(_,rpk,conn)
	local funcname = rpk_read_string(rpk)
	local rpcHandle = Cjson.decode(rpk_read_string(rpk))
	rpcHandle.conn = conn
	local func = rpc_function[funcname]
	if func then
		--todo use pcall
		func(rpcHandle)
	else
		rpcResponse(rpcHandle,nil,"unknow function:" .. func)
	end
end

local function	RPC_RESPONSE(_,rpk,conn)
	local response = Cjson.decode(rpk_read_string(rpk))
	local conn_pending_rpc = pending_rpc[conn]
	if conn_pending_rpc then
		local callbackObj = conn_pending_rpc[response.rpcno]
		if callbackObj then
			callbackObj.OnRPCResponse(callbackObj,response.ret,response.err)
		end
	end
end

local function  onDisconnect(conn)
	local conn_pending_rpc = pending_rpc[conn]
	if conn_pending_rpc then
		for k,v in do 
			v.OnRPCResponse(v,nil,"connection loss")
		end
		pending_rpc[conn] = nil
	end
end

local function reg_cmd_handler()
	GameApp.reg_cmd_handler(CMD_RPC_CALL,{handle=RPC_CALL})
	GameApp.reg_cmd_handler(CMD_RPC_RESPONSE,{handle=RPC_RESPONSE})
end

return {
	RegHandler = reg_cmd_handler,
	RPCCall = rpcCall,
	RPCResponse = rpcResponse,
	RegisterRpcFunction = registerRpcFunction,
	OnDisconnect = onDisconnect,
}
