local Sche = require "lua.sche"
local Redis = require "lua.redis"
local Cjson = require "cjson"
local Socket = require "lua.socket"

local err
local toredis
local serverip = "192.168.0.87"

local deployment={
	--[[{groupname="central",service={
				{type="ssdb-server",logicname="ssdb-server",conf="ssdb.conf",ip="192.168.0.87"},
		}
	},]]--
	{groupname="group1",service={
			{type="groupserver",logicname="groupserver",ip="192.168.0.87",port="8010"},
			{type="gameserver",logicname="gameserver",ip="192.168.0.87",port="8011"},
			{type="gateserver",logicname="gateserver",ip="192.168.0.87",port="8012"},
		}
	},	
	{groupname="group2",service={
			{type="groupserver",logicname="groupserver",ip="192.168.0.88",port="8010"},
			{type="gameserver",logicname="gameserver",ip="192.168.0.88",port="8011"},
			{type="gateserver",logicname="gateserver",ip="192.168.0.88",port="8012"},
		}
	},
	{groupname="测试3区",service={
			{type="groupserver",logicname="groupserver",ip="192.168.0.89",port="8010"},
			{type="gameserver",logicname="gameserver",ip="192.168.0.89",port="8011"},
			{type="gateserver",logicname="gateserver",ip="192.168.0.89",port="8012"},
		}
	},	
}

local process
--{groupname,type,logicname}
local localservice

local function split(s,separator)
	local ret = {}
	local initidx = 1
	local spidx
	while true do
		spidx = string.find(s,separator,initidx)
		if not spidx then
			break
		end
		table.insert(ret,string. sub(s,initidx,spidx-1))
		initidx = spidx + 1
	end
	if initidx ~= string.len(s) then
		table.insert(ret,string. sub(s,initidx))
	end
	return ret
end

--server for php request
local function RunDaemonServer()
	local function FindByLogicname(logicname,group)
		for k,v in pairs(localservice) do
			if v[3] == logicname and v[1] == group then
				return  v
			end
		end
		return nil
	end

	local function FindProcess(logicname,group)
		local got = nil
		for i = 1,#process do
			if string.find(process[i].cmd,logicname,1) and 
			   string.find(process[i].cmd,group,1) then
				got = process[i]
				break
			end
		end
		return got
	end

	local function StartProcess(serv)
		if serv[2] == "ssdb-server" then
			C.ForkExec("~/ssdb-master/ssdb-server","~/ssdb-server/ssdb.conf",serv[1])
		else
			local luafile = string.format("Survive/%s/%s.lua",serv[2],serv[2])
			C.ForkExec("./distrilua",luafile,serv[1],serv[3])
		end		
	end
	
	local function processMsg(sock,msg)
		print("processMsg")
		local opreq = Cjson.decode(msg);
		local retpk = nil
		while true do
			if opreq.ip  and opreq.ip ~= serverip then
				break
			end
			if opreq.op == "Start" then
				if opreq.logicname  then
					--start one service
					if not opreq.group then
						break
					end
					local got = FindProcess(opreq.logicname,opreq.group)
					if got then
						break
					end
					local r = FindByLogicname(opreq.logicname,opreq.group)
					if r then
						StartProcess(r)
						retpk = Socket.RawPacket("operation success")
					end
				else
					if opreq.group then
						for k,v in pairs(localservice) do
							if opreq.group == v[1] and
							   not FindProcess(v[3],v[1]) then
							   	StartProcess(v)
							end
						end
					elseif opreq.ip then
						for k,v in pairs(localservice) do
							if not FindProcess(v[3],v[1]) then
							   	StartProcess(v)
							end
						end
					else
						break
					end
					retpk = Socket.RawPacket("operation success")
				end
				break
			elseif opreq.op == "Stop" or opreq.op == "Kill" then
				if opreq.logicname then
					--stop or kill one service
					if not opreq.group then
						break
					end	
					local got = FindProcess(opreq.logicname,opreq.group)
					if not got then
						break
					end
					if opreq.op == "Stop" then
						--print(got.pid)
						C.StopProcess(got.pid)
					else
						C.KillProcess(got.pid)	
					end
				else
					if opreq.group then
						for k,v in pairs(localservice) do
							if opreq.group == v[1] then
								local p = FindProcess(v[3],v[1])
								if p then
									if opreq.op == "Stop" then
										C.StopProcess(p.pid)
									else
										C.KillProcess(p.pid)	
									end
								end
							end
						end
					elseif opreq.ip then
						for k,v in pairs(localservice) do
							local p = FindProcess(v[3],v[1])
							if p then
								if opreq.op == "Stop" then
									C.StopProcess(p.pid)
								else
									C.KillProcess(p.pid)	
								end
							end							
						end
					else
						break
					end
				end
				retpk = Socket.RawPacket("operation success")
				break
			else
				break
			end
		end
		if not retpk then
			retpk = Socket.RawPacket("invaild operation")
		end
		sock:Send(retpk)
		sock:Close()
	end

	local server = Socket.Stream.New(CSocket.AF_INET)
	if not server:Listen("127.0.0.1",8800) then
			print("DaemonServer listen on 127.0.0.1 8800")
			while true do
				local client = server:Accept()
				print("new client")
				client:Establish()
				Sche.Spawn(function ()
					local unpackbuff = ''
					while true do
						local packet,err = client:Recv()
						if err then
							print("client disconnected err:" .. err)			
							client:Close()
							return
						end
						processMsg(client,packet:Read_rawbin())
					end
				end)
			end		
	else
		print("create DaemonServer on 127.0.0.1 8800 error")
	end
end


err,toredis = Redis.Connect("127.0.0.1",6379,function () print("disconnected") end)
if not err then

	localservice = {}
	for k1,v1 in pairs(deployment) do
		for k2,v2 in pairs(v1.service) do
			if v2.ip == serverip then
				table.insert(localservice,{v1.groupname,v2.type,v2.logicname})
			end
		end
	end

	for k,v in pairs(localservice) do
		print(v[1],v[2],v[3])
	end

	Sche.Spawn(RunDaemonServer)
	toredis:CommandAsync("set deployment " .. Cjson.encode(deployment))
	C.AddTopFilter("distrilua")
	C.AddTopFilter("ssdb-server")
	while true do
		local machine_status = C.Top()
		local tb = split(machine_status,"\n")
		local machine = {}
		local i = 1
		while i <= #tb do
			if tb[i] ~= "process_info" then
				table.insert(machine,tb[i])
			else
				i = i + 1	
				break
			end
			i = i + 1
		end
		process = {}
		while i <= #tb do
			if tb[i] ~= "" then
				local tmp = {}
				local cols = split(tb[i],",")
				for k,v in pairs(cols) do
					local keyvals = split(v,":")
					tmp[keyvals[1]] = keyvals[2];
				end
				table.insert(process,tmp)
			end
			i = i + 1	
		end
		local str = string.format("hmset MachineStatus 192.168.0.87 %s",CBase64.encode(Cjson.encode({machine,process})))
		toredis:CommandAsync(str)
		collectgarbage("collect")			
		Sche.Sleep(1000)
	end
else
	Exit()
end
