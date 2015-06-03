local Cjson = require "cjson"
local LinkQue = require "lua.linkque"
local Gate = require "groupserver.gate"
local Game = require "groupserver.game"
local MsgHandler = require "netcmd.msghandler"
local Name2idx = require "common.name2idx"
local Db = require "common.db"
local Attr = require "groupserver.attr"
local Bag = require "groupserver.bag"
local Skill = require "groupserver.skill"
local NetCmd = require "netcmd.netcmd"
local Sche = require "lua.sche"
local Map = require "groupserver.map"
local RPC = require "lua.rpc"
local GM = require "groupserver.gm"
local Timer = require "lua.timer"
local IdMgr = require "common.idmgr"
local Util = require "groupserver.util"
local Item = require "groupserver.item"
local Sign = require "groupserver.everydaysignin"
local Task = require "groupserver.everydaytask"
local Achi = require "groupserver.achievement"
local Lock = require "lua.lock"
local Mail = require "groupserver.mail"
require "groupserver.homeisland"
require "groupserver.equip"
require "common.TableRole"
require "common.TableEquipment"
require "common.TableExperience"
require "common.TableItem"
require "common.TableIntensify"
require "common.TableRising_Star"
require "common.TableStone"
require "common.TableNewbie_Reward"
require "common.TableArena_Reward"
require "common.TableTower_Reward"



LogOutTimer  = Timer.New("runImmediate")

for k,v in pairs(TableArena_Reward) do
	for k1,v1 in pairs(v) do
		local award = {}
		local _award = Util.SplitString(v1,",")
		for k2,v2 in pairs(_award) do
			local tmp2 = Util.SplitString(v2,":")
			tmp2[1] = tonumber(tmp2[1])
			tmp2[2] = tonumber(tmp2[2])
			table.insert(award,tmp2)
		end
		v[k1] = award
	end
end

for k,v in pairs(TableTower_Reward) do
	for k1,v1 in pairs(v) do
		local award = {}
		local _award = Util.SplitString(v1,",")
		for k2,v2 in pairs(_award) do
			local tmp2 = Util.SplitString(v2,":")
			tmp2[1] = tonumber(tmp2[1])
			tmp2[2] = tonumber(tmp2[2])
			table.insert(award,tmp2)
		end
		v[k1] = award
	end
end

--for k,v in pairs(TableArena_Reward) do
--	print(v["2V2_Win_Reward"][1][1],v["2V2_Win_Reward"][1][2])
--end

local freeidx = IdMgr.New(4096)

local function GetIdx()
	return freeidx:Get()
end

local function ReleaseIdx(idx)
	freeidx:Release(idx)
end

local player = {}
local actname2player ={}
local chaid2player = {}
local id2player = {}
local nickname2player = {}

function player:new(actname)
	local id = GetIdx()
	if not id then
		return nil
	end
	local o = {}   
	setmetatable(o, self)
	self.__index = self
	o.groupsession = id
	return o
end

local function NewPlayer(actname)
	local ply = player:new()
	if ply then
		ply.actname = actname
		id2player[ply.groupsession] = ply
		actname2player[actname] = ply		
	end
	return ply	
end

function ReleasePlayer(ply)
	if ply.groupsession then
		if ply.actname then
			print(string.format("Release %s",ply.actname))
		end
		id2player[ply.groupsession] = nil
		actname2player[ply.actname] = nil
		if ply.chaid then
			chaid2player[ply.chaid] = nil
		end
		if ply.nickname then
			nickname2player[ply.nickname] = nil
		end
		ReleaseIdx(ply.groupsession)
		ply.groupsession = nil
	end
end

function GetPlayerBySessionId(id)
	return id2player[id]
end

function GetPlayerByActname(actname)
	return actname2player[actname]
end

function GetPlyByNickname(nickname)
	return nickname2player[nickname]
end

function GetPlyByChaid(chaid)
	return chaid2player[chaid]
end

function player:Send2Game(wpk)
	local gamesession = self.gamesession
	if gamesession then
		wpk:Write_uint32(gamesession.sessionid)
		gamesession.game.sock:Send(wpk)
	end
end

function player:Send2Client(wpk)
	local gatesession = self.gatesession
	if gatesession then
		--print(debug.traceback())
		local wpk1 = CPacket.NewWPacket(256)
		local rpk = CPacket.NewRPacket(wpk)
		print(rpk)
		local cmd = rpk:Read_uint16()
		--print(cmd)
		wpk1:Write_uint16(cmd)
		wpk1:Write_wpk(wpk)
		wpk1:Write_uint16(1)
		wpk1:Write_uint32(gatesession.sessionid)
		gatesession.gate.sock:Send(wpk1)
	end	
