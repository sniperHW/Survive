local Sche = require "src.pseudoserver.sche"
local Map = require "src.pseudoserver.map"
local Que = require "src.pseudoserver.queue"

local msgque = Que.New()

local function Send2Pseudo(wpk)
	local rpk = CreateByWPacket(wpk)
	Map.ProcessPacket(rpk)
	--Map.Tick()
	--Sche.Schedule()	
	DestroyWPacket(wpk)
	DestroyRPacket(rpk)
end

local function TickPseudo()
	Map.Tick()
	Sche.Schedule()
	while msgque:Len() > 0 do
		local wpk = msgque:Pop()
		wpk = wpk[1]
		local rpk = CreateByWPacket(wpk)
		OnPseudoServerPacket(rpk)
		DestroyWPacket(wpk)
		DestroyRPacket(rpk)		
	end
end

local function DestroyMap()
	while msgque:Len() > 0 do
		local wpk = msgque:Pop()
		wpk = wpk[1]
		DestroyWPacket(wpk)		
	end
	Map.DestroyMap()
end

function Send2Client(wpk)
	msgque:Push({wpk})
end

local function BegPlay(round)
	UsePseudo = true
	--DestroyMap()
	Map.InitMap(round)
end

return {
	Send2Pseudo = Send2Pseudo,
	TickPseudo = TickPseudo,
	DestroyMap = DestroyMap,
	BegPlay = BegPlay,
}






