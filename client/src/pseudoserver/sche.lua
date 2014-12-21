local MinHeap = require "src.pseudoserver.minheap"
local Que =  require "src.pseudoserver.queue"
local Time = require "src.pseudoserver.time"


local sche = {
	ready_list = Que.New(),
	timer = MinHeap.New(),
	allcos = {},
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
    sche.ready_list:Push(co) 
end

local function Sleep(ms)
	local co = sche.runningco
	if co.status ~= stat_running then
		return
	end	
	if ms and ms > 0 then
		co.timeout = Time.SysTick() + ms
        		if co.index == 0 then
            			sche.timer:Insert(co)
        		else
            			sche.timer:Change(co)
        		end
        		co.status = stat_sleep		
	else
		co.status = stat_yield
	end
	coroutine.yield(co.coroutine)
end

local function Yield()
    Sleep(0)
end

local function Block(ms)
	local co = sche.runningco
	if co.status ~= stat_running then
		return
	end
    	if ms and ms > 0 then
		ms = ms * 1000
       		local nowtick = Time.SysTick()
        		co.timeout = nowtick + ms
        		if co.index == 0 then
            			sche.timer:Insert(co)
        		else
            			sche.timer:Change(co)
        		end
    	end
	co.status = stat_block
	coroutine.yield(co.coroutine)
	if co.index ~= 0 then
	        co.timeout = 0		
	        sche.timer:Change(co)
	        sche.timer:PopMin()
	end
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
		local now = Time.SysTick()
		local timer = sche.timer
		while timer:Min() ~=0 and timer:Min() <= now do
			co = timer:PopMin()
			if co.status == stat_block or co.status == stat_sleep then
				add2Ready(co)
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
	--print("---------start_fun--------------")
	--co.start_func()
    local ret,err = pcall(co.start_func,unpack(co.args))
    if not ret then
        print("error on start_fun:" .. err)
    end
    sche.allcos[co.identity] = nil
    co.status = stat_dead
end

local g_counter = 0
local function gen_identity()
	g_counter = g_counter + 1
	return "l" .. Time.SysTick() .. "" .. g_counter
end

--产生一个coroutine在下次调用Schedule时执行
local function Spawn(func,...)
	local co = {index=0,timeout=0,identity=gen_identity(),start_func = func,args={...}}
	co.coroutine = coroutine.create(start_fun)
	--if not sche.mainco then
	--	sche.mainco = co
	--end 
	sche.allcos[co.identity] = co
	add2Ready(co)
	return co
end

--产生一个coroutine立刻执行
local function SpawnAndRun(func,...)
	local co = {index=0,timeout=0,identity=gen_identity(),start_func = func,args={...}}
	co.coroutine = coroutine.create(start_fun)
	--if not sche.mainco then
	--	sche.mainco = co
	--end   
	sche.allcos[co.identity] = co
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
		Exit = Exit,
}