end


function player:NotifyBeginPlay()
	self.status = playing
	local wpk = CPacket.NewWPacket(256)
	wpk:Write_uint16(NetCmd.CMD_GC_BEGINPLY)
	wpk:Write_uint32(self.chaid)
	wpk:Write_uint16(self.avatarid)
	wpk:Write_string(self.nickname)
	self.attr:OnBegPly(wpk)
	self.bag:OnBegPly(wpk)
	self.skills:OnBegPly(wpk)
	self.sign:OnBegPly(wpk)
	wpk:Write_uint32(os.time())
	self:Send2Client(wpk)
	self.achieve:OnBeginPlay()		
end

function player:NotifyCreate()
	self.status = createcha
	return {true,self.groupsession,"create"}	
end

function player:NotifyCreateError(msg)
	local wpk = CPacket.NewWPacket(64)
	wpk:Write_uint16(NetCmd.CMD_GC_CREATE_ERROR) 
	wpk:Write_string(msg)
	self:Send2Client(wpk)
end

function player:AddExp(exp)
	if not exp then return end
	local oldexp = self.attr:Get("exp")
	exp = oldexp + exp
	local level = self.attr:Get("level")
	while true do
		local tb = TableExperience[level]
		if not tb then
			return
		end
		local nextexp = tb["Experience"]
		if nextexp == 0 then
			break
		end
		if exp >= nextexp then
			level = level + 1
			exp = exp - nextexp
			self:OnLevelUp(level)
		else
			break
		end
	end
	self.attr:Set("exp",exp)
	--self.attr:Update2Client()
	--self.attr:DbSave()
end


function player:OnLevelUp(level,notifyclient)
	local cur_level = self.attr:Get("level")
	local cur_potential_point = self.attr:Get("potential_point") or 0
	local power,endurance,constitution,agile,lucky,accurate = 0,0,0,0,0,0
	local power_base,endurance_base,constitution_base,agile_base,lucky_base,accurate_base = 0,0,0,0,0,0
	--local cirt = 0
	if cur_level ~= 0 then
		power = TableRole[cur_level]["Power"] or 0
		endurance = TableRole[cur_level]["endurance"] or 0
		constitution = TableRole[cur_level]["constitution"] or 0
		agile = TableRole[cur_level]["agile"] or 0
		lucky = TableRole[cur_level]["Lucky"] or 0
		accurate = TableRole[cur_level]["accurate"] or 0

		power_base = self.attr:Get("power") - power
		endurance_base = self.attr:Get("endurance") - endurance
		constitution_base = self.attr:Get("constitution") - constitution
		agile_base = self.attr:Get("agile") - agile
		lucky_base = self.attr:Get("lucky") - lucky
		accurate_base = self.attr:Get("accurate") - accurate
	end

	local potential_point = TableRole[level]["Potential_Point"] or 0
	potential_point = potential_point + cur_potential_point

	power = TableRole[level]["Power"] or 0
	endurance = TableRole[level]["endurance"] or 0
	constitution = TableRole[level]["constitution"] or 0
	agile = TableRole[level]["agile"] or 0
	lucky = TableRole[level]["Lucky"] or 0
	accurate = TableRole[level]["accurate"] or 0	

	self.attr:Set("level",level)
	self.attr:Set("power",power + power_base)
	self.attr:Set("endurance",endurance + endurance_base)
	self.attr:Set("constitution",constitution + constitution_base)
	self.attr:Set("agile",agile + agile_base)
	self.attr:Set("lucky",lucky + lucky_base)
	self.attr:Set("accurate",accurate + accurate_base)
	self.attr:Set("potential_point",potential_point)
	self.achieve:OnEvent(Achi.AchiType.ACHI_LEVEL_UP,level)
	--self.attr:Set("crit",crit)
	self:CalAttr(notifyclient)
end

function getStone(equip,stonepos)
	if stonepos == 1 then
		return equip:GetAttrHigh(1)
	elseif stonepos == 2 then
		return equip:GetAttrLow(1)
	elseif stonepos == 3 then
		return equip:GetAttrHigh(2)
	elseif stonepos == 4 then
		return equip:GetAttrLow(2)
	end
	return nil
end

local function fetchStones(stones,equip)
	for i = 1,4 do
		local stone = getStone(equip,i)
		if stone > 0 then
			table.insert(stones,stone)
		end
	end
end

