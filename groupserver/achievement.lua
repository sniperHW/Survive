local Cjson = require "cjson"
local NetCmd = require "netcmd.netcmd"
local Db = require "common.db"
local MsgHandler = require "netcmd.msghandler"
local Util = require "groupserver.util"
local GM = require "groupserver.gm"
require "common.TableNew_Achieve"

--achievement's achieve type
local achi_type = {
	ACHI_SINGLE_PVE = 1,
	ACHI_EQUIP_UPGRADE = 2,
	ACHI_EQUIP_ADDSTAR = 3,
	ACHI_EQUIP_INSET = 4,
	ACHI_ADDPOINT = 5,
	ACHI_LEVEL_UP = 6,
	ACHI_5PVE = 7,
	ACHI_5PVP = 8,
	ACHI_COMPOSITION = 9,
	ACHI_GUAJI = 10,
	ACHI_EQUIP_LEVELUP = 11,
	ACHI_KILL_BOSS = 12,
}

local achievement ={}


local achiv_check = {
	[1] = function (evtype,param)
		if evtype == achi_type.ACHI_SINGLE_PVE then
			return true
		end
	         end,
	[2] = function (evtype,param) 
		if evtype == achi_type.ACHI_KILL_BOSS then
			return true
		end
	          end,
	[3] = function (evtype,param)
		if evtype == achi_type.ACHI_GUAJI then
			return true
		end 
	          end,       	                  
	[4] = function (evtype,param)
		if evtype == achi_type.ACHI_EQUIP_UPGRADE then
			return true
		end 
	          end, 
	[5] = function (evtype,param)
		if evtype == achi_type.ACHI_EQUIP_ADDSTAR then
			return true
		end 
	          end,
	[6] = function (evtype,param)
		if evtype == achi_type.ACHI_ADDPOINT then
			return true
		end 
	          end,
	[7] = function (evtype,param)
		if evtype == achi_type.ACHI_EQUIP_UPGRADE and
		    param == 20 then
		    	return true
		end
	          end,
	[8] = function (evtype,param)
		if evtype == achi_type.ACHI_EQUIP_ADDSTAR  and
		    param == 20	then
			return true
		end 
	          end,
	[9] = function (evtype,param)
		if evtype == achi_type.ACHI_LEVEL_UP  and
		    param == 10	then
			return true
		end 
	          end,
	[10] = function (evtype,param)
		if evtype == achi_type.ACHI_EQUIP_INSET then
			return true
		end 
	          end,
	[11] = function (evtype,param) 
		if evtype == achi_type.ACHI_SINGLE_PVE  then
			return true
		end
	          end,	          
	[12] = function (evtype,param) 
		if evtype == achi_type.ACHI_5PVE then
			return true
		end
	          end,
	[13] = function (evtype,param) 
		if evtype == achi_type.ACHI_5PVP then
			return true
		end
	          end,
	[14] = function (evtype,param) 
		if evtype == achi_type.ACHI_COMPOSITION then
			return true
		end
	          end,	          	          	          
	[15] = function (evtype,param)
		if evtype == achi_type.ACHI_LEVEL_UP  and
		    param == 20	then
			return true
		end 
	          end,	          	          	          	          
}

for k,v in pairs(TableNew_Achieve) do
	local award = {}
	local tmp = Util.SplitString(v.Award,",")
	for k1,v1 in pairs(tmp) do
		local tmp2 = Util.SplitString(v1,":")
		tmp2[1] = tonumber(tmp2[1])
		tmp2[2] = tonumber(tmp2[2])
		table.insert(award,tmp2)
	end
	v.Award = award
end

function achievement:new(owner,data)
  local o = {}   
  setmetatable(o, self)
  self.__index = self
  o.owner = owner
  o.achiv_open = {}
  o.achiv_close = {}
  --data = data or {}
  if data then
	  for k,v in pairs(data) do
	  	if v.achived == 1 then
	  		table.insert(o.achiv_close,{id=k,awarded=v.awarded})
	  	else
	  		table.insert(o.achiv_open,{id=k,awarded=0})
	  	end
	  end
  else
  		for k,v in pairs(TableNew_Achieve) do
  			if k >= 16 and k <= 21 then
  				table.insert(o.achiv_close,{id=k,awarded=0})
  			else
  				table.insert(o.achiv_open,{id=k,awarded=0})
  			end
  		end
  end
  return o
