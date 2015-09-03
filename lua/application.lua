local Sche = require "lua.sche"
local RPC = require "lua.rpc"
local Timer = require "lua.timer"
local application = {}


--[[
对于每一个socket至少需要1-N个coroutine为其执行recver函数,以处理在这个socket上接收到的数据包.
但是,当recver执行处理数据包逻辑的时候,在用户的逻辑处理函数中有可能导致当前coroutine阻塞.假设只有
一个coroutine在为一个socket执行recver,并且在执行用户处理函数的时候当前coroutine被阻塞.则在阻塞期
间这个socket上到达的所有数据包都将无法被处理,直到coroutine解除阻塞.

因此,一般情况下,当没有recver可用的情况下会spawn一个新的coroutine去执行recver.

max_recver_per_socket的作用就是设定每个socket的recver上限.当达到这个数量之后,即使没有可用的
recver,也不会为这个socket产生一个新的coroutine去执行recver

如果应用在设计时就已经预计到在处理函数中会出现大量的阻塞操作,则可将此值设大点.	
]]--


local default_recver_per_socket = 64

function application:new(max_recver_per_socket)
  local o = {}   
  setmetatable(o, self)
  self.__index = self
  if not max_recver_per_socket or max_recver_per_socket == 0 then
	max_recver_per_socket = default_recver_per_socket
  end
  o._RPCService = {}
  o.max_recver_per_socket = max_recver_per_socket
  return o
end

local CMD_PING = 0xABABCBCB

local function recver(app,socket)
	socket.recver_count = socket.recver_count + 1
	while true do--app.running do
		local rpk,err = socket:Recv()
		if err then
			socket:Close()
			break
		end
		if rpk then
			if socket.check_recvtimeout then 
				socket.lastrecv = C.GetSysTick()
			end
			local cmd = rpk:Peek_uint32()
			if cmd and cmd == RPC.CMD_RPC_CALL or cmd == RPC.CMD_RPC_RESP then
				--如果是rpc消息，执行rpc处理
				if cmd == RPC.CMD_RPC_CALL then
					rpk:Read_uint32()
					RPC.ProcessCall(app,socket,rpk)
				elseif cmd == RPC.CMD_RPC_RESP then
					rpk:Read_uint32()
					RPC.ProcessResponse(socket,rpk)
				end
			elseif cmd and cmd == CMD_PING then
				return		
			elseif socket.process_packet then
				local stack,errmsg
				if not xpcall(socket.process_packet,
					   		  function (err)
					   		  	errmsg = err	
					   			stack = debug.traceback()	
					   		  end,socket,rpk) then
					CLog.SysLog(CLog.LOG_ERROR,
								string.format("application process_packet error:%s\n%s\n",errmsg,stack))
				end
			end
		end
		--if socket.recver_count > app.max_recver_per_socket then
		--	break
		--end 	
	end
	socket.recver_count = socket.recver_count - 1
end


local heart_beat_timer = Timer.New("runImmediate")

function application:Add(socket,on_packet,on_disconnected,recvtimeout,pinginterval)
	if not socket.app then
		socket.app = self
		socket.recver_count = 0
		socket.process_packet = on_packet
		local app = self
		socket.on_disconnected = function (sock,errno)
						sock.app = nil
						if on_disconnected then
							on_disconnected(sock,errno)
						end
					end
		socket.check_recvtimeout = recvtimeout
		--改变conn.sock.__on_packet的行为
		socket.__on_packet = function (socket,packet)
			socket.packet:Push({packet})
			local co = socket.recv_wakeup
			if not co then
				co = socket.block_recv:Pop()
				socket.recv_wakeup = co
			end
			if co then
				co = co[1]
				Sche.WakeUp(co)
			elseif socket.recver_count < app.max_recver_per_socket then
				Sche.SpawnAndRun(recver,app,socket)
			end
		end
		
		if recvtimeout then
			socket.lastrecv = C.GetSysTick()
			heart_beat_timer:Register(
				function ()
					if socket.luasocket then
						if C.GetSysTick() > socket.lastrecv + recvtimeout then
							socket:Close()
							return "stoptimer"
						end
					else
						return "stoptimer"
					end
				end,1000)
		end
		
		if pinginterval then
			heart_beat_timer:Register(
				function ()
					if socket.luasocket then
						local wpk = CPacket.NewWPacket(64)
						wpk:Write_uint32(CMD_PING)
						socket:Send(wpk)
					else
						return "stoptimer"
					end
				end,pinginterval)		
		end	
	end
	return self
end

function application:RPCService(name,func)
	self._RPCService[name] = func
end

return {
	New =  function (max_recver_per_socket) return application:new(max_recver_per_socket) end,
}