function player:CalAttr(notifyclient,withoutweapon)
	local attack_plus,attack_base = 0,0  --攻击
	local defencse_plus,defencse_base = 0,0 --防御
	local maxlife_plus,maxlife_base = 0,0 --最大生命
	local dodge_plus,dodge_base = 0,0 --闪避
	local crit_plus,crit_base = 0,0 --暴击
	local hit_plus,hit_base = 0,0--命中

	dodge_base = math.floor(self.attr:Get("agile") * 0.02)
	crit_base = math.floor(self.attr:Get("lucky") * 0.01)
	hit_base = math.floor(self.attr:Get("accurate") * 0.1)
	local stones = {}
	if not withoutweapon then
		local weapon = self.bag:GetBagItem(Bag.weapon)	
		if weapon then
			local tb = TableEquipment[weapon.id]
			if tb then
				attack_plus = tb["Attack"] or 0
				local strengthen_lev = weapon:GetAttrHigh(3)
				tb = TableIntensify[strengthen_lev]
				if tb then
					attack_plus = attack_plus + tb["Attack"]
				end
				local star = weapon:GetAttrLow(3)
				tb = TableRising_Star[star]
				if tb then
					attack_plus = attack_plus + tb["Attack"]
				end
				fetchStones(stones,weapon)
			end
		end
	end

	local belt = self.bag:GetBagItem(Bag.belt)
	if belt then
		local tb = TableEquipment[belt.id]
		if tb then
			maxlife_plus = tb["Life"] or 0
			local strengthen_lev = belt:GetAttrHigh(3) 
			tb = TableIntensify[strengthen_lev]
			if tb then
				maxlife_plus = maxlife_plus + tb["Life"]
			end
			local star = belt:GetAttrLow(3)
			tb = TableRising_Star[star]
			if tb then
				maxlife_plus = maxlife_plus + tb["Life"]
			end
			fetchStones(stones,belt)
		end				
	end

	local cloth = self.bag:GetBagItem(Bag.cloth)
	if cloth then
		local tb = TableEquipment[cloth.id]
		if tb then
			defencse_plus = tb["Defense"] or 0
			local strengthen_lev = cloth:GetAttrHigh(3)
			tb = TableIntensify[strengthen_lev]
			if tb then
				defencse_plus = defencse_plus + tb["Defense"]
			end
			local star = cloth:GetAttrLow(3)
			tb = TableRising_Star[star]
			if tb then
				defencse_plus = defencse_plus + tb["Defense"]
			end
			fetchStones(stones,cloth)
		end							
	end
	--print("atk_plus",attack_plus)
	--local bak_atk_plus = attack_plus
	--local bak_defencse_plus = defencse_plus
	--local bak_maxlife_plus = maxlife_plus
	for k,v in pairs(stones) do
		tb = TableStone[v]
		if tb then
			local atk_plus_rate = tb["Attack"]
			if atk_plus_rate > 0 then
				attack_plus = math.floor((attack_plus*100+atk_plus_rate) / 100)
			end
			local defencse_plus_rate = tb["Defense"]
			if defencse_plus_rate > 0 then
				defencse_plus = math.floor((defencse_plus*100+defencse_plus_rate) / 100)			
			end
			local maxlife_plus_rate = tb["Life"]
			if maxlife_plus_rate > 0 then
				maxlife_plus = math.floor((maxlife_plus*100+maxlife_plus_rate) / 100)			
			end
			local dodge_plus_rate = tb["Dodge"]
			if dodge_plus_rate > 0 then
				dodge_plus = dodge_plus + math.floor((dodge_base*100+dodge_plus_rate) / 100)
			end
			local crit_plus_rate = tb["Crit"]
			if crit_plus_rate > 0 then
				crit_plus = crit_plus + math.floor((crit_base*100+crit_plus_rate) / 100)
			end
			local hit_plus_rate = tb["Hit"]
			if hit_plus_rate > 0 then
				hit_plus = hit_plus + math.floor((hit_base*100+hit_plus_rate) / 100)
			end										
		end
	end
	attack_base = math.floor(self.attr:Get("power") * 2.5)
	defencse_base = math.floor(self.attr:Get("endurance") * 2)
	maxlife_base = math.floor(self.attr:Get("constitution") * 22.5)
	local level = self.attr:Get("level") or 1
	crit_base = TableRole[level]["Crit"] + crit_base 
	self.attr:Set("attack",attack_base + attack_plus)
	self.attr:Set("defencse",defencse_base + defencse_plus)
	self.attr:Set("maxlife",maxlife_base + maxlife_plus)
	self.attr:Set("dodge",dodge_base + dodge_plus)
	self.attr:Set("crit",crit_base + crit_plus)
	self.attr:Set("hit",hit_base + hit_plus)
	print(self.attr:Get("attack"))
	print(self.attr:Get("maxlife"))
	if notifyclient then
		self.attr:Update2Client(self)
	end
