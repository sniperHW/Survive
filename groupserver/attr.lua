local Cjson = require "cjson"
local Name2idx = require "Survive/common/name2idx"
local NetCmd = require "Survive/netcmd/netcmd"
local attr = {}

--需要从group带到game的属性
local attr2game ={
	level = 1,--角色等级
	exp = 2, --经验值
	power = 3,--力量
	endurance = 4,--耐力
	constitution = 5,--体质
	agile = 6,--敏捷
	lucky = 7,--幸运
	accurate = 8,--精准
	movement_speed = 9,-- 移动速度
	action_force = 13,--行动力

	attack = 21,  --攻击
	defencse = 22,--防御
	life = 23,    --当前生命
	maxlife = 24, --最大生命
	dodge = 25,--闪避
	crit = 26,--暴击
	hit = 27,--命中
	anger = 28,--怒气
	combat_power = 29,--战斗力	
}

function attr:new(o)
  local o = o or {}   
  setmetatable(o, self)
  self.__index = self
  return o
end

function attr:Init(baseinfo)
	self.attr = baseinfo	
	return self
end

function attr:Get(name)
	return self.attr[name]
end

function attr:OnBegPly(wpk)
	self:Pack(wpk,false)
end

function attr:Set(name,val)
	local idx = Name2idx.Idx(name) or 0
	if idx > 0 then
		self.attr[idx] = val
		self.flag = self.flag or {}
		self.flag[idx] = true
	end
end

function attr:Pack(wpk,modfy)
	local wpos = wpk:Get_write_pos()
	wpk:Write_uint8(0)
	local c = 0
	self.flag = self.flag or {}
	for k,v in pairs(self.attr) do	
		if (not modfy) or self.flag[k] then		
			wpk:Write_uint8(k)
			wpk:Write_uint32(self.attr[k])
			c = c + 1
		end
	end	
	wpk:Rewrite_uint8(wpos,c)			
end

--将属性的变更通知给客户端
function attr:Update2Client(ply)	
	if not self.flag then
		return
	end
	local wpk = CPacket.NewWPacket(128)
	wpk:Write_uint16(NetCmd.CMD_GC_ATTRUPDATE)
	self.Pack(wpk,true)
	self.flag = nil
	ply:Send2Client(wpk)
end

function attr:DbStr()
	local t = {}
	for k,v in pairs(self.attr) do
		if k > 0 and k <= 13 then
			t[k] = v
		end
	end	
	return Cjson.encode(t)
end

--将game需要用到的属性对提取出来
function attr:Pack2Game()
	local t = {}
	for k,v in pairs(self.attr) do
		if attr2game[Name2idx.Name(k)] then
			t[k] = v
		end
	end
	return t
end

return {
	New = function () return attr:new() end,
}
