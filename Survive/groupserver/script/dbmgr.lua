local Que = require "queue"

local rediscon = {
	ip,
	port,
	conns,
}

local dbmgr={
	hash,	
}

local function on_redis_connect(self,conn,err)
	if conn then 
		self.conns:push(conn)
		local initfinish = true		
		for k,v in pairs(dbmgr.hash) do
			if v.conns:len() ~= 10 then
				initfinish = false
				break
			end
		end		
		if initfinish then
			--回调C函数初始化完成
			C.db_initfinish()
		end
	else
		C.redis_connect(self.ip,self.port,self)	
	end
end

local function on_redis_disconnect(self,conn)
	local que = self.conns
	self.conns = Que:Queue()
	local tmp = que:pop()
	while tmp do
		if tmp ~= conn then
			self.conns:push(tmp)
		end
		tmp = que:pop()
	end
	C.redis_connect(self.ip,self.port,self)		
end


local function init()
	dbmgr.hash = {}
	dbmgr.hash[1] = {ip="127.0.0.1",6379,conns=Que:Queue()}
	--dbmgr.hash[2] = {ip="127.0.0.1",6378,conns=Que:Queue()}
	--dbmgr.hash[3] = {ip="127.0.0.1",6377,conns=Que:Queue()}
	--dbmgr.hash[4] = {ip="127.0.0.1",6376,conns=Que:Queue()}	
	for k,v in pairs(dbmgr.hash) do
		for 1,10 do
			if not C.redis_connect(v.ip,v.port,{v=v,on_connect = on_redis_connect,
							on_disconnect = on_redis_disconnect}) then
				return false
			end
		end
	end	
	return true
end

local function dbcmd(hashkey,cmd,callback)
	local key = math.mod(hashkey,#dbmgr.hash)+1
	
	if not dbmgr.hash[key] then
		return "invaild hashkey"
	end
		
	local conn = dbmgr.hash[key].conns:pop()
	while conn do
		if C.redisCommand(conn,cmd,callback) then
			dbmgr.hash[key].conns:push(conn)
			return nil
		else
			conn = dbmgr.hash[key].conns:pop()
		end
	end
	
	return "no db connection"
end

return {
	Init = init,
	DBCmd = dbcmd,
}