end

local function _checkDuplicateName()
	local lock =  Lock.New()
	return function (nickname)
		lock:Lock()
		local err,result = Db.CommandSync("hmget nickname " .. nickname)
		if err or result[1] then
			lock:Unlock()
			return false
		end
		err = Db.CommandSync(string.format("hmset nickname %s 1",nickname))
		if err then
			lock:Unlock()
			return false			
		end
		lock:Unlock()
		return true
	end
end

local checkDuplicateName = _checkDuplicateName()

--创建角色
MsgHandler.RegHandler(NetCmd.CMD_CG_CREATE,function (sock,rpk)
	local avatarid = rpk:Read_uint8()
	local nickname = rpk:Read_string()
	local weapon = rpk:Read_uint16()
	local groupsession = rpk:Read_uint16()	
	local ply = GetPlayerBySessionId(groupsession)
	if not ply or not ply.gatesession then
		log_groupserver:Log(CLog.LOG_ERROR,string.format("CMD_CG_CREATE not ply or not gatesession %s",nickname))	
		return 
	end	
	if ply.status ~= createcha then
		log_groupserver:Log(CLog.LOG_ERROR,string.format("CMD_CG_CREATE invaild status %s %d",ply.actname,ply.status))	
		return 
	end

	if nickname == "" or not TableItem[weapon] or TableItem[weapon]["Item_Type"] ~= 2 then
		if nickname == "" then
			ply:NotifyCreateError("invaild nickname")
		else
			ply:NotifyCreateError("invaild weapon")
		end
		return
	end
	ply.status = creating
	if not ply.nickname or ply.nickname ~= nickname then
		if not checkDuplicateName(nickname) then
			print("DuplicateName,",nickname)
			ply.status = createcha
			ply:NotifyCreateError("invaild nickname")
			return
		end
	end
	log_groupserver:Log(CLog.LOG_ERROR,string.format("CMD_CG_CREATE %s %s",ply.actname,nickname))		
	ply.chaid = ply.chaid or 0
	ply.nickname =  nickname
	ply.avatarid = avatarid
	if ply.chaid == 0 then
		local err,result = Db.CommandSync("incr chaid")
		if err or not result then
			log_groupserver:Log(CLog.LOG_ERROR,string.format("CMD_CG_CREATE %s db incr error",ply.actname))	
			ply:NotifyCreateError("retry")
			ply.status = createcha
			return
		else
			ply.chaid = tonumber(result)
			err,result = Db.CommandSync("set " .. ply.actname .. " " .. ply.chaid)
			if err then
				log_groupserver:Log(CLog.LOG_ERROR,string.format("CMD_CG_CREATE %s db set actname error",ply.actname))	
				ply:NotifyCreateError("retry")
				ply.status = createcha
				return
			end			
		end
	end

	local attr = {}
	for k,v in pairs(Name2idx.Pairs) do
		attr[v] = 0
	end
	ply.attr = Attr.New():Init(ply,attr)
	ply.attr:Set("online_award",os.time())
	ply.attr:Set("stamina",100)
	ply.sign = Sign.New(ply)
	ply.task = Task.New(ply)
	ply.achieve = Achi.New(ply)
	ply.mail = Mail.New(ply)
	local extra_skill

	if weapon == 5101 then
		extra_skill = {1110,1}
	elseif weapon == 5201 then
		extra_skill = {1210,1}
	else
		extra_skill = {1010,1}
	end
	local bag = {size=60,
		       [Bag.weapon] = {id=weapon,count=1,attr = {0,0,0,0,0,0,0,0,0,0}}, 
		       [Bag.belt] = {id=5401,count=1,attr = {0,0,0,0,0,0,0,0,0,0}},
		       [11] = {id=5502,count=10}, 
		       [12]= {id=5503,count=10}}
	ply.bag = Bag.New():Init(ply,bag)
	ply.skills = Skill.New(ply,{{11,1},{12,1},{13,1},{21,1},extra_skill})
	ply:OnLevelUp(1)
	ply.attr:ClearFlag()
	local err =  Db.CommandSync(string.format("hmset chaid:%u nickname %s avatarid %u chainfo %s bag %s skills %s everydaysign %s everydaytask %s achievement %s",
				    ply.chaid,ply.nickname,ply.avatarid,ply.attr:DbStr(),ply.bag:DbStr(),ply.skills:DbStr(),ply.sign:DbStr(),ply.task:DbStr(),ply.achieve:DbStr())) 	
	if err then
		log_groupserver:Log(CLog.LOG_ERROR,string.format("CMD_CG_CREATE %s db set character error:%s" ,nickname,err))	
		ply:NotifyCreateError("retry")
		ply.status = createcha
	else	
		chaid2player[ply.chaid] = ply
		nickname2player[ply.nickname] = ply
		ply:NotifyBeginPlay()
	end		
end)

