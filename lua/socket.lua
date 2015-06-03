--[[
对CluaSocket的一层lua封装,提供协程化的阻塞接口,使得在应用上以阻塞的方式调用
Recv,Send,Connect,Accept等接口,而实际是异步处理的
]]--

local Sche = require "lua.sche"
local LinkQue  = require "lua.linkque"
local socket = {}

--function for stream socket
local stream = {}

function stream.on_new_conn(self,sock)
	self.new_conn:Push({sock})	
	local co = self.block_onaccept:Pop()
	if co then
		Sche.WakeUp(co)--Schedule(co)
	end
end

function stream.Listen(self,ip,port)
	if not self.luasocket then
		return "socket close"
	end
	if self.block_onaccept or self.new_conn then
		return "already listening"
	end
	self.block_onaccept = LinkQue.New()
	self.new_conn = LinkQue.New()
	self.__on_new_connection = stream.on_new_conn
	self.Connect = nil
	self.Accept = stream.Accept
	return CSocket.listen(self.luasocket,ip,port)
end

function stream.cb_connect (self,err)
	if err ~= 0 then
		self.errno = err
	else
		self.Establish = stream.Establish
	end
	local co = self.connect_co
	if co then
		self.connect_co = nil
		Sche.WakeUp(co)
	end
end

function stream.Connect(self,ip,port)
	self.Listen = nil
	self.Accept = nil
	local err,ret = CSocket.connect(self.luasocket,ip,port)
	if err then
		return err
	else
		if ret == 0 then
			self.connect_co = Sche.Running()
			self.___cb_connect = stream.cb_connect
			Sche.Block()
			if not self.luasocket then
				return "socket close"
			elseif self.errno ~= 0 then
				return "connect error"
			end
		elseif ret == 1 then
			print("success immediately")
			self.Establish = stream.Establish			
		end				
	end
end

 function stream.Accept(self)
	if not self.luasocket then
		return nil,"socket close"
	end
	if not self.block_onaccept or not self.new_conn then
		return nil,"invaild socket"
	else	
		while true do
			local s = self.new_conn:Pop()
			if s then
			    s = s[1]
				local sock = socket:new2(s)
				sock.Establish = stream.Establish
				return sock,nil
			else
				local co = Sche.Running()
				self.block_onaccept:Push(co)
				Sche.Block()
				if  not self.luasocket then
					return nil,"socket close" --socket被关闭
				end				
			end
		end
	end
end

function stream.Recv(self,timeout)
	--[[
	尝试从套接口中接收数据,如果成功返回数据,如果失败返回nil,错误描述
	timeout参数如果为nil,则当socket没有数据可被接收时Recv调用将一直阻塞
	直到有数据可返回或出现错误.否则在有数据可返回或出现错误之前Recv最少阻塞
	timeout毫秒
	]]--
	if not self.luasocket then
		return nil,"socket close"
	end 		
	while true do	
		local packet = self.packet:Pop()
		if packet then
			return packet[1],nil
		end		
		local co = Sche.Running()
		co = {co}	
		self.block_recv:Push(co)		
		local ret = Sche.Block(timeout)
		self.recv_wakeup = nil
		if ret == "timeout" then
			self.block_recv:Remove(co)
			return nil,"recv timeout"
		elseif not self.luasocket then
			return nil,(self.errno == nil or self.errno == 0) and "socket close" or self.errno
		end

	end	
end

function stream.Send(self,packet)
	--[[
	将packet发送给对端，如果成功返回nil,否则返回错误描述.
	(此函数不会阻塞,立即返回)
	]]--	
	if not self.luasocket then
		return "socket close"
	end
	return CSocket.stream_send(self.luasocket,packet)
end

function stream.__send_complete(self)
	local callback_index = self.block_send.callback_index
	local co = self.block_send.coros[callback_index]
	if co then
		self.block_send.count = self.block_send.count - 1
		self.block_send.coros[callback_index] = nil
		Sche.WakeUp(co)
	end
	self.block_send.callback_index = self.block_send.callback_index + 1	
	if self.block_send.count == 0 then
		self.block_send.coros = {}
		self.block_send.callback_index = 1
		self.block_send.sync_send_idx = 1				
	end
end

function stream.SendSync(self,packet,timeout)
	if not self.luasocket then
		return "socket close"
	end
	local ret = CSocket.stream_syncsend(self.luasocket,packet)
	if not ret then
		self.__send_complete = self.__send_complete or stream.__send_complete
		local co = Sche.Running()
		local idx = self.block_send.sync_send_idx
		self.block_send.sync_send_idx = self.block_send.sync_send_idx + 1
		self.block_send.count = self.block_send.count + 1
		self.block_send.coros[idx] = co		
		if "timeout" == Sche.Block(timeout) then
			self.block_send.coros[idx] = nil
			self.block_send.count = self.block_send.block_count - 1
			if self.block_send.count == 0 then
				self.block_send.coros = {}
				self.block_send.callback_index = 1
				self.block_send.sync_send_idx = 1				
			end
			return "send timeout"
		elseif not self.luasocket then
			return "socket close"
		end	
	else
		return ret
	end
end

