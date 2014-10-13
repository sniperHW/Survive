local logs = {}

local function New(name)
	if logs[name] then
		return false
	else
		logs[name] = CLog.New(name)
		return true
	end
end

local function Log(name,level,msg)
	local l = logs[name]
	if l then
		l:Log(level,msg)
	end
end


return {
	New = New,
	Log = Log,
	Init = Init,
	INFO = CLog.LOG_INFO,
	ERROR = CLog.LOG_ERROR,
}