--请求进入地图
MsgHandler.RegHandler(NetCmd.CMD_CG_ENTERMAP,function (sock,rpk)
	print("CMD_CG_ENTERMAP")
	local groupsession = rpk:Reverse_read_uint16()
	local ply = GetPlayerBySessionId(groupsession)
	if not ply or not ply.gatesession or ply.mapinstance or ply.status ~= playing then
		if not ply then
			log_groupserver:Log(CLog.LOG_ERROR,string.format("CMD_CG_ENTERMAP error no player obj"))	
		elseif not ply.gatesession then
			log_groupserver:Log(CLog.LOG_ERROR,string.format("CMD_CG_ENTERMAP %s not gatesession",ply.actname))	
		elseif ply.mapinstance then
			log_groupserver:Log(CLog.LOG_ERROR,string.format("CMD_CG_ENTERMAP %s already in map",ply.actname))	
		else
			log_groupserver:Log(CLog.LOG_ERROR,string.format("CMD_CG_ENTERMAP %s invaild status",ply.actname,ply.status))	
		end
		return 
	end
	local type = rpk:Read_uint8()
	ply.status = entermap
	local succ,err = Map.EnterMap(ply,type)
	if not succ then
		ply.status = playing
	end
end)

release_timeout = 1*60*1000

MsgHandler.RegHandler(NetCmd.CMD_CG_LEAVEMAP,function (sock,rpk)
	local groupsession = rpk:Reverse_read_uint16()
	local ply = GetPlayerBySessionId(groupsession)
	if not ply or not ply.gatesession or not ply.mapinstance or ply.status ~= playing then
		if not ply then
			log_groupserver:Log(CLog.LOG_ERROR,string.format("CMD_CG_LEAVEMAP error no player obj"))	
		elseif not ply.gatesession then
			log_groupserver:Log(CLog.LOG_ERROR,string.format("CMD_CG_LEAVEMAP %s no gatesession",ply.actname))	
		elseif not ply.mapinstance then
			log_groupserver:Log(CLog.LOG_ERROR,string.format("CMD_CG_LEAVEMAP %s no map",ply.actname))	
		else
			log_groupserver:Log(CLog.LOG_ERROR,string.format("CMD_CG_LEAVEMAP %s invaild status %d",ply.actname,ply.status))	
		end
		return 
	end
	
	ply.status = leavingmap
	if Map.LeaveMap(ply) then
		if not ply.gatesession then
		--start a timer
			_,ply.lgTimer = LogOutTimer:Register(function ()
								ReleasePlayer(ply)
								return "stop timer"
		    					           end,release_timeout)
		end
		ply.bag:SynBattleItem()
	end
	ply.status = playing
end)

MsgHandler.RegHandler(NetCmd.CMD_AG_CLIENT_DISCONN,function (sock,rpk)
	local groupsession = rpk:Reverse_read_uint16()
	local ply = GetPlayerBySessionId(groupsession)
	if ply then
		log_groupserver:Log(CLog.LOG_ERROR,string.format("CMD_AG_CLIENT_DISCONN %s ",ply.actname))
		if ply.gatesession then
			Gate.UnBind(ply)
		end
		if ply.gamesession then
			local wpk = CPacket.NewWPacket(64)
			wpk:Write_uint16(NetCmd.CMD_GGAME_CLIDISCONNECTED)
			ply:Send2Game(wpk)
		else
			--start a timer
			_,ply.lgTimer = LogOutTimer:Register(function ()
				ReleasePlayer(ply)
 				return "stop timer"
			    end,release_timeout)
		end
	end	
end)



MsgHandler.RegHandler(NetCmd.CMD_CG_PVE_GETAWARD,function (sock,rpk)
	local groupsession = rpk:Reverse_read_uint16()
	local ply = GetPlayerBySessionId(groupsession)
	if ply then
		print("CMD_CG_PVE_GETAWARD")
		local round = ply.attr:Get("spve_today_max")
		local tb = TableNewbie_Reward[round]
		if not tb then
			return
		end
		Util.NewRes(ply,4004,tb.Experience)
		Util.NewRes(ply,4001,tb.Shell)
		ply.attr:Set("spve_today_max",0)
		ply.attr:DbSave()
		ply.attr:Update2Client()
	end		
end)


