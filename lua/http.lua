local Socket = require "lua.socket"
local Sche = require "lua.sche"
local Cjson = require "cjson"

local chttp = CHttp
CHttp = nil

local http_response = {}

function http_response:new()
  local o = {}
  self.__index = self      
  setmetatable(o,self)
  return o
end

function http_response:Send(connection)
	local s  = string.format("HTTP/1.1 %d %s\r\nConnection: Keep-Alive\r\n",self.status,self.phase)	
	table.insert(self.headers,"Date: Tue, 26 Aug 2014 11:40:38 GMT")	
	for k,v in pairs(self.headers) do
		s = s .. string.format("%s\r\n",v)
	end	
	if self.body then
		s = s ..  "Transfer-Encoding: chunked\r\n\r\nc\r\n"
		s = s .. string.format("%s\r\n0\r\n",self.body)
	end
	s = s .. "\r\n"
	connection:Send(CPacket.NewRawPacket(s))	
end

function http_response:WriteHead(status,phase,contents)
	self.status = status
	self.phase = phase
	self.headers = self.headers or {}
	if contents then
		for k,v in pairs(contents) do
			table.insert(self.headers,v)
		end
	end
end

function http_response:End(body)
	self.body = body
end

local http_server = {}

function http_server:new()
  local o = {}
  self.__index = self      
  setmetatable(o,self)
  return o
end


local function process_server(connection,on_request)
	local request
	while true do
		local httpevent,err = connection:Recv()
		if err then	
			connection:Close()
			return
		else
			local ev_type = httpevent:Event()
			if ev_type == "ON_MESSAGE_BEGIN" then
				request = {}
				request.header = {}
				request.method = httpevent:Method()
			elseif ev_type == "ON_URL" then
				request.url = httpevent:Content()
			elseif ev_type == "ON_HEADER_FIELD" then
				local httpevent1,err1 = connection:Recv()
				if err1 then		
					connection:Close()
					return
				end
				if httpevent1:Event() ~= "ON_HEADER_VALUE" then
					connection:Close()
					return					
				end
				request.header[httpevent:Content()] = httpevent1:Content()
			elseif ev_type == "ON_BODY" then
				request.body = httpevent:Content()
			elseif ev_type == "ON_MESSAGE_COMPLETE" then
				local response = http_response:new()
				on_request(request,response)
				response:Send(connection)
				request = nil				
			end		
		end
	end

end

function http_server:CreateServer(on_request)
	self.on_request = on_request
	return self
end

function http_server:Listen(ip,port)
	self.socket = Socket.Stream.New(CSocket.AF_INET)
	local err = self.socket:Listen(ip,port)
	if err then
		return err
	else
		local s = self
		Sche.Spawn(function () 	
			while true do
				local connection = s.socket:Accept()
				connection:Establish(chttp.http_decoder(chttp.HTTP_REQUEST,512),65535)
				Sche.Spawn(process_server,connection,s.on_request)
			end
		end)
		return nil
	end
end

local function CreateServer(on_request)
	return http_server:new():CreateServer(on_request)
end

return {
	CreateServer = CreateServer
}
