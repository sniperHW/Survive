local Cjson = require "cjson"
local NetCmd = require "SurviveServer.netcmd.netcmd"
local Db = require "SurviveServer.common.db"


--achievement's achieve type
local ACHI_SINGLE_PVE = 1
local ACHI_EQUIP_UPGRADE = 2
local ACHI_EQUIP_ADDSTAR = 3
local ACHI_EQUIP_INSET = 4
local ACHI_ADDPOINT = 5
local ACHI_LEVEL_UP = 6
local ACHI_5PVE = 7
local ACHI_5PVP = 8
local ACHI_COMPOSITION = 9

local achievement ={}


--[[
data = {
	id,
	is_achieve = true or false,
	tb,
	is_everydata,
}
]]--

function achievement:new(owner,data)
  local o = {}   
  setmetatable(o, self)
  self.__index = self
  o.owner = owner
  o.data = {}  
  
  for k,v in pairs(data) do
	local type = tb[v.id].type
	local tmp = o.data[type]
	if not tmp then
		tmp = {all_achieve = true,achieves={}}
		o.data[type] = tmp
	end
	local achieve = {is_achieve=v.is_achieve,fn_check = tb[v.id].fn_check}
	tmp.achieves[v.id] = achieve	
  end
  
  for k,v in pairs(o.data) do
  	local tmp = v.achieves
  	for k1,v1 in pairs(tmp) do
  		if not v1.is_achieve then
  			v.all_achieve = false
  			break
  		end
  	end
  end
  return o
end

function achievement:OnBegPly(wpk)
	local wpos = wpk:Get_write_pos()
	wpk:Write_uint8(0)	
	local c = 0
	for k1,v1 in pairs(self.data) do
		local tmp = v1.achieves
		for k2,v2 in pairs(tmp) do
			wpk:Write_uint16(k2)
			if v2.is_achieve then
				wpk:Write_uint8(1)
			else
				wpk:Write_uint8(0)
			end
			c = c + 1
		end
	end
	wpk:Rewrite_uint8(wpos,c)
end

function achievement:NotifyUpdate(id,is_achieve)
	local wpk = CPacket.NewWPacket(512)
	wpk:Write_uint16(0)
	wpk:Write_uint16(id)
	if is_achieve then
		wpk:Write_uint8(1)
	else
		wpk:Write_uint8(0)
	end	
	self.owner:Send2Client(wpk)
end

function achievement:DbStr()
	local tmp1 = {}
	for k1,v1 in pairs(self.data) do
		local tmp2 = v1.achieves
		for k2,v2 in pairs(tmp2) do
			table.insert(tmp,{id=k2,is_achieve = v2.is_achieve})
		end
	end
	return Cjson.encode(tmp1)
end

function achievement:DbSave()
	local cmd = "hmset chaid:" .. self.owner.chaid .. " achievement  " .. self:DbStr()
	Db.Command(cmd)
end

function achievement:OnEvent(evtype,param)
	local tmp = self.data[evtype]
	if not tmp or tmp.all_achieve then
		return
	end
	for k,v in pairs(tmp.achieves) do
		if not v.is_achieve and v.fn_check then
			if v.fn_check(self.owner,param) then
				--modify all_achieve
				tmp.all_achieve = true
			  	for k1,v1 in pairs(tmp.achieves) do
			  		if not v1.is_achieve then
			  			tmp.all_achieve = false
			  			break
			  		end
			  	end				
				--notify client
				self:NotifyUpdate(k,true)
				--dbsave
				self:DbSave()
				break
			end
		end
	end
end

function achievement:ResetEveryDayAchievement()

end

return {
	New = function (owner,data) return achievement:new(owner,data) end,
	ACHI_SINGLE_PVE = ACHI_SINGLE_PVE,
	ACHI_EQUIP_UPGRADE = ACHI_EQUIP_UPGRADE,
	ACHI_EQUIP_ADDSTAR = ACHI_EQUIP_ADDSTAR,
	ACHI_EQUIP_INSET = ACHI_EQUIP_INSET,
	ACHI_ADDPOINT = ACHI_ADDPOINT,
	ACHI_LEVEL_UP = ACHI_LEVEL_UP,
	ACHI_5PVE = ACHI_5PVE,
	ACHI_5PVP = ACHI_5PVP,
	ACHI_COMPOSITION = ACHI_COMPOSITION,	
}