function stream.process_c_disconnect_event(self,errno)
	self.errno = errno
	while true do
		co = self.block_recv:Pop()
		if co then
			co = co[1]
			Sche.WakeUp(co)--Schedule(co) 
		else
			break
		end
	end
	for k,v in pairs(self.block_send.coros) do
		Sche.WakeUp(v)		
	end
	if self.pending_call then
		for k,v in pairs(self.pending_call) do
			self.minheap:Remove(v)
			if v.co then
				v.co.response = {err="remote connection lose"}
				Sche.WakeUp(v.co)				
			elseif v.callback then
				local ret = table.pack(pcall(v.callback,{err="remote connection lose"}))
				if not ret[1] then
					CLog.SysLog(CLog.LOG_ERROR,string.format("CallAsync error in callback:%s",ret[2]))
				end				
			end
		end
		self.pending_call = nil		
	end
	if self.on_disconnected then
		self.on_disconnected(self,errno)
	end
	if self.luasocket then
		self:Close()
	end			
end

function stream.process_c_packet_event(self,packet)
	self.packet:Push({packet})
	local co = self.recv_wakeup
	if not co then
		co = self.block_recv:Pop()
		self.recv_wakeup = co
	end
	if co then
	    	co = co[1]
		Sche.WakeUp(co)		
	end
end

function stream.Establish(self,decoder,recvbuf_size)
	self.__on_packet = stream.process_c_packet_event
	self.__on_disconnected = stream.process_c_disconnect_event
	self.block_recv = LinkQue.New()	
	recvbuf_size = recvbuf_size or 65535	
	CSocket.establish(self.luasocket,recvbuf_size,decoder)
	self.Send = stream.Send
	self.SendSync = stream.SendSync
	self.block_send = {callback_index = 1,sync_send_idx = 1,count = 0,coros={}}
	self.Recv = stream.Recv
	self.Establish = nil
	self.packet = LinkQue.New()
	return self	
end				

--function for datagram socket
local datagram = {}

function datagram.Listen(self,ip,port)
	if not self.luasocket then
		return "socket close"
	end
	return CSocket.listen(self.luasocket,ip,port)
end

function datagram.Send(self,packet,to)
	if not self.luasocket then
		return "socket close"
	end
	if not to then
		return "need remote addr"
	end
	return CSocket.datagram_send(self.luasocket,packet,to)
end

function datagram.process_c_packet_event(self,packet,from)
	self.packet:Push({packet,from})
	local co = self.recv_wakeup
	if not co then
		co = self.block_recv:Pop()
		self.recv_wakeup = co
	end
	if co then
	    	co = co[1]
		Sche.WakeUp(co)		
	end
end

function datagram.Recv(self,timeout)
	--[[
	尝试从套接口中接收数据,如果成功返回数据,如果失败返回nil,错误描述
	timeout参数如果为nil,则当socket没有数据可被接收时Recv调用将一直阻塞
	直到有数据可返回或出现错误.否则在有数据可返回或出现错误之前Recv最少阻塞
	timeout毫秒
	]]--
	if not self.luasocket then
		return nil,"socket close"
	end 				
	while true do	
		local packet = self.packet:Pop()
		if packet then
			return packet[1],packet[2],nil
		end		
		local co = Sche.Running()
		co = {co}	
		self.block_recv:Push(co)		
		local ret = Sche.Block(timeout)
		self.recv_wakeup = nil
		if ret == "timeout" then
			self.block_recv:Remove(co)
			return nil,nil,"recv timeout"
		elseif not self.luasocket then
			return nil,nil, (self.errno == nil or self.errno == 0) and "socket close" or self.errno
		end		
	end	
end


function socket:new(domain,type,recvbuf_size,decoder)
	local o = {}
	self.__index = self      
	setmetatable(o,self)
	recvbuf_size = recvbuf_size or 1024
	o.luasocket = CSocket.new1(o,domain,type,recvbuf_size,decoder)
	if not o.luasocket then
	return nil
	end
	o.errno = 0
	if type == CSocket.SOCK_STREAM then
		o.Listen = stream.Listen
		o.Connect = stream.Connect
	else
		o.Listen = datagram.Listen
		o.Send = datagram.Send
		o.Recv = datagram.Recv
		o.packet = LinkQue.New()
		o.block_recv = LinkQue.New()
		o.__on_packet = datagram.process_c_packet_event
	end
	return o   
end

function socket:new2(sock)
	local o = {}
	self.__index = self          
	setmetatable(o, self)
	o.luasocket = CSocket.new2(o,sock)
	o.errno = 0 
	return o
end

--[[
关闭socket对象，同时关闭底层的luasocket对象,这将导致连接断开。
务必保证对产生的每个socket对象调用Close。
]]--
function socket:Close()
	local luasocket = self.luasocket
	if luasocket then
		
		while self.block_onaccept do
			local co = self.block_onaccept:Pop()
			if co then
				Sche.WakeUp(co)
			else
				break
			end
		end

		if self.connect_co then
			Sche.WakeUp(self.connect_co)
		end

		self.luasocket = nil
		CSocket.close(luasocket)
	end	
end

function socket:tostring()
	return string.format("%s",self)
end

return {
	Stream = {
			New = function (domain) return socket:new(domain,CSocket.SOCK_STREAM) end,
			RDecoder = CSocket.rpkdecoder,
			RawDecoder =  CSocket.rawdecoder,			
		},
	Datagram = {
			New = function (domain,recvbuf_size,decoder) return socket:new(domain,CSocket.SOCK_DGRAM,recvbuf_size,decoder) end,
			RDecoder = CSocket.datagram_rpkdecoder,
			RawDecoder =  CSocket.datagram_rawdecoder,
		},
	WPacket = CPacket.NewWPacket,
	RPacket =  CPacket.NewRPacket,
	RawPacket = CPacket.NewRawPacket,
}

