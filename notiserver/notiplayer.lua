
local notiplayer = {}
local players = {}

function notiplayer:new()
	local o = {}
	setmetatable(o, self)
	self.__index = self
	return o	
end

function notiplayer:Init(chaid,gatename)

end

--send a notification to player
function notiplayer:Send2Client(wpk)

end

--send a notification to all players
local function Send2All(wpk)
	for k,v in pairs(players) do
		v:Send2Client(wpk)
	end
end

local function GetPlayerByChaid(chaid)
	return players[chaid]
end

return {
	GetPlayerByChaid = GetPlayerByChaid,
}