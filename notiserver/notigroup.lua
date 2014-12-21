
local notigroup = {}

function notigroup:new()
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.members = {}
	return o	
end

function notigroup:AddPly(ply)

end

function notigroup:RemPly(ply)

end

--send a notification to group members
function notigroup:Send(wpk)
	for k,v in pairs(self.members) do
		v:Send2Client(wpk)
	end
end


