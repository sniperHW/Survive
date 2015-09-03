--[[
rpc连接只能发送和接收CSocket.rpkdecoder()格式的封包
]]--

local cjson = require "cjson"
local Sche = require "lua.sche"
local Timer = require "lua.timer"

local CMD_RPC_CALL =  0xABCDDBCA
local CMD_RPC_RESP =  0xDBCAABCD

local function gen_rpc_identity()
	local g_counter = 0
	return function ()
		g_counter = math.modf(g_counter + 1,0xffffffff)
		return {h=os.time(),l=g_counter} 
	end	
end

gen_rpc_identity = gen_rpc_identity()

local function identity_to_string(identity)
	return string.format("%d:%d",identity.h,identity.l)
end


local minheap =  CMinHeap.New()
local timeout_checker

local function init_timeout_checker()
	timeout_checker = Timer.New():Register(function ()
				local contexts = minheap:Pop(C.GetSysTick())
				if contexts then
					for k,v in pairs(contexts) do
						v.on_timeout()
					end
				end
		     	       end,1)
	Sche.Spawn(function() timeout_checker:Run() end)	
end

local function RPC_Process_Call(app,s,rpk)
	local request = rpk:Read_table()
	local identity = request.identity
	s.rpc_record = s.rpc_record or {0,0}
	if identity.l > s.rpc_record[2] or identity.h >  s.rpc_record[1] then
		s.rpc_record[1] = identity.h
		s.rpc_record[2] = identity.l
		local funname = request.f
		local func = app._RPCService[funname]
		table.insert(request.arg,s)
		if request.noret then
			if not func then
				CLog.SysLog(CLog.LOG_ERROR,funname .. " not found")
			else	
				local stack,errmsg
				if not xpcall(func,
							  function (err)
							  	errmsg = err
							  	stack  = debug.traceback() 
							  end,table.unpack(request.arg)) then
					CLog.SysLog(CLog.LOG_ERROR,string.format("rpc process error:%s\n%s",errmsg,stack))

				end
			end
		else
			local response = {identity = identity}
			if not func then
				response.err = funname .. " not found"
			else	
				local stack,errmsg
				local ret = table.pack(xpcall(func,
											  function (err)
											  	errmsg = err
											  	stack  = debug.traceback()
											  end,table.unpack(request.arg)))
				if ret[1] then
					table.remove(ret,1)			
					response.ret = ret
				else
					response.err = errmsg
					CLog.SysLog(CLog.LOG_ERROR,string.format("rpc process error:%s\n%s",errmsg,stack))
				end
			end
			local wpk = CPacket.NewWPacket(512)
			wpk:Write_uint32(CMD_RPC_RESP)
			wpk:Write_table(response)
			s:Send(wpk)
		end
	end
end

local function RPC_Process_Response(s,rpk)
	local response = rpk:Read_table()
	if not response then
		CLog.SysLog(CLog.LOG_ERROR,string.format("rpc read table error"))		
		return
	end
	local id_string = identity_to_string(response.identity)
	local context = s.pending_call[id_string]
	if context then
		s.pending_call[id_string] = nil
		minheap:Remove(context)		
		if context.callback then			
			local stack,errmsg
			if not xpcall(context.callback,
						  function (err)
						  	errmsg = err
						  	stack  = debug.traceback()
						  end,response.err,table.unpack(response.ret)) then
				CLog.SysLog(CLog.LOG_ERROR,string.format("CallAsync error in callback:%s\n%s",errmsg,stack))
			end		
		elseif context.co then
			context.co.response = response
			Sche.WakeUp(context.co)
		end
	end
end

local rpcCaller = {}

function rpcCaller:new(s,funcname)
	local o = {}
	self.__index = self      
	setmetatable(o,self)
	o.s = s
	s.minheap = s.minheap or minheap
	s.pending_call = s.pending_call or {}	
	o.funcname = funcname
	return o
end

