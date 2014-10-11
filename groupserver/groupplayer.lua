local Cjson = require "cjson"
local Que = require "lua/queue"
local Gate = require "Survive/groupserver/gate"
local Game = require "Survive/groupserver/game"
local MsgHandler = require "Survive/netcmd/msghandler"
local Name2idx = require "Survive/common/name2idx"
local Db = require "Survive/common/db"
local Attr = require "Survive/groupserver/attr"
local Bag = require "Survive/groupserver/bag"
local Skill = require "Survive/groupserver/skill"
local NetCmd = require "Survive/netcmd/netcmd"
local Sche = require "lua/sche"
local Map = require "Survive/groupserver/map"
local RPC = require "lua/rpc"

local freeidx = Que.New()

for i=1,65535 do
	freeidx:Push({v=i})
end

local function GetIdx()
	local n = freeidx:Pop()
	if n then 
		return n.v
	else
		return nil
	end
end

local function ReleaseIdx(idx)
	freeidx:Push({v=idx})
end

local createcha  = 1
local loading    = 2
local playing    = 3
local releasing  = 4
local entermap   = 5

local player = {}
local actname2player ={}
local id2player = {}

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

local function ReleasePlayer(ply)
	if ply.groupsession then
		id2player[ply.groupsession] = nil
		actname2player[ply.actname] = nil
		ReleaseIdx(ply.groupsession)
		ply.groupsession = nil
	end
end

local function GetPlayerBySessionId(id)
	return id2player[id]
end

local function GetPlayerByActname(actname)
	return actname2player[actname]
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
		local wpk1 = CPacket.NewWPacket(256)
		local rpk = CPacket.NewRPacket(wpk)
		wpk1:Write_uint16(rpk:Read_uint16())
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
	wpk:Write_uint16(self.avatarid)
	wpk:Write_string(self.nickname)
	self.attr:OnBegPly(wpk)
	self.bag:OnBegPly(wpk)
	self.skills:OnBegPly(wpk)
	self:Send2Client(wpk)		
end

function player:NotifyCreate()
	self.status = createcha
	return {true,self.groupsession,"create"}	
end

function player:NotifyCreateError(msg)
	local wpk = CPacket.NewWPacket(64)
	wpk:Write_uint16(NetCmd.CMD_SC_CREATE_ERROR) 
	wpk:Write_string(msg)
	self:Send2Client(wpk)
end

--创建角色
MsgHandler.RegHandler(NetCmd.CMD_CG_CREATE,function (sock,rpk)
	print("CMD_CG_CREATE")
	local avatarid = rpk:Read_uint8()
	local nickname = rpk:Read_string()
	local weapon = rpk:Read_uint8()
	local groupsession = rpk:Read_uint16()	
	local ply = GetPlayerBySessionId(groupsession)
	if not ply or not ply.gatesession then
		return 
	end	
	if ply.status ~= createcha then
		return 
	end	
	ply.chaid = ply.chaid or 0
	ply.nickname = nickname
	ply.avatarid = avatarid
	if ply.chaid == 0 then
		local err,result = Db.Command("incr chaid")
		if err or not result then
			ply:NotifyCreateError("retry")
		else
			ply.chaid = result
			err,result = Db.Command("set " .. ply.actname .. " " .. ply.chaid)
			if err then
				ply:NotifyCreateError("retry")
			end			
		end
	end
	local attr={
		[Name2idx.Idx("level")] = 1,
		[Name2idx.Idx("exp")] = 0,
		[Name2idx.Idx("power")] = 0,
		[Name2idx.Idx("endurance")] = 0,
		[Name2idx.Idx("constitution")] = 0,
		[Name2idx.Idx("agile")] = 0,
		[Name2idx.Idx("lucky")] = 0,
		[Name2idx.Idx("accurate")] = 0,
		[Name2idx.Idx("movement_speed")] = 0,
		[Name2idx.Idx("shell")] = 0,
		[Name2idx.Idx("pearl")] = 0,
		[Name2idx.Idx("soul")] = 0,
		[Name2idx.Idx("action_force")] = 0,
		
		[Name2idx.Idx("attack")] = 100,
		[Name2idx.Idx("defencse")] = 100,
		[Name2idx.Idx("life")] = 100,
		[Name2idx.Idx("maxlife")] = 100,			
		[Name2idx.Idx("dodge")] = 100,
		[Name2idx.Idx("crit")] = 100,
		[Name2idx.Idx("hit")] = 100,
		[Name2idx.Idx("anger")] = 0,
		[Name2idx.Idx("combat_power")] = 0,
	}
	ply.attr = Attr.New():Init(attr)
	ply.bag = Bag.New():Init()
	ply.skills = Skill.New():Init()	
	local err =  Db.Command(string.format("hmset chaid:%u nickname %s avatarid %u chainfo %s bag %s skills %s",ply.chaid,ply.nickname,ply.avatarid,ply.attr:DbStr(),
								  ply.bag:DbStr(),ply.skills:DbStr())) 	
	if err then
		ply:NotifyCreateError("retry")
	else	
		ply:NotifyBeginPlay()
	end		
end)

