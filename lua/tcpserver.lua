local Socket = require "lua.socket"
local Sche = require "lua.sche"

local function listen(ip,port,process)
	local server = Socket.Stream.New(CSocket.AF_INET)
	local err = server:Listen(ip,port)
	if err then
		server:Close()
		return err,nil
	end
	Sche.Spawn(function ()	
		while true do
			Sche.Spawn(process,server:Accept())
		end
	end)
	return nil,server
end

return {
	Listen = listen
}