local function RegRpcService(app)
	local function PlayerLogin(sock,actname,chaid,sessionid)
		log_groupserver:Log(CLog.LOG_ERROR,string.format("PlayerLogin %s",actname))
		local ply = GetPlayerByActname(actname)
		if ply then
			if ply.gatesession then
				log_groupserver:Log(CLog.LOG_ERROR,string.format("PlayerLogin already have gatesession %s",actname))
				return {false,"invaild login"}
			else
				if ply.lgTimer then
					LogOutTimer:Remove(ply.lgTimer)
					ply.lgTimer = nil
				end
				log_groupserver:Log(CLog.LOG_ERROR,string.format("PlayerLogin already in group %s",actname))
				--断线重连
				if ply.status == createcha then
					Gate.Bind(Gate.GetGateBySock(sock),ply,sessionid)
					return ply:NotifyCreate()
				elseif ply.status == creating then
					Gate.Bind(Gate.GetGateBySock(sock),ply,sessionid)
				elseif ply.status == playing or ply.status == queueing or ply.status == entermap then
					Gate.Bind(Gate.GetGateBySock(sock),ply,sessionid)
					Sche.Spawn(function ()
						if ply.gatesession then
							ply:NotifyBeginPlay()					
							if ply.gamesession then
								--通知gameserver断线重连
								local rpccaller = RPC.MakeRPC(ply.gamesession.game.sock,"CliReConn")
								print("reconnect",ply.gatesession.gate.name)	
								local err,ret = rpccaller:CallSync(ply.gamesession.sessionid,
											      {name=ply.gatesession.gate.name,id=ply.gatesession.sessionid})
								if err or not ret then
									Game.UnBind(ply)
									log_groupserver:Log(CLog.LOG_ERROR,string.format("game reconnect error %s",actname))
								end							   						
							end
						end
					end)					
					return {true,ply.groupsession}					
				else
					log_groupserver:Log(CLog.LOG_ERROR,string.format("PlayerLogin invaild status %s %d",actname,ply.status))
					return {false,"invaild status"}				
				end				 
			end
		else
			    ply = NewPlayer(actname)
		    	    if not ply then
		    	    	log_groupserver:Log(CLog.LOG_ERROR,string.format("PlayerLogin reach max group player count %s",actname))
				return {false,"group busy"}
		    	    end
			    Gate.Bind(Gate.GetGateBySock(sock),ply,sessionid)
			    ply.chaid = ply.chaid or chaid
			    if ply.chaid == 0 then
					return ply:NotifyCreate()
			    else
					ply.status = loading
					local err,result = Db.CommandSync("hmget chaid:" .. ply.chaid .. " nickname avatarid chainfo bag skills everydaysign everydaytask achievement mail")
					if err then
						ReleasePlayer(ply)
						log_groupserver:Log(CLog.LOG_ERROR,string.format("PlayerLogin %s db error %s",actname,err))
						return {false,"group busy"}
					end
					if not result or not result[1] or not result[2] or not result[3] or not result[4] or not result[5] then
						return ply:NotifyCreate()
					else
						ply.status   = playing
						ply.nickname = result[1]
						ply.avatarid = tonumber(result[2])				
						ply.attr =  Attr.New():Init(ply,Cjson.decode(result[3]))
						ply.bag = Bag.New():Init(ply,Cjson.decode(result[4]))
						ply.skills = Skill.New():Init(ply,Cjson.decode(result[5]))

						local signdata = nil
						if result[6] then
							signdata = Cjson.decode(result[6])
						end
						ply.sign = Sign.New(ply,signdata)						
						local taskdata = nil
						if result[7] then
							taskdata = Cjson.decode(result[7])
						end						
						ply.task = Task.New(ply,taskdata)
						local achieve = nil
						if result[8] then
							achieve = Cjson.decode(result[8])
						end
						ply.achieve = Achi.New(ply,achieve)

						local mails
						if result[9] then
							mails = Cjson.decode(CBase64.decode(result[9]))
						end
						ply.mail = Mail.New(ply,mails)
						ply:CalAttr()
						ply.attr:ClearFlag()						
						Sche.Spawn(function () 
								if ply.gatesession then
									chaid2player[ply.chaid] = ply
									nickname2player[ply.nickname] = ply
									ply:NotifyBeginPlay() 
								end
							        end)
						return {true,ply.groupsession}
					end  				
			    end	
		end	
	end
	app:RPCService("PlayerLogin",
			 function (sock,actname,chaid,sessionid)
				local status,ret = pcall(PlayerLogin,sock,actname,chaid,sessionid)
				if status then
					return ret
				else
					local ply = GetPlayerByActname(actname)
					if ply then
						Gate.UnBind(ply)
						ReleasePlayer(ply)
					end
					log_groupserver:Log(CLog.LOG_ERROR,string.format("PlayerLogin %s error %s",actname,ret))
					return {false,ret}
				end
			end)