--请求进入地图
MsgHandler.RegHandler(NetCmd.CMD_CG_ENTERMAP,function (sock,rpk)
	local groupsession = rpk:Reverse_read_uint16()
	local ply = GetPlayerBySessionId(groupsession)
	if not ply or not ply.gatesession or ply.gamesession or ply.status ~= playing then
		return 
	end
	local type = rpk:Read_uint8()
	ply.status = entermap
	local ret,err = Map.EnterMap(ply,type)
	ply.status = playing
end)

MsgHandler.RegHandler(NetCmd.CMD_AG_CLIENT_DISCONN,function (sock,rpk)
	local groupsession = rpk:Reverse_read_uint16()
	local ply = GetPlayerBySessionId(groupsession)
	if ply then
		if ply.gatesession then
			Gate.UnBind(ply)
		end
		if ply.gamesession then
			local wpk = CPacket.NewWPacket(64)
			wpk:Write_uint16(NetCmd.CMD_GGAME_CLIDISCONNECTED)
			ply:Send2Game(wpk)
		end
	end	
end)

local function RegRpcService(app)
	app:RPCService("PlayerLogin",function (sock,actname,chaid,sessionid)
		print("PlayerLogin")
		local ply = GetPlayerByActname(actname)
		if ply then
			if ply.gatesession then
				return {false,"invaild login"}
			else
				print("already in group")
				--断线重连
				if ply.status == createcha then
					return ply:NotifyCreate()
				elseif ply.status == playing then
					Gate.Bind(Gate.GetGateBySock(sock),ply,sessionid)
					ply:NotifyBeginPlay()					
					if ply.gamesession then
						print("game CliReConn")
						--通知gameserver断线重连
						local rpccaller = RPC.MakeRPC(ply.gamesession.game.sock,"CliReConn")	
						local err,ret = rpccaller:Call(ply.gamesession.sessionid,
													   {name=ply.gatesession.gate.name,id=ply.gatesession.sessionid})
						if err or not ret then
							print("CliReConn error")
						end							   						
					end					
					return {true,ply.groupsession}					
				else
					return {false,"invaild status"}				
				end				 
			end
		else
			ply = NewPlayer(actname)
		    if not ply then
				return {false,"group busy"}
		    end
		    Gate.Bind(Gate.GetGateBySock(sock),ply,sessionid)
		    ply.chaid = ply.chaid or chaid
		    if ply.chaid == 0 then
				return ply:NotifyCreate()
		    else
				ply.status = loading
				local err,result = Db.Command("hmget chaid:" .. ply.chaid .. " nickname avatarid chainfo bag skills")
				if err then
					ReleasePlayer(ply)
					return {false,"group busy"}
				end
				if not result then
					return ply:NotifyCreate()
				else
					ply.status   = playing
					ply.nickname = result[1]
					ply.avatarid = tonumber(result[2])				
					ply.attr =  Attr.New():Init(Cjson.decode(result[3]))
					ply.bag = Bag.New():Init(Cjson.decode(result[4]))
					ply.skills = Skill.New():Init(Cjson.decode(result[5]))
					ply.attr:Set("attack",100)
					ply.attr:Set("defencse",100)
					ply.attr:Set("life",100)
					ply.attr:Set("maxlife",100)	
					ply.attr:Set("dodge",100)
					ply.attr:Set("crit",100)
					ply.attr:Set("hit",100)
					ply.attr:Set("anger", 0)
					ply.attr:Set("combat_power",0)
					Sche.Spawn(function () ply:NotifyBeginPlay() end)
					return {true,ply.groupsession}
				end  				
		    end	
		end		
	end)
end

return {
	RegRpcService = RegRpcService,
}
