local Sche = require "lua.sche"
local LinkQue  = require "lua.linkque"

local redisconn = {}

function redisconn:new(coObj,ip,port)
  local o = {}
  self.__index = self      
  setmetatable(o,self)
  o.conn = coObj.conn
  o.ip = ip
  o.port = port
  coObj.redisconn = o
  return o 
end


function redisconn:CommandSync(cmd)	
	if self.isclose then
		return "redis connection is close",nil
	end
	local cbObj = {
		co = Sche.Running(),
		__callback = function (self,error,result)
			self.err = error
			self.result = result
			Sche.WakeUp(self.co)			
		end
	}	
	if CRedis.redisCommandSync(self.conn,cmd,cbObj) then
		Sche.Block()
		return cbObj.err,cbObj.result		
	else
		return "redis command error",nil
	end
end

function redisconn:CommandAsync(cmd,callback)
	if self.isclose then
		return "redis connection is close"
	end
	local cbObj
	if callback then
		cbObj = { __callback = callback }
	end	
	if CRedis.redisCommandAsync(self.conn,cmd,cbObj) then
		return nil		
	else
		return "redis command error"
	end
end

function redisconn:Close()	
    self.activeclose = true
    CRedis.close(self.conn)
end

local function connect(ip,port,on_disconnected)
	local cbObj = {co = Sche.Running(),
				   __cb_connect = function (self,conn,err)
						self.conn = conn
						self.err = err
						Sche.WakeUp(self.co)
				   end,
				   __on_disconnected = function (self)
						self.redisconn.isclose = true
						if on_disconnected then
							on_disconnected(self.redisconn)
						end	
				   end}
	local error = CRedis.redis_connect(ip,port,cbObj)
	if error then 
		return error,nil
	end
	Sche.Block()
	if cbObj.err then 
		return cbObj.err,nil
	else
		return nil,redisconn:new(cbObj,ip,port)
	end
end

return {
	Connect = connect
}
