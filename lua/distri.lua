local Sche = require "lua.sche"
local Http = require "lua.http"
local LinkQue  = require "lua.linkque"
local c_callback_que = LinkQue.New()--用于接收c传递进来的callback请求	
local block_on_c_callback_que

local normal_callback = 1
local obj_callback = 2


function push_c_callback(fun,...)
	local cbobj = {normal_callback,fun,table.pack(...)}
	c_callback_que:Push(cbobj)
	if block_on_c_callback_que then
		Sche.WakeUp(block_on_c_callback_que)
		block_on_c_callback_que = nil
	end
end

function push_c_obj_callback(fun,obj,...)
	local cbobj = {obj_callback,fun,obj,table.pack(...)}
	c_callback_que:Push(cbobj)
	if block_on_c_callback_que then
		Sche.WakeUp(block_on_c_callback_que)
		block_on_c_callback_que = nil
	end	
end


--用于处理c中传递的callback
local function process_c_callback()
	local cbobj
	while true do
		cbobj = c_callback_que:Pop()
		if cbobj then
			local f
			local obj
			local ret,err
			if cbobj[1] == normal_callback then
				f = _G[cbobj[2]]
				ret,err = f(table.unpack(cbobj[3]))
				if not ret then
					--将err写到日志
				end 
			else
				obj = cbobj[3]
				f = obj[cbobj[2]]
				ret,err = f(obj,table.unpack(cbobj[4]))
				if not ret then
					--将err写到日志
				end 								
			end	
		else
			block_on_c_callback_que = Sche.Running()
			Sche.Block()
		end
	end
end

function Exit()
	--StopEngine()
	Sche.Exit()
end 

function distri_lua_start_run(mainfile)
	local main,err= loadfile(mainfile)
	if err then 
		CLog.SysLog(CLog.LOG_ERROR,string.format("distri_lua_start_run load %s %s",mainfile,err))
	 end
	Sche.Spawn(function () main() end)
	Sche.Spawn(process_c_callback)--启动一个协程去处理回调
	local ms = 1
	while C.RunOnce(ms,50) do
		local ret = Sche.Schedule()
		if ret < 0 then
			return
		elseif ret > 0 then
			ms = 0
		else
			ms = 1
		end
	end
end