end


MsgHandler.RegHandler(NetCmd.CMD_CG_CHAT,function (sock,rpk)
	print("CMD_CG_CHAT")
	local groupsession = rpk:Reverse_read_uint16()
	local ply = GetPlayerBySessionId(groupsession)
	if ply and ply.gatesession then
		local target = rpk:Read_string()
		local str = rpk:Read_string()
		if target == "all" then
			if string.byte(str,1) == 42 then --* prefix
				GM.Command(ply,string.sub(str,2))
			else
				--broadcast
				local wpk = CPacket.NewWPacket(512)
				wpk:Write_uint16(NetCmd.CMD_GC_CHAT)
				wpk:Write_uint8(1)
				wpk:Write_string(ply.nickname)
				wpk:Write_string(str)				
				for k,v in pairs(nickname2player) do
					v:Send2Client(wpk)
				end				
			end
		else
			target = GetPlyByNickname(target)
			if target then
				local wpk = CPacket.NewWPacket(512)
				wpk:Write_uint16(NetCmd.CMD_GC_CHAT)
				wpk:Write_uint8(0)
				wpk:Write_string(ply.nickname)
				wpk:Write_string(str)
				target:Send2Client(wpk)
			end
		end
	end	
end)

MsgHandler.RegHandler(NetCmd.CMD_CG_ADDPOINT,function (sock,rpk)
	print("CMD_CG_ADDPOINT")
	local groupsession = rpk:Reverse_read_uint16()
	local ply = GetPlayerBySessionId(groupsession)
	if ply then
		local power = rpk:Read_uint16()
		local endurance = rpk:Read_uint16()
		local constitution = rpk:Read_uint16()
		local agile = rpk:Read_uint16()
		local lucky = rpk:Read_uint16()
		local accurate = rpk:Read_uint16()
		local potential_point = ply.attr:Get("potential_point") or 0
		if power + endurance + constitution + agile + lucky + accurate > potential_point then
			return
		end

		ply.attr:Set("power",ply.attr:Get("power") + power)
		potential_point = potential_point - power

		ply.attr:Set("endurance",ply.attr:Get("endurance") + endurance)
		potential_point = potential_point - endurance

		ply.attr:Set("constitution",ply.attr:Get("constitution") + constitution)
		potential_point = potential_point - constitution

		ply.attr:Set("agile",ply.attr:Get("agile") + agile)
		potential_point = potential_point - agile

		ply.attr:Set("lucky",ply.attr:Get("lucky") + lucky)
		potential_point = potential_point - lucky												

		ply.attr:Set("accurate",ply.attr:Get("accurate") + accurate)
		potential_point = potential_point - accurate

		ply.attr:Set("potential_point",potential_point)
		ply.achieve:OnEvent(Achi.AchiType.ACHI_ADDPOINT)

		ply:CalAttr(true)
		ply.attr:DbSave()
	end	
end)


require "common.TableNewbie_Reward"

for k,v in pairs(TableNewbie_Reward) do
	if v.Guide_Reward then
		--print(v.Guide_Reward)
		local reward = {}
		local tmp = Util.SplitString(v.Guide_Reward,",")
		for k1,v1 in pairs(tmp) do
			local tmp2 = Util.SplitString(v1,":")
			tmp2[1] = tonumber(tmp2[1])
			tmp2[2] = tonumber(tmp2[2])
			--print(tmp2[1],tmp2[2])
			table.insert(reward,tmp2)
		end
		v.Guide_Reward = reward
	end
end