end

function achievement:DbStr()
	local tmp = {}
	for k,v in pairs(self.achiv_open) do
		local tmp1 = {achived=0,awarded = 0}
		tmp[v.id] = tmp1
	end
	for k,v in pairs(self.achiv_close) do
		local tmp1 = {achived=1,awarded = v.awarded}
		tmp[v.id] = tmp1
	end	
	return Cjson.encode(tmp)
end

function achievement:DbSave()
	local cmd = "hmset chaid:" .. self.owner.chaid .. " achievement  " .. self:DbStr()
	Db.CommandAsync(cmd)
end

function achievement:Pack(wpk)
	wpk:Write_uint16(#self.achiv_open + #self.achiv_close)
	print(#self.achiv_open,#self.achiv_close)
	for k,v in pairs(self.achiv_open) do
		wpk:Write_uint16(v.id)
		wpk:Write_uint8(0)
		wpk:Write_uint8(0)
	end
	for k,v in pairs(self.achiv_close) do
		wpk:Write_uint16(v.id)
		wpk:Write_uint8(1)
		wpk:Write_uint8(v.awarded)
	end	
end

function achievement:OnEvent(evtype,param)
	for k,v in pairs(self.achiv_open) do
		local check_fn = achiv_check[v.id]
		if check_fn and check_fn(evtype,param) then
			table.insert(self.achiv_close,{id=v.id,awarded=v.awarded})
			table.remove(self.achiv_open,k)
			self:DbSave()
			break
		end
	end
end

function achievement:OnBeginPlay()
	--[[local flag
	for k,v in pairs(self.achiv_close) do
		if v.id >= 16 and v.id <= 21 and v.awarded then
			flag = true
			break
		end
	end]]--
	local ply = self.owner 
	if ply.attr:Get("online_award") ~= 0 then
		local wpk = CPacket.NewWPacket(64)
		wpk:Write_uint16(NetCmd.CMD_GC_ACHIEVE)	
		ply.achieve:Pack(wpk)
		ply:Send2Client(wpk)
	end

end

MsgHandler.RegHandler(NetCmd.CMD_CG_ACHIEVE,function (sock,rpk)
	local groupsession = rpk:Reverse_read_uint16()
	local ply = GetPlayerBySessionId(groupsession)
	if ply then
		local wpk = CPacket.NewWPacket(64)
		wpk:Write_uint16(NetCmd.CMD_GC_ACHIEVE)	
		ply.achieve:Pack(wpk)
		ply:Send2Client(wpk)
	end		
end)

MsgHandler.RegHandler(NetCmd.CMD_CG_ACHIEVE_AWARD,function (sock,rpk)
	local groupsession = rpk:Reverse_read_uint16()
	local ply = GetPlayerBySessionId(groupsession)
	if ply then
		local id = rpk:Read_uint16()
		for k,v in pairs(ply.achieve.achiv_close) do
			if v.id == id then
				if awarded then
					return
				end
				if id >=16 and id <= 21 then
					local duration = os.time() - ply.attr:Get("online_award")
					if duration < TableNew_Achieve[id].Time_Interval then
						return
					end
				end
				v.awarded = 1
				ply.achieve:DbSave()

				local tb = TableNew_Achieve[id]
				if tb then
					local award = tb.Award
					for k1,v1 in pairs(award) do
						local id = v1[1]
						local num = v1[2]
						Util.NewRes(ply,id,num)
					end
				end
				if id >=16 and id <= 21 then
					if id == 21 then
						ply.attr:Set("online_award",0)
					else
						ply.attr:Set("online_award",os.time())
					end
				end
				ply.bag:NotifyUpdate()
				ply.bag:Save()
				ply.attr:Update2Client()
				ply.attr:DbSave()				
				local wpk = CPacket.NewWPacket(64)
				wpk:Write_uint16(NetCmd.CMD_GC_ACHIEVE)	
				ply.achieve:Pack(wpk)
				ply:Send2Client(wpk)
				return			
			end
		end
	end		
end)

return {
	New = function (owner,data) return achievement:new(owner,data) end,
	AchiType = achi_type,	
}

