local LinkQue =  require "lua.linkque"


local sche = {
	ready_list = LinkQue.New(),
	timer = CMinHeap.New(),
	allcos = {},
	co_count = 0,
	runningco = nil,
}

local stat_ready = 1
local stat_sleep = 2
local stat_yield = 3
local stat_dead  = 4
local stat_block = 5
local stat_running = 6

local function add2Ready(co)
    local status = co.status
    if status == stat_ready or status == stat_dead or status == stat_running then
    	return
    end
    co.status = stat_ready
    sche.timer:Remove(co)    
    sche.ready_list:Push(co) 
end

local function _block(ms,stat)
	local co = sche.runningco
	if co.status ~= stat_running then
		return
	end
    	if ms and ms > 0 then
        		local timeout = C.GetSysTick() + ms
        		if co.heapele then
             			sche.timer:Change(co,timeout)       			
        		else
            			sche.timer:Insert(co,timeout)        			
        		end
    	end
	co.status = stat
	coroutine.yield(co.coroutine)
	if co.heapele then		
	        sche.timer:Remove(co)
	        return "timeout"
	end
end

local function Sleep(ms)
	local stat
	if ms and ms > 0 then
		stat = stat_sleep
	else
		stat = stat_yield
	end
	return _block(ms,stat)
end

local function Yield()
    Sleep(0)
end

local function Block(ms)
	return _block(ms,stat_block)
end

local function WakeUp(co)
    add2Ready(co)
end


local function SwitchTo(co)
	local pre_co = sche.runningco
	sche.runningco = co
	co.status = stat_running
	coroutine.resume(co.coroutine,co)
	sche.runningco = pre_co
	return co.status	
end

local function Schedule(co)
	local readylist = sche.ready_list
	if co then
		local status = co.status
		if status == stat_ready or status == stat_dead or status == stat_running then
			return sche.ready_list:Len()
		end
		sche.timer:Remove(co)
		if SwitchTo(co) == stat_yield then
			add2Ready(co)
		end
		if sche.stop then
			return -1
		end		
	else
		local yields = {}
		co = readylist:Pop()
		while co do
			if SwitchTo(co) == stat_yield then
				table.insert(yields,co)
			end
			if sche.stop then
				return -1
			end			
			co = readylist:Pop()
		end
		local timeouts = sche.timer:Pop(C.GetSysTick())
		if timeouts then
			for k,v in pairs(timeouts) do
				add2Ready(v)
			end
		end		
		for k,v in pairs(yields) do
			add2Ready(v)
		end
    end
    return sche.ready_list:Len()
end

local function Running()
    return sche.runningco
end

local function GetCoByIdentity(identity)
	return sche.allcos[identity]
end

local function start_fun(co)
	local stack,errmsg
    if not xpcall(co.start_func,
    			  function (err)
    			  	errmsg = err
    			 	stack  = debug.traceback()
    			  end,
    			  table.unpack(co.args)) then
        CLog.SysLog(CLog.LOG_ERROR,string.format("error on start_fun:%s\n%s",errmsg,stack))
    end
    sche.allcos[co.identity] = nil
    sche.co_count = sche.co_count - 1
    co.status = stat_dead
end

local g_counter = 0
local function gen_identity()
	g_counter = bit32.band(g_counter + 1,0x000FFFFF)
	return string.format("%d-%d",C.GetSysTick(),g_counter)
end

--产生一个coroutine在下次调用Schedule时执行
local function Spawn(func,...)
	local co = {index=0,timeout=0,identity=gen_identity(),start_func = func,args={...}}
	co.coroutine = coroutine.create(start_fun)
	sche.allcos[co.identity] = co
	sche.co_count = sche.co_count + 1
	add2Ready(co)
	return co
end

--产生一个coroutine立刻执行
local function SpawnAndRun(func,...)
	local co = {index=0,timeout=0,identity=gen_identity(),start_func = func,args={...}}
	co.coroutine = coroutine.create(start_fun)
	sche.allcos[co.identity] = co
	sche.co_count = sche.co_count + 1	
	Schedule(co)
	return co
end

local function Exit()
	sche.stop = true
	Yield() --yield to scheduler	
end

return {
		Spawn = Spawn,
		SpawnAndRun = SpawnAndRun,
		Yield = Yield,
		Sleep = Sleep,
		Block = Block,
		WakeUp = WakeUp,
		Running = Running,
		GetCoByIdentity = GetCoByIdentity,
		Schedule = Schedule,
		GetCoCount = function () return  sche.co_count  end,
		Exit = Exit,
}