MsgHandler.RegHandler(NetCmd.CMD_CG_COMMIT_INTRODUCE_STEP,function (sock,rpk)
	print("CMD_CG_COMMIT_INTRODUCE_STEP")
	local groupsession = rpk:Reverse_read_uint16()
	local ply = GetPlayerBySessionId(groupsession)
	if ply and ply.gatesession then
		local old = ply.attr:Get("introduce_step")
		local new = rpk:Read_uint16()
		if new > old then
			local tb = TableNewbie_Reward[new]
			if tb and tb.Guide_Reward then
				for k,v in pairs(tb.Guide_Reward) do
					print(v[1],v[2])
					Util.NewRes(ply,v[1],v[2])
				end
			end
			ply.attr:Set("introduce_step",new)
			ply.bag:NotifyUpdate()
			ply.bag:Save()
			ply.attr:DbSave()
			ply.attr:Update2Client()
		end
	end	
end)

MsgHandler.RegHandler(NetCmd.CMD_CG_COMMIT_SPVE,function (sock,rpk)
	print("CMD_CG_COMMIT_SPVE")
	local groupsession = rpk:Reverse_read_uint16()
	local ply = GetPlayerBySessionId(groupsession)
	if ply and ply.gatesession then
		local old = ply.attr:Get("spve_today_max")
		local new = rpk:Read_uint16()
		
		if new == 1003 then
			ply.achieve:OnEvent(Achi.AchiType.ACHI_KILL_BOSS)
		elseif new == 1001 then 
			ply.achieve:OnEvent(Achi.AchiType.ACHI_SINGLE_PVE)
		end
		if new > 1000 then
			return
		end
		if new > old then
			ply.achieve:OnEvent(Achi.AchiType.ACHI_SINGLE_PVE)
			ply.attr:Set("spve_today_max",new)
			old = ply.attr:Get("spve_history_max")
			if new > old then
				ply.attr:Set("spve_history_max",new)
			end
			ply.attr:DbSave()
			ply.attr:Update2Client()
		end
	end	
end)

MsgHandler.RegHandler(NetCmd.CMD_GAMEG_PVPAWARD,function (sock,rpk)
	print("CMD_GAMEG_PVPAWARD")
	local maptype = rpk:Read_uint16()
	local size = rpk:Read_uint8()
	for i = 1,size do
		local groupsession = rpk:Read_uint16()
		local win = rpk:Read_uint8() == 1
		local ply = GetPlayerBySessionId(groupsession)
		if ply then
			local level = ply.attr:Get("level")
			local award

			if maptype == 204 then
				if win then
					award = TableArena_Reward[level]["5V5_Win_Reward"]
				else
					award = TableArena_Reward[level]["5V5_Fail_Reward"]
				end
			elseif maptype == 207 then
				if win then
					award = TableArena_Reward[level]["1V1_Win_Reward"]
				else
					award = TableArena_Reward[level]["1V1_Fail_Reward"]
				end
			elseif maptype == 208 then
				if win then
					award = TableArena_Reward[level]["2V2_Win_Reward"]
				else
					award = TableArena_Reward[level]["2V2_Fail_Reward"]
				end			
			end

			if award then
				--print(1,ply.attr.Update2Client)
				--print(Util.NewRes)
				for k,v in pairs(award) do
					Util.NewRes(ply,v[1],v[2])
				end
				print(2,ply.attr.Update2Client)
				ply.attr:DbSave()
				print(3,ply.attr.Update2Client)
				ply.attr:Update2Client()
				ply.bag:Save()
				ply.bag:NotifyUpdate()
			end
		end		

	end
end)

MsgHandler.RegHandler(NetCmd.CMD_GAMEG_5PVEAWARD,function (sock,rpk)
	print("CMD_GAMEG_5PVEAWARD")
	local round = rpk:Read_uint16()
	local size = rpk:Read_uint8()
	for i = 1,size do
		local groupsession = rpk:Read_uint16()
		local ply = GetPlayerBySessionId(groupsession)
		if ply then
			local award = TableTower_Reward[round]["Tower_Reward"]
			if award then
				for k,v in pairs(award) do
					Util.NewRes(ply,v[1],v[2]*round)
				end
				ply.attr:DbSave()
				ply.attr:Update2Client()
				ply.bag:Save()
				ply.bag:NotifyUpdate()
			end
		end		

	end
end)



MsgHandler.RegHandler(NetCmd.CMD_GAMEG_KICK,function (sock,rpk)
	print("CMD_GAMEG_KICK")
	local groupsession = rpk:Read_uint16()
	local ply = GetPlayerBySessionId(groupsession)
	if ply then
		Game.UnBind(ply)
		ply.mapinstance = nil
		if not ply.gatesession then
			--start a timer
			_,ply.lgTimer = LogOutTimer:Register(function ()
								ReleasePlayer(ply)
								return "stop timer"
		    					       end,release_timeout)
		end		
	end		
end)

return {
	RegRpcService = RegRpcService,
}