function rpcCaller:CallAsync(callback,...)

	if not callback then
		return "need a callback function"
	end

	local request = {}
	local co = Sche.Running()
	request.f = self.funcname
	local socket = self.s	
	request.identity = gen_rpc_identity()
	local id_string = identity_to_string(request.identity)
	request.arg = {...}
	local wpk = CPacket.NewWPacket(512)
	wpk:Write_uint32(CMD_RPC_CALL)
	wpk:Write_table(request)	

	local ret = socket:Send(wpk)
	if ret then
		return "socket error"
	end

	local context = {callback=callback}
	socket.pending_call[id_string]  = context
	if not timeout_checker then
		init_timeout_checker()
	end
	local trycount = 1
	context.on_timeout = function()
		if trycount <= 2 then
			local wpk = CPacket.NewWPacket(512)
			wpk:Write_uint32(CMD_RPC_CALL)
			wpk:Write_table(request)			
			ret = socket:Send(wpk)
			if ret then
				return "socket error"
			end			
			trycount= trycount + 1			
			minheap:Insert(context,C.GetSysTick() + 5000)		
		else
			local stack,errmsg
			if not xpcall(callback,
						  function (err)
						  	errmsg = err
						  	stack  = debug.traceback()
						  end,{err="timeout"}) then
				CLog.SysLog(CLog.LOG_ERROR,string.format("CallAsync error in callback:%s\n%s",errmsg,stack))
			end
			socket.pending_call[id_string] = nil
			return
		end
	end
	minheap:Insert(context,C.GetSysTick() + 5000)	
end

function rpcCaller:CallNoRet(...)
	local request = {}
	local co = Sche.Running()
	local socket = self.s
	request.f = self.funcname
	request.identity = gen_rpc_identity()
	request.arg = {...}
	request.noret = true
	local wpk = CPacket.NewWPacket(512)
	wpk:Write_uint32(CMD_RPC_CALL)
	wpk:Write_table(request)
	
	local ret = socket:Send(wpk)
	if ret then
		return "socket error"
	end
	local trycount = 1
	local context = {}
	context.on_timeout = function()
		if trycount <= 2 then
			local wpk = CPacket.NewWPacket(512)
			wpk:Write_uint32(CMD_RPC_CALL)
			wpk:Write_table(request)			
			ret = socket:Send(wpk)
			if ret then
				return
			end			
			trycount= trycount + 1			
			minheap:Insert(context,C.GetSysTick() + 5000)		
		end
	end
	minheap:Insert(context,C.GetSysTick() + 5000)
	if not timeout_checker then
		init_timeout_checker()
	end	
end

function rpcCaller:CallSync(...)
	local request = {}
	local co = Sche.Running()
	local socket = self.s
	request.f = self.funcname
	request.identity = gen_rpc_identity()
	local id_string = identity_to_string(request.identity)
	request.arg = {...}
	local wpk = CPacket.NewWPacket(512)
	wpk:Write_uint32(CMD_RPC_CALL)
	wpk:Write_table(request)
	
	local ret = socket:Send(wpk)
	if ret then
		return "socket error"
	end
	local trycount = 1
	local context = {co = co}
	socket.pending_call[id_string]  = context	
	context.on_timeout = function()
		if trycount <= 2 then
			local wpk = CPacket.NewWPacket(512)
			wpk:Write_uint32(CMD_RPC_CALL)
			wpk:Write_table(request)			
			ret = socket:Send(wpk)
			if ret then
				return "socket error"
			end			
			trycount= trycount + 1			
			minheap:Insert(context,C.GetSysTick() + 5000)		
		else
			co.response = {err="timeout"}
			socket.pending_call[id_string] = nil
			Sche.Schedule(co)
			return
		end
	end
	minheap:Insert(context,C.GetSysTick() + 5000)
	if not timeout_checker then
		init_timeout_checker()
	end	
	Sche.Block()
	local response = co.response
	co.response = nil
	if not response.ret then
		return response.err,nil
	else
		return response.err,table.unpack(response.ret)
	end	
end

local function RPC_MakeCaller(s,funcname)
	return rpcCaller:new(s,funcname)
end

return {
	ProcessCall = RPC_Process_Call,
	ProcessResponse = RPC_Process_Response,
	MakeRPC = RPC_MakeCaller,
	CMD_RPC_CALL =  CMD_RPC_CALL,
	CMD_RPC_RESP =  CMD_RPC_RESP,
}
