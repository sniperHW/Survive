local rediscon = {
	ip,
	port,
	conn,
}

local dbmgr={
	hash,	
}

local function on_redis_connect(self,conn,err)
	if conn then 
		self.v.conn = conn
		local initfinish = true		
		for k,v in pairs(dbmgr.hash) do
			if not v.conn then
				initfinish = false
				break
			end
		end		
		print("on_redis_connect")
		if initfinish then
			--回调C函数初始化完成
			C.db_initfinish()
		end
	else
		C.redis_connect(self.ip,self.port,self)	
	end
end

local function on_redis_disconnect(self,conn)
	self.conn = nil
	C.redis_connect(self.ip,self.port,self)		
end


local function init()
	dbmgr.hash = {}
	dbmgr.hash[1] = {ip="127.0.0.1",port=6379}
	--dbmgr.hash[2] = {ip="127.0.0.1",port=6378}
	--dbmgr.hash[3] = {ip="127.0.0.1",port=6377}
	--dbmgr.hash[4] = {ip="127.0.0.1",port=6376}	
	for k,v in pairs(dbmgr.hash) do
		if not C.redis_connect(v.ip,v.port,{v=v,on_connect = on_redis_connect,
						on_disconnect = on_redis_disconnect}) then
			print("db init failed")
			return false
		end
	end	
	return true
end

local function dbcmd(hashkey,cmd,callback)
	--local key = math.mod(hashkey,#dbmgr.hash)+1
	
	--if not dbmgr.hash[key] then
	--	return "invaild hashkey"
	--end
	local key = 1	
	local conn = dbmgr.hash[key].conn
	if conn then
		if C.redisCommand(conn,cmd,callback) then
			return nil
		else
			redis_close(conn)
		end
	end
	
	return "no db connection"
end

return {
	Init = init,
	DBCmd = dbcmd,
}
